//
//  CRHTTPConnection.m
//  Criollo
//
//  Created by Cătălin Stan on 10/25/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRHTTPConnection.h"
#import "GCDAsyncSocket.h"
#import "CRApplication.h"
#import "CRServer.h"
#import "CRHTTPServerConfiguration.h"
#import "CRRequest.h"
#import "CRHTTPResponse.h"

@interface CRHTTPConnection () {
    NSUInteger requestBodyLength;
    NSUInteger requestBodyReceivedBytesLength;
    BOOL didPerformInitialRead;
}

@end

@implementation CRHTTPConnection

#pragma mark - Data

- (void)startReading {
    requestBodyLength = 0;
    requestBodyReceivedBytesLength = 0;

    CRHTTPServerConfiguration* config = (CRHTTPServerConfiguration*)self.server.configuration;

    // Read the first request header
    NSUInteger timeout = didPerformInitialRead ? config.CRConnectionKeepAliveTimeout : config.CRConnectionInitialReadTimeout + config.CRHTTPConnectionReadHeaderLineTimeout;
    [self.socket readDataToData:[CRConnection CRLFData] withTimeout:timeout maxLength:config.CRRequestMaxHeaderLineLength tag:CRHTTPConnectionSocketTagBeginReadingRequest];
}

- (void)didReceiveCompleteRequestHeaders {
    [super didReceiveCompleteRequestHeaders];
    //    NSLog(@"%@", self.request.allHTTPHeaderFields);
}

- (void)didReceiveRequestBody {
    [super didReceiveRequestBody];
}

- (void)didReceiveCompleteRequest {
    [super didReceiveCompleteRequest];

    NSMutableString* string = [NSMutableString stringWithString:@"<h1>Hello world!</h1>"];
    self.response = [[CRHTTPResponse alloc] initWithConnection:self HTTPStatusCode:200 description:@"asdfadsfas" version:self.request.version];
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

    self.response = [[CRHTTPResponse alloc] initWithConnection:self HTTPStatusCode:statusCode];
    [self.response setValue:@"0" forHTTPHeaderField:@"Content-length"];
    [self.response setValue:@"close" forHTTPHeaderField:@"Connection"];
    [self.response end];
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag {

    didPerformInitialRead = YES;

    if ( tag == CRHTTPConnectionSocketTagBeginReadingRequest ) {
        // Parse the first line of the header
        NSString* decodedHeader = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, data.length - 2)] encoding:NSUTF8StringEncoding];
        NSArray* decodedHeaderComponents = [decodedHeader componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        if ( decodedHeaderComponents.count == 3 ) {
            NSString *method = decodedHeaderComponents[0];
            NSString *path = decodedHeaderComponents[1];
            NSString *version = decodedHeaderComponents[2];
            if ( [self.server canHandleHTTPMethod:method forPath:path] ) {
                self.request = [[CRRequest alloc] initWithMethod:method URL:[NSURL URLWithString:path] version:version];
            } else {
                [self handleError:CRErrorRequestUnsupportedMethod object:@{CRRequestKey:[NSString stringWithFormat:@"%@ %@", method, path]}];
                return;
            }
        } else {
            [self handleError:CRErrorRequestMalformedRequest object:data];
            return;
        }

    }

    BOOL result = [self.request appendData:data];
    if (!result) {
        // Failed on first read
        [self handleError:CRErrorRequestMalformedRequest object:data];
        return;
    }

    CRHTTPServerConfiguration* config = (CRHTTPServerConfiguration*)self.server.configuration;

    switch (tag) {
        case CRHTTPConnectionSocketTagBeginReadingRequest:
            // We've read the first header line and it's ok.
            // Continue to read the rest of the headers
            [self.socket readDataToData:[CRConnection CRLFCRLFData] withTimeout:config.CRHTTPConnectionReadHeaderTimeout maxLength:config.CRRequestMaxHeaderLength tag:CRHTTPConnectionSocketTagReadingRequestHeader];
            break;

        case CRHTTPConnectionSocketTagReadingRequestHeader:
            // We have all the headers
            [self didReceiveCompleteRequestHeaders];

            requestBodyLength = [self.request valueForHTTPHeaderField:@"Content-Length"].integerValue;
            if ( requestBodyLength > 0 ) {
                NSUInteger bytesToRead = requestBodyLength < config.CRRequestBodyBufferSize ? requestBodyLength : config.CRRequestBodyBufferSize;
                [self.socket readDataToLength:bytesToRead withTimeout:config.CRHTTPConnectionReadBodyTimeout tag:CRHTTPConnectionSocketTagReadingRequestBody];
            } else {
                [self didReceiveCompleteRequest];
            }
            break;

        case CRHTTPConnectionSocketTagReadingRequestBody:
            // We are receiving data
            requestBodyReceivedBytesLength += data.length;

            if (requestBodyReceivedBytesLength < requestBodyLength) {
                NSUInteger requestBodyLeftBytesLength = requestBodyLength - requestBodyReceivedBytesLength;
                NSUInteger bytesToRead = requestBodyLeftBytesLength < config.CRRequestBodyBufferSize ? requestBodyLeftBytesLength : config.CRRequestBodyBufferSize;
                [self.socket readDataToLength:bytesToRead withTimeout:config.CRHTTPConnectionReadBodyTimeout tag:CRHTTPConnectionSocketTagReadingRequestBody];
            } else {
                [self didReceiveCompleteRequest];
            }
            break;
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {

    switch ( tag ) {
        case CRHTTPConnectionSocketTagFinishSendingResponseAndClosing:
        case CRHTTPConnectionSocketTagFinishSendingResponse:
            if ( tag == CRHTTPConnectionSocketTagFinishSendingResponseAndClosing || self.shouldClose) {
                [self.socket disconnect];
            } else {
                [self startReading];
            }
            break;
            
        default:
            break;
    }
    
}

@end
