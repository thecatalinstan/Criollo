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
#import "CRServerConfiguration.h"
#import "CRRequest.h"
#import "CRResponse.h"

@interface CRHTTPConnection () {
    NSUInteger requestBodyLength;
    NSUInteger requestBodyReceivedBytesLength;
    BOOL didPerformInitialRead;
}

- (void)didReceiveRequestHeaderData:(NSData*)data;
- (void)didReceiveRequestBodyData:(NSData*)data;

@end

@implementation CRHTTPConnection

- (instancetype)initWithSocket:(GCDAsyncSocket *)socket server:(CRServer *)server delegateQueue:(dispatch_queue_t)delegateQueue {
    self = [super initWithSocket:socket server:server delegateQueue:delegateQueue];
    if ( self != nil ) {

    }
    return self;
}

#pragma mark - Data

- (void)startReading {
    requestBodyLength = 0;
    requestBodyReceivedBytesLength = 0;

    // Read the first request header
    [self.socket readDataToData:[CRConnection CRLFData] withTimeout:(didPerformInitialRead ? self.server.configuration.CRHTTPConnectionKeepAliveTimeout : self.server.configuration.CRConnectionInitialReadTimeout) + self.server.configuration.CRHTTPConnectionReadHeaderLineTimeout maxLength:self.server.configuration.CRRequestMaxHeaderLineLength tag:CRSocketTagBeginReadingRequest];
}

- (void)didReceiveRequestHeaderData:(NSData*)data {
}

- (void)didReceiveRequestBodyData:(NSData*)data {
}

- (void)didReceiveCompleteRequestHeaders {
    [super didReceiveCompleteRequestHeaders];
}

- (void)didReceiveRequestBody {
    [super didReceiveRequestBody];
}

- (void)didReceiveCompleteRequest {
    [super didReceiveCompleteRequest];

    NSMutableString* string = [NSMutableString stringWithString:@"<h1>Hello world!</h1>"];
    self.response = [[CRResponse alloc] initWithHTTPConnection:self HTTPStatusCode:200 description:@"asdfadsfas" version:self.request.version];
    [self.response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-type"];
    [self.response writeString:string];
    [self.response finish];
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

    self.response = [[CRResponse alloc] initWithHTTPConnection:self HTTPStatusCode:statusCode];
    [self.response setValue:@"0" forHTTPHeaderField:@"Content-length"];
    [self.response setValue:@"close" forHTTPHeaderField:@"Connection"];
    [self.response end];
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag {

    didPerformInitialRead = YES;

    if ( tag == CRSocketTagBeginReadingRequest ) {
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

    switch (tag) {
        case CRSocketTagBeginReadingRequest:
            // We've read the first header line and it's ok.
            // Continue to read the rest of the headers
            [self didReceiveRequestHeaderData:data];
            [self.socket readDataToData:[CRConnection CRLFCRLFData] withTimeout:self.server.configuration.CRHTTPConnectionReadHeaderTimeout maxLength:self.server.configuration.CRRequestMaxHeaderLength tag:CRSocketTagReadingRequestHeader];
            break;

        case CRSocketTagReadingRequestHeader:
            // We have all the headers
            [self didReceiveRequestHeaderData:data];
            [self didReceiveCompleteRequestHeaders];

            requestBodyLength = [self.request valueForHTTPHeaderField:@"Content-Length"].integerValue;
            if ( requestBodyLength > 0 ) {
                NSUInteger bytesToRead = requestBodyLength < self.server.configuration.CRRequestBodyBufferSize ? requestBodyLength : self.server.configuration.CRRequestBodyBufferSize;
                [self.socket readDataToLength:bytesToRead withTimeout:self.server.configuration.CRHTTPConnectionReadBodyTimeout tag:CRSocketTagReadingRequestBody];
            } else {
                [self didReceiveCompleteRequest];
            }
            break;

        case CRSocketTagReadingRequestBody:
            // We are receiving data
            [self didReceiveRequestBodyData:data];
            requestBodyReceivedBytesLength += data.length;

            if (requestBodyReceivedBytesLength < requestBodyLength) {
                NSUInteger requestBodyLeftBytesLength = requestBodyLength - requestBodyReceivedBytesLength;
                NSUInteger bytesToRead = requestBodyLeftBytesLength < self.server.configuration.CRRequestBodyBufferSize ? requestBodyLeftBytesLength : self.server.configuration.CRRequestBodyBufferSize;
                [self.socket readDataToLength:bytesToRead withTimeout:self.server.configuration.CRHTTPConnectionReadBodyTimeout tag:CRSocketTagReadingRequestBody];
            } else {
                [self didReceiveCompleteRequest];
            }
            break;
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {

    switch ( tag ) {
        case CRSocketTagFinishSendingResponseAndClosing:
        case CRSocketTagFinishSendingResponse:
            if ( tag == CRSocketTagFinishSendingResponseAndClosing || self.shouldClose) {
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
