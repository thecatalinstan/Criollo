//
//  CRConnection.m
//  Criollo
//
//  Created by Cătălin Stan on 10/23/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRConnection.h"
#import "CRConnection_Internal.h"
#import "CRApplication.h"
#import "CRServer.h"
#import "CRServer_Internal.h"
#import "CRServerConfiguration.h"
#import "GCDAsyncSocket.h"
#import "CRRequest.h"
#import "CRRequest_Internal.h"
#import "CRResponse.h"
#import "CRResponse_Internal.h"

#include <sys/types.h>
#include <sys/sysctl.h>
#import "NSDate+RFC1123.h"

#define CRConnectionSocketTagSendingResponse                        20

@interface CRConnection () <GCDAsyncSocketDelegate>

@property (nonatomic, readonly) BOOL willDisconnect;

- (void)bufferBodyData:(nonnull NSData *)data forRequest:(nonnull CRRequest *)request;
- (void)bufferResponseData:(nonnull NSData *)data forRequest:(nonnull CRRequest *)request;

@end

@implementation CRConnection

+ (NSData *)CRLFCRLFData {
    static NSData* _CRLFCRLFData;
    static dispatch_once_t _CRLFCRLFDataToken;
    dispatch_once(&_CRLFCRLFDataToken, ^{
        _CRLFCRLFData = [NSData dataWithBytes:"\x0D\x0A\x0D\x0A" length:4];
    });
    return _CRLFCRLFData;
}

+ (NSData *)CRLFData {
    static NSData* _CRLFData;
    static dispatch_once_t _CRLFDataToken;
    dispatch_once(&_CRLFDataToken, ^{
        _CRLFData = [NSData dataWithBytes:"\x0D\x0A" length:2];
    });
    return _CRLFData;
}

#pragma mark - Responses

- (CRResponse *)responseWithHTTPStatusCode:(NSUInteger)HTTPStatusCode {
    return [self responseWithHTTPStatusCode:HTTPStatusCode description:nil version:nil];
}

- (CRResponse *)responseWithHTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description {
    return [self responseWithHTTPStatusCode:HTTPStatusCode description:description version:nil];
}

- (CRResponse *)responseWithHTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description version:(NSString *)version {
    return [[CRResponse alloc] initWithConnection:self HTTPStatusCode:HTTPStatusCode description:description version:version];
}

#pragma mark - Initializers

- (instancetype)init {
    return [self initWithSocket:nil server:nil];
}

- (instancetype)initWithSocket:(GCDAsyncSocket *)socket server:(CRServer *)server {
    self = [super init];
    if (self != nil) {
        self.server = server;
        self.socket = socket;
        self.socket.delegate = self;
        self.requests = [NSMutableArray array];

        _remoteAddress = self.socket.connectedHost;
        _remotePort = self.socket.connectedPort;
        _localAddress = self.socket.localHost;
        _localPort = self.socket.localPort;

        _isolationQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:[NSString stringWithFormat:@"CRConnection-IsolationQueue-%lu", self.hash]] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(self.isolationQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));

    }
    return self;
}

- (void)dealloc {
    [self.socket setDelegate:nil delegateQueue:NULL];
    [self.socket disconnect];
}

#pragma mark - Data

- (void)startReading {
    self.currentRequest = nil;
}

- (void)didReceiveCompleteRequestHeaders {
    if (self.willDisconnect) {
        return;
    }
}

- (void)didReceiveRequestBodyData:(NSData *)data {
    if ( self.willDisconnect ) {
        return;
    }

    NSLog(@"%s %lu bytes", __PRETTY_FUNCTION__, data.length);
    NSString* contentType = self.currentRequest.env[@"HTTP_CONTENT_TYPE"];
    if ([contentType hasPrefix:CRRequestTypeMultipart]) {
        NSError* bodyParsingError;
        if ( ![self.currentRequest parseMultipartBodyDataChunk:data error:&bodyParsingError] ) {
            NSLog(@" * bodyParsingError = %@", bodyParsingError);
        }
    } else {
        [self bufferBodyData:data forRequest:self.currentRequest];
    }
}

- (void)didReceiveCompleteRequest {
    if ( self.willDisconnect ) {
        return;
    }

    // Parse request body
    NSUInteger contentLength = [self.currentRequest.env[@"HTTP_CONTENT_LENGTH"] integerValue];
    if ( contentLength > 0 ) {
        NSError* bodyParsingError;
        NSString* contentType = self.currentRequest.env[@"HTTP_CONTENT_TYPE"];

        BOOL result = YES;

        if ([contentType hasPrefix:CRRequestTypeJSON]) {
            result = [self.currentRequest parseJSONBodyData:&bodyParsingError];
        } else if ([contentType hasPrefix:CRRequestTypeMultipart]) {
        } else if ([contentType hasPrefix:CRRequestTypeURLEncoded]) {
            result = [self.currentRequest parseURLEncodedBodyData:&bodyParsingError];
        } else {
            result = [self.currentRequest parseBufferedBodyData:&bodyParsingError];
        }

        if ( !result ) {
            NSLog(@" * bodyParsingError = %@", bodyParsingError);
        } else {
            NSLog(@" * request.body = %@", self.currentRequest.body);
            NSLog(@" * bufferedBodyData = %lu bytes", self.currentRequest.bufferedBodyData.length);
        }
    }

    CRResponse* response = [self responseWithHTTPStatusCode:200];
    [self.currentRequest setResponse:response];
    [response setRequest:self.currentRequest];
    [self.requests addObject:self.currentRequest];
    [self.delegate connection:self didReceiveRequest:self.currentRequest response:response];
    [self startReading];
}

- (void)bufferBodyData:(NSData *)data forRequest:(CRRequest *)request {
    if ( self.willDisconnect ) {
        return;
    }
    [request bufferBodyData:data];
}

- (void)bufferResponseData:(NSData *)data forRequest:(CRRequest *)request {
    if ( self.willDisconnect ) {
        return;
    }
    [request bufferResponseData:data];
}

- (void)sendDataToSocket:(NSData *)data forRequest:(CRRequest *)request {
    if ( self.willDisconnect ) {
        return;
    }
    CRRequest* firstRequest = self.requests.firstObject;
    if ( [firstRequest isEqual:request] ) {
        request.bufferedResponseData = nil;
        [self.socket writeData:data withTimeout:self.server.configuration.CRConnectionWriteTimeout tag:CRConnectionSocketTagSendingResponse];
        if ( request.shouldCloseConnection ) {
            _willDisconnect = YES;
            [self.socket disconnectAfterWriting];
        }
        if ( request.response.finished ) {
            [self didFinishResponseForRequest:request];
        }
    } else {
        [self bufferResponseData:data forRequest:request];
    }
}

- (void)didFinishResponseForRequest:(CRRequest *)request {
    [self.delegate connection:self didFinishRequest:request response:request.response];
    [self.requests removeObject:request];
}

#pragma mark - State

- (BOOL)shouldClose {
    return NO;
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    switch (tag) {
        case CRConnectionSocketTagSendingResponse: {
            CRRequest* request = (CRRequest*)self.requests.firstObject;
            if ( request.bufferedResponseData.length > 0 ) {
                [self sendDataToSocket:request.bufferedResponseData forRequest:request];
            }
        } break;

        default:
            break;
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    [self.requests removeAllObjects];
    [self.server didCloseConnection:self];
}

@end
