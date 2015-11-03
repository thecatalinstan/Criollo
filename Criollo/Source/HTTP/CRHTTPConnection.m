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

    // Create ENV from HTTP headers
    NSMutableDictionary* env = [NSMutableDictionary dictionary];
    [self.request.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        NSString* headerName = [@"HTTP_" stringByAppendingString:[key.uppercaseString stringByReplacingOccurrencesOfString:@"-" withString:@"_"]];
        [env setObject:obj forKey:headerName];
    }];

    if ( env[@"HTTP_CONTENT_LENGTH"] ) {
        env[@"CONTENT_LENGTH"] = env[@"HTTP_CONTENT_LENGTH"];
    }
    if ( env[@"HTTP_CONTENT_TYPE"] ) {
        env[@"CONTENT_TYPE"] = env[@"HTTP_CONTENT_TYPE"];
    }

    if ( env[@"HTTP_HOST"]) {
        env[@"SERVER_NAME"] = env[@"HTTP_HOST"];
    }
//    env[@"SERVER_SOFTWARE"] = @"";

    env[@"REQUEST_METHOD"] = self.request.method;
    env[@"SERVER_PROTOCOL"] = self.request.version;
    env[@"REQUEST_URI"] = self.request.URL.absoluteString;
    env[@"DOCUMENT_URI"] = self.request.URL.path;
    env[@"SCRIPT_NAME"] = self.request.URL.path;
    env[@"QUERY_STRING"] = self.request.URL.query;

    env[@"REMOTE_ADDR"] = self.socket.connectedHost;
    env[@"REMOTE_PORT"] = @(self.socket.connectedPort);
    env[@"SERVER_ADDR"] = self.socket.localHost;
    env[@"SERVER_PORT"] = @(self.socket.localPort);

    [self.request setEnv:env];
}

- (void)didReceiveRequestBody {
    [super didReceiveRequestBody];
}

- (void)didReceiveCompleteRequest {
    [super didReceiveCompleteRequest];
}

- (void)handleError:(NSUInteger)errorType object:(id)object {
    [super handleError:errorType object:object];
}

#pragma mark - State

- (BOOL)shouldClose {
    if ( self.ignoreKeepAlive ) {
        return YES;
    }

    BOOL shouldClose = NO;

    NSString *connectionHeader = [self.request valueForHTTPHeaderField:@"Connection"];
    if ( connectionHeader != nil ) {
        shouldClose = [connectionHeader caseInsensitiveCompare:@"close"] == NSOrderedSame;
    } else {
        shouldClose = [self.request.version isEqualToString:CRHTTP10];
    }

    return shouldClose;
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

@end
