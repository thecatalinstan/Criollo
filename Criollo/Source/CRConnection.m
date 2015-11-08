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
    CRResponse* response = [self responseWithHTTPStatusCode:200];
    [self.currentRequest setResponse:response];
    [response setRequest:self.currentRequest];
    [self.requests addObject:self.currentRequest];
    [self.delegate connection:self didReceiveRequest:self.currentRequest response:response];
    [self startReading];
}

- (void)sendData:(NSData *)data forResponse:(CRResponse *)response {
    CRRequest* firstRequest = self.requests.firstObject;
    if ( [firstRequest.response isEqual:response] ) {
        [self.socket writeData:data withTimeout:self.server.configuration.CRConnectionWriteTimeout tag:CRConnectionSocketTagSendingResponse];
        if ( response.request.shouldCloseConnection ) {
            [self.socket disconnectAfterWriting];
        }
        if ( response.finished ) {
            [self didFinishResponse:response];
        }
    }
}

- (void)didFinishResponse:(CRResponse *)response {
    NSLog(@"%@", [self.requests valueForKeyPath:@"response"]);
    [self.requests enumerateObjectsUsingBlock:^(CRRequest * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ( [obj.response isEqualTo:response] ) {
            [self.requests removeObject:obj];
            *stop = YES;
        }
    }];
    NSLog(@"%@", self.requests);
}

#pragma mark - State

- (BOOL)shouldClose {
    return NO;
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    [self.server didCloseConnection:self];
}

@end
