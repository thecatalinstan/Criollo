//
//  CRConnection.m
//  Criollo
//
//  Created by Cătălin Stan on 10/23/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRConnection.h"
#import "CRApplication.h"
#import "CRServer.h"
#import "CRServerConfiguration.h"
#import "GCDAsyncSocket.h"
#import "CRRequest.h"
#import "CRResponse.h"

#include <sys/types.h>
#include <sys/sysctl.h>
#import "NSDate+RFC1123.h"

@interface CRConnection () <GCDAsyncSocketDelegate> 

- (void)bufferResponseData:(NSData*)data forRequest:(CRRequest*)request;

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
}

- (void)didReceiveRequestBody {
}

- (void)didReceiveCompleteRequest {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    CRResponse* response = [self responseWithHTTPStatusCode:200];
    [self.currentRequest setResponse:response];
    [response setRequest:self.currentRequest];
    [self.requests addObject:self.currentRequest];
    [self.delegate connection:self didReceiveRequest:self.currentRequest response:response];
    [self startReading];
}

- (void)bufferResponseData:(NSData *)data forRequest:(CRRequest *)request {
    if ( request.bufferedResponseData == nil ) {
        request.bufferedResponseData = [[NSMutableData alloc] initWithData:data];
    } else {
        [request.bufferedResponseData appendData:data];
    }
}

- (void)sendDataToSocket:(NSData *)data forRequest:(CRRequest *)request {
    CRRequest* firstRequest = self.requests.firstObject;
    if ( [firstRequest isEqual:request] ) {
        request.bufferedResponseData = nil;
        [self.socket writeData:data withTimeout:self.server.configuration.CRConnectionWriteTimeout tag:CRConnectionSocketTagSendingResponse];
        if ( request.shouldCloseConnection ) {
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
