//
//  CRHTTPConnection.m
//  Criollo
//
//  Created by Cătălin Stan on 10/25/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import <Criollo/CRHTTPConnection.h>

#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import <Criollo/CRApplication.h>
#import <Criollo/CRHTTPResponse.h>
#import <Criollo/CRHTTPServer.h>
#import <Criollo/CRHTTPServerConfiguration.h>
#import <Criollo/CRMessage.h>
#import <Criollo/CRRequest.h>

#import "CRConnection_Internal.h"
#import "CRMessage_Internal.h"
#import "CRRequest_Internal.h"
#import "CRResponse_Internal.h"
#import "CRServer_Internal.h"

@interface CRHTTPConnection () {
    NSUInteger requestBodyLength;
    NSUInteger requestBodyReceivedBytesLength;
    BOOL didPerformInitialRead;
}

@end

@implementation CRHTTPConnection

#pragma mark - Data

- (void)startReading {
    [super startReading];

    requestBodyLength = 0;
    requestBodyReceivedBytesLength = 0;

    CRHTTPServerConfiguration* config = (CRHTTPServerConfiguration*)self.server.configuration;

    // Read the request headers
    NSUInteger timeout = didPerformInitialRead ? config.CRConnectionKeepAliveTimeout : config.CRConnectionReadTimeout + config.CRHTTPConnectionReadHeaderTimeout;
    [self.socket readDataToData:[CRConnection CRLFCRLFData] withTimeout:timeout maxLength:config.CRRequestMaxHeaderLength tag:CRHTTPConnectionSocketTagBeginReadingRequest];
}

- (void)didReceiveCompleteRequestHeaders {
    CRRequest *request = self.requestBeingReceived;
    
    // Create ENV from HTTP headers
    NSDictionary<NSString*, NSString*> *headers = request.allHTTPHeaderFields;
    NSMutableDictionary* env = [NSMutableDictionary dictionaryWithCapacity:headers.count];
    [request.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        NSString* headerName = [@"HTTP_" stringByAppendingString:[key.uppercaseString stringByReplacingOccurrencesOfString:@"-" withString:@"_"]];
        env[headerName] = obj;
    }];

    env[@"CONTENT_LENGTH"] = env[@"HTTP_CONTENT_LENGTH"];
    env[@"CONTENT_TYPE"] = env[@"HTTP_CONTENT_TYPE"];
    env[@"SERVER_NAME"] = env[@"HTTP_HOST"];
    env[@"REQUEST_METHOD"] = NSStringFromCRHTTPMethod(self.requestBeingReceived.method);
    env[@"SERVER_PROTOCOL"] = NSStringFromCRHTTPVersion(self.requestBeingReceived.version);
    
    GCDAsyncSocket *socket = self.socket;
    env[@"SERVER_ADDR"] = socket.localHost;
    env[@"SERVER_PORT"] = [NSString stringWithFormat:@"%hu", socket.localPort];
    env[@"REMOTE_ADDR"] = socket.connectedHost;
    env[@"REMOTE_PORT"] = [NSString stringWithFormat:@"%hu", socket.connectedPort];
    
    NSURL *requestURL = request.URL;
    env[@"REQUEST_URI"] = requestURL.absoluteString;
    env[@"DOCUMENT_URI"] = requestURL.path;
    env[@"SCRIPT_NAME"] = requestURL.path;
    env[@"QUERY_STRING"] = requestURL.query;
    
    request.env = env;
    [request parseQueryString];
    [request parseCookiesHeader];
    [request parseRangeHeader];

    [super didReceiveCompleteRequestHeaders];

    if ( self.willDisconnect ) {
        return;
    }

    CRHTTPServerConfiguration* config = (CRHTTPServerConfiguration*)self.server.configuration;
    requestBodyLength = [env[@"CONTENT_LENGTH"] integerValue];
    if (requestBodyLength > 0) {
        NSUInteger bytesToRead = requestBodyLength < config.CRRequestBodyBufferSize ? requestBodyLength : config.CRRequestBodyBufferSize;
        [self.socket readDataToLength:bytesToRead withTimeout:config.CRHTTPConnectionReadBodyTimeout tag:CRHTTPConnectionSocketTagReadingRequestBody];
    } else {
        [self didReceiveCompleteRequest];
    }
}

#pragma mark - Responses

- (CRResponse *)responseWithHTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description version:(CRHTTPVersion)version {
    return [[CRHTTPResponse alloc] initWithConnection:self HTTPStatusCode:HTTPStatusCode description:description version:version];
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag {
    didPerformInitialRead = YES;
    CRHTTPServerConfiguration* config = (CRHTTPServerConfiguration*)self.server.configuration;

    if ( tag == CRHTTPConnectionSocketTagBeginReadingRequest ) {

        NSData* spaceData = [@" " dataUsingEncoding:NSUTF8StringEncoding];
        BOOL result = YES;

        NSRange rangeOfFirstNewline = [data rangeOfData:[CRConnection CRLFData] options:0 range:NSMakeRange(0, data.length)];
        NSRange rangeOfFirstSpace = [data rangeOfData:spaceData options:0 range:NSMakeRange(0, rangeOfFirstNewline.location)];
        if (rangeOfFirstSpace.location != NSNotFound ) {

            NSRange methodRange = NSMakeRange(0, rangeOfFirstSpace.location);
            NSRange pathSearchRange = NSMakeRange(rangeOfFirstSpace.location + rangeOfFirstSpace.length, rangeOfFirstNewline.location - rangeOfFirstSpace.location - rangeOfFirstSpace.length);
            NSRange rangeOfSecondSpace = [data rangeOfData:spaceData options:0 range:pathSearchRange];

            if ( rangeOfSecondSpace.location != NSNotFound ) {
                NSRange pathRange = NSMakeRange(pathSearchRange.location, rangeOfSecondSpace.location - pathSearchRange.location);
                NSRange versionRange = NSMakeRange(rangeOfSecondSpace.location + rangeOfSecondSpace.length, rangeOfFirstNewline.location - rangeOfSecondSpace.location - rangeOfSecondSpace.length);

                NSString * methodSpec = [[NSString alloc] initWithBytesNoCopy:(void *)data.bytes + methodRange.location length:methodRange.length encoding:NSUTF8StringEncoding freeWhenDone:NO];
                CRHTTPMethod requestMethod = CRHTTPMethodMake(methodSpec);

                if ( requestMethod != CRHTTPMethodNone ) {
                    NSString* pathSpec = [[NSString alloc] initWithBytesNoCopy:(void *)data.bytes + pathRange.location length:pathRange.length encoding:NSUTF8StringEncoding freeWhenDone:NO];

                    NSString* versionSpec = [[NSString alloc] initWithBytesNoCopy:(void *)data.bytes + versionRange.location length:versionRange.length encoding:NSUTF8StringEncoding freeWhenDone:NO];
                    CRHTTPVersion version = CRHTTPVersionMake(versionSpec);

                    NSRange rangeOfHostHeader = [data rangeOfData:[@"Host: " dataUsingEncoding:NSUTF8StringEncoding] options:0 range:NSMakeRange(0, data.length)];

                    if ( rangeOfHostHeader.location != NSNotFound || version == CRHTTPVersion1_0 ) {
                        NSString* hostSpec = @"localhost";
                        if (rangeOfHostHeader.location != NSNotFound) {
                            NSRange rangeOfNewLineAfterHost = [data rangeOfData:[CRConnection CRLFData] options:0 range:NSMakeRange(rangeOfHostHeader.location + rangeOfHostHeader.length, data.length - rangeOfHostHeader.location - rangeOfHostHeader.length)];
                            
                            if ( rangeOfNewLineAfterHost.location == NSNotFound ) {
                                rangeOfNewLineAfterHost.location = data.length - 1;
                            }
                            
                            NSRange hostSpecRange = NSMakeRange(rangeOfHostHeader.location + rangeOfHostHeader.length, rangeOfNewLineAfterHost.location - rangeOfHostHeader.location - rangeOfHostHeader.length);
                            hostSpec = [[NSString alloc] initWithBytesNoCopy:(void *)data.bytes + hostSpecRange.location length:hostSpecRange.length encoding:NSUTF8StringEncoding freeWhenDone:NO];
                        }

                        // TODO: request.URL should be parsed using no memcpy and using the actual scheme
                        NSURL* URL = [NSURL URLWithString:[NSString stringWithFormat:@"http%@://%@%@", ((CRHTTPServer *)self.server).isSecure ? @"s" : @"", hostSpec, pathSpec]];
                        CRRequest* request = [[CRRequest alloc] initWithMethod:CRHTTPMethodMake(methodSpec) URL:URL version:CRHTTPVersionMake(versionSpec) connection:self];
                        [self addRequest:request];
                        self.requestBeingReceived = request;
                    } else {
                        result = NO;
                    }
                } else {
                    result = NO;
                }
            } else {
                result = NO;
            }
        } else {
            result = NO;
        }

        if ( !result ) {
            [self.socket disconnect];
            return;
        }

        NSRange remainingDataRange = NSMakeRange(rangeOfFirstNewline.location + rangeOfFirstNewline.length, data.length - rangeOfFirstNewline.location - rangeOfFirstNewline.length);
        NSData* remainingData = [NSData dataWithBytesNoCopy:(void *)data.bytes + remainingDataRange.location length:remainingDataRange.length freeWhenDone:NO];
        if ( ! [self.requestBeingReceived appendData:remainingData] ) {
            [self.socket disconnect];
            return;
        }

        // We've read the request headers
        if ( self.requestBeingReceived.headersComplete ) {
            [self didReceiveCompleteRequestHeaders];
        } else {
            [self.socket disconnect];
            return;
        }

    } else if ( tag == CRHTTPConnectionSocketTagReadingRequestBody ) {

        // We are receiving data
        requestBodyReceivedBytesLength += data.length;
        [self didReceiveRequestBodyData:data];

        if (requestBodyReceivedBytesLength < requestBodyLength) {
            NSUInteger requestBodyLeftBytesLength = requestBodyLength - requestBodyReceivedBytesLength;
            NSUInteger bytesToRead = requestBodyLeftBytesLength < config.CRRequestBodyBufferSize ? requestBodyLeftBytesLength : config.CRRequestBodyBufferSize;
            [self.socket readDataToLength:bytesToRead withTimeout:config.CRHTTPConnectionReadBodyTimeout tag:CRHTTPConnectionSocketTagReadingRequestBody];
        } else {
            [self didReceiveCompleteRequest];
        }
    }
}

@end
