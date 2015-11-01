//
//  CRFCGIConnection.m
//  Criollo
//
//  Created by Cătălin Stan on 10/25/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRFCGIConnection.h"
#import "CRApplication.h"
#import "CRFCGIServer.h"
#import "CRFCGIServerConfiguration.h"
#import "CRFCGIRequest.h"
#import "CRFCGIResponse.h"
#import "CRFCGIRecord.h"
#import "GCDAsyncSocket.h"

@interface CRFCGIConnection () {
    NSUInteger requestBodyLength;
    NSUInteger requestBodyReceivedBytesLength;
    BOOL didPerformInitialRead;

    CRFCGIRecord* currentRecord;
    CRFCGIRequestRole currentRequestRole;
    CRFCGIRequestFlags currentRequestFlags;
    NSMutableDictionary* currentRequestParams;
}

@property (nonatomic, strong) dispatch_queue_t isolationQueue;

- (void)appendParamsFromData:(NSData*)paramsData length:(NSUInteger)dataLength;

@end

@implementation CRFCGIConnection

#pragma mark - Data

- (instancetype)initWithSocket:(GCDAsyncSocket *)socket server:(CRServer *)server {
    self = [super initWithSocket:socket server:server];
    if ( self != nil ) {
        self.isolationQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"IsolationQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(self.isolationQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    }
    return self;
}

- (void)startReading {
    requestBodyLength = 0;
    requestBodyReceivedBytesLength = 0;

    currentRequestParams = [NSMutableDictionary dictionary];

    CRFCGIServerConfiguration* config = (CRFCGIServerConfiguration*)self.server.configuration;

    // Read the begin request record
    NSUInteger timeout = (didPerformInitialRead ? config.CRConnectionKeepAliveTimeout : config.CRConnectionInitialReadTimeout) + config.CRFCGIConnectionReadRecordTimeout;
    [self.socket readDataToLength:CRFCGIRecordHeaderLength withTimeout:timeout tag:CRFCGIConnectionSocketTagReadRecordHeader];
}

- (void)didReceiveCompleteRequestHeaders {
    [super didReceiveCompleteRequestHeaders];

    // Create HTTP headers from FCGI Params
    NSMutableData* headersData = [NSMutableData data];
    [self.request.env enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if ( ![key hasPrefix:@"HTTP_"] ) {
            return;
        }
        NSArray<NSString*>* headerParts = [[key substringFromIndex:5] componentsSeparatedByString:@"_"];
        NSMutableArray<NSString*>* transformedHeaderParts = [NSMutableArray arrayWithCapacity:headerParts.count];

        [headerParts enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString* transformedHeaderPart = [[obj substringToIndex:1].uppercaseString stringByAppendingString:[obj substringFromIndex:1].lowercaseString];
            [transformedHeaderParts addObject:transformedHeaderPart];
        }];

        NSString* headerName = [transformedHeaderParts componentsJoinedByString:@"-"];

        NSData* headerData = [[NSString stringWithFormat:@"%@: %@", headerName, obj] dataUsingEncoding:NSUTF8StringEncoding];
        [headersData appendData:headerData];
        [headersData appendData:[CRConnection CRLFData]];
    }];

    [self.request appendData:headersData];
    [self.request appendData:[CRConnection CRLFData]];
}

- (void)didReceiveRequestBody {
    [super didReceiveRequestBody];
}

- (void)didReceiveCompleteRequest {
    [super didReceiveCompleteRequest];

    NSMutableString* string = [NSMutableString stringWithString:@"<h1>Hello world!</h1>"];
    self.response = [[CRFCGIResponse alloc] initWithConnection:self HTTPStatusCode:200 description:@"asdfadsfas" version:self.request.version];
    [self.response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-type"];
    [self.response sendString:string];
}

- (void)handleError:(NSUInteger)errorType object:(id)object {
    NSUInteger statusCode = 500;

    switch (errorType) {
        case CRErrorRequestMalformedRequest:
            statusCode = 400;
            [CRApp logErrorFormat:@"Malformed request: %@", [[NSString alloc] initWithData:object encoding:NSUTF8StringEncoding] ];
            break;

        case CRErrorRequestUnsupportedMethod:
            statusCode = 405;
            [CRApp logErrorFormat:@"Cannot %@", object[CRRequestKey]];
            break;

        default:
            break;
    }

    self.response = [[CRFCGIResponse alloc] initWithConnection:self HTTPStatusCode:statusCode];
    [self.response setValue:@"0" forHTTPHeaderField:@"Content-length"];
    [self.response setValue:@"close" forHTTPHeaderField:@"Connection"];
    [self.response end];
}

#pragma mark - Record Processing

- (void)appendParamsFromData:(NSData*)paramsData length:(NSUInteger)dataLength {


    dispatch_async(self.isolationQueue, ^{

        void(^parseValuePairBlock)(NSUInteger*, NSString**, NSString**, NSUInteger*) = ^(NSUInteger* offset, NSString** name, NSString** value, NSUInteger* bytesRead) {

            // Refer to http://www.fastcgi.com/drupal/node/6?q=node/22#S3.4 for rules in parsing dictionaries

            NSUInteger initialOffset = *offset;

            UInt8 pos0, pos1, pos4;
            UInt8 valueLengthB3, valueLengthB2, valueLengthB1, valueLengthB0;
            UInt8 nameLengthB3, nameLengthB2, nameLengthB1, nameLengthB0;
            UInt32 nameLength, valueLength;

            [paramsData getBytes:&pos0 range:NSMakeRange(*offset + 0, 1)];
            [paramsData getBytes:&pos1 range:NSMakeRange(*offset + 1, 1)];
            [paramsData getBytes:&pos4 range:NSMakeRange(*offset + 4, 1)];

            if (pos0 >> 7 == 0) {

                // NameValuePair11 or 14
                nameLength = pos0;

                if (pos1 >> 7 == 0) {
                    // NameValuePair11
                    valueLength = pos1;
                    *offset += 2;
                } else {
                    //NameValuePair14
                    [paramsData getBytes:&valueLengthB3 range:NSMakeRange(*offset + 1, 1)];
                    [paramsData getBytes:&valueLengthB2 range:NSMakeRange(*offset + 2, 1)];
                    [paramsData getBytes:&valueLengthB1 range:NSMakeRange(*offset + 3, 1)];
                    [paramsData getBytes:&valueLengthB0 range:NSMakeRange(*offset + 4, 1)];
                    valueLength = ((valueLengthB3 & 0x7f) << 24) + (valueLengthB2 << 16) + (valueLengthB1 << 8) + valueLengthB0;
                    *offset += 5;
                }

            } else {

                // NameValuePair41 or 44
                [paramsData getBytes:&nameLengthB3 range:NSMakeRange(*offset + 0, 1)];
                [paramsData getBytes:&nameLengthB2 range:NSMakeRange(*offset + 1, 1)];
                [paramsData getBytes:&nameLengthB1 range:NSMakeRange(*offset + 2, 1)];
                [paramsData getBytes:&nameLengthB0 range:NSMakeRange(*offset + 3, 1)];
                nameLength = ((nameLengthB3 & 0x7f) << 24) + (nameLengthB2 << 16) + (nameLengthB1 << 8) + nameLengthB0;

                if (pos4 >> 7 == 0) {
                    //NameValuePair41
                    valueLength = pos4;
                    *offset += 5;
                } else {
                    //NameValuePair44
                    [paramsData getBytes:&valueLengthB3 range:NSMakeRange(*offset + 4, 1)];
                    [paramsData getBytes:&valueLengthB2 range:NSMakeRange(*offset + 5, 1)];
                    [paramsData getBytes:&valueLengthB1 range:NSMakeRange(*offset + 6, 1)];
                    [paramsData getBytes:&valueLengthB0 range:NSMakeRange(*offset + 7, 1)];
                    valueLength = ((valueLengthB3 & 0x7f) << 24) + (valueLengthB2 << 16) + (valueLengthB1 << 8) + valueLengthB0;
                    *offset += 8;
                }
            }

            *name = [[NSString alloc] initWithData:[paramsData subdataWithRange:NSMakeRange(*offset + 0, nameLength)] encoding:NSASCIIStringEncoding];
            *offset += nameLength;

            *value = [[NSString alloc] initWithData:[paramsData subdataWithRange:NSMakeRange(*offset + 0, valueLength)] encoding:NSASCIIStringEncoding];
            *offset += valueLength;

            if ( bytesRead != NULL ) {
                *bytesRead = *offset - initialOffset;
            }
        };

        NSUInteger startOffset = 0;
        NSString *paramName, *paramValue;

        while ( startOffset < dataLength ) {
            parseValuePairBlock(&startOffset, &paramName, &paramValue, NULL);
            if ( paramName.length != 0 && paramValue != nil ) {
                currentRequestParams[paramName] = paramValue;
            }
        }

    });

}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag {

    didPerformInitialRead = YES;

    CRFCGIServerConfiguration* config = (CRFCGIServerConfiguration*)self.server.configuration;

    switch (tag) {

        case CRFCGIConnectionSocketTagReadRecordHeader:
            currentRecord = [[CRFCGIRecord alloc] initWithHeaderData:data];
            NSLog(@" * Header: %@ %hu", NSStringFromCRFCGIRecordType(currentRecord.type), currentRecord.contentLength);

            // Process the record header
            if (currentRecord.contentLength == 0) {

                // Zero-length content records are markers
                switch (currentRecord.type) {
                    case CRFCGIRecordTypeParams: {
                        // We've finished reading the parameters
                        NSString* method = currentRequestParams[@"REQUEST_METHOD"];
                        NSString* path = currentRequestParams[@"DOCUMENT_URI"];
                        NSString* version = currentRequestParams[@"SERVER_PROTOCOL"];
                        if ( [self.server canHandleHTTPMethod:method forPath:path] ) {
//                            [currentRequestParams removeObjectsForKeys:@[@"REQUEST_METHOD", @"DOCUMENT_URI", @"SERVER_PROTOCOL"]];
                            self.request = [[CRFCGIRequest alloc] initWithMethod:method URL:[NSURL URLWithString:path] version:version env:currentRequestParams];

                            [self didReceiveCompleteRequestHeaders];

                            requestBodyLength = [self.request.env[@"CONTENT_LENGTH"] integerValue];
                            if ( requestBodyLength > 0 ) {
                                [self.socket readDataToLength:CRFCGIRecordHeaderLength withTimeout:config.CRFCGIConnectionReadRecordTimeout tag:CRFCGIConnectionSocketTagReadRecordHeader];
                            } else {
                                [self didReceiveCompleteRequest];
                            }
                        } else {
                            [self handleError:CRErrorRequestUnsupportedMethod object:@{CRRequestKey:[NSString stringWithFormat:@"%@ %@", method, path]}];

                        }
                    }
                        break;

                    case CRFCGIRecordTypeStdIn: {
                        // We have received the request body
                        [self didReceiveRequestBody];

                        if ( requestBodyLength == self.request.body.length ) {
                            [self didReceiveCompleteRequest];
                        } else {
                            [self handleError:CRErrorRequestMalformedRequest object:self.request.body];
                        }
                    }
                        break;


                    default:
                        break;
                }

            } else {

                // Read the data content of the record
                [self.socket readDataToLength:(currentRecord.contentLength + currentRecord.paddingLength) withTimeout:config.CRFCGIConnectionReadRecordTimeout tag:CRFCGIConnectionSocketTagReadRecordContent];

            }
            break;

        case CRFCGIConnectionSocketTagReadRecordContent:
            NSLog(@" * Content: %@ %lu", NSStringFromCRFCGIRecordType(currentRecord.type), data.length);

            // Process the header content data
            switch (currentRecord.type) {
                case CRFCGIRecordTypeBeginRequest:
                    // Request role
                    [data getBytes:&currentRequestRole range:NSMakeRange(0, 2)];
                    currentRequestRole = CFSwapInt16BigToHost(currentRequestRole);

                    // Request flags
                    [data getBytes:&currentRequestFlags range:NSMakeRange(2, 1)];

                    // Go on reaading the next record
                    [self.socket readDataToLength:CRFCGIRecordHeaderLength withTimeout:config.CRFCGIConnectionReadRecordTimeout tag:CRFCGIConnectionSocketTagReadRecordHeader];

                    break;

                case CRFCGIRecordTypeParams:
                    // We are receiving the params
                    [self appendParamsFromData:data length:(currentRecord.contentLength - currentRecord.paddingLength)];

                    // Go on reaading the next record
                    [self.socket readDataToLength:CRFCGIRecordHeaderLength withTimeout:config.CRFCGIConnectionReadRecordTimeout tag:CRFCGIConnectionSocketTagReadRecordHeader];
                    break;

                case CRFCGIRecordTypeStdIn: {

                    NSData* currentRecordContentData = [data subdataWithRange:NSMakeRange(0, currentRecord.contentLength)];
                    [self.request appendData:currentRecordContentData];

                    requestBodyReceivedBytesLength += currentRecordContentData.length;

                    // Go on reaading the next record
                    [self.socket readDataToLength:CRFCGIRecordHeaderLength withTimeout:config.CRFCGIConnectionReadRecordTimeout tag:CRFCGIConnectionSocketTagReadRecordHeader];
                }
                    break;

                default:
                    break;
            }
            

            
            break;
            
        default:
            break;
    }
    
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

@end
