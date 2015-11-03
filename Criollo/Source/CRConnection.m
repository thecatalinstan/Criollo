//
//  CRConnection.m
//  Criollo
//
//  Created by Cătălin Stan on 10/23/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRConnection.h"
#import "CRServer.h"
#import "CRServerConfiguration.h"
#import "GCDAsyncSocket.h"
#import "CRRequest.h"
#import "CRResponse.h"

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
    }
    return self;
}

- (void)dealloc {
    [self.socket setDelegate:nil delegateQueue:NULL];
    [self.socket disconnect];
}

#pragma mark - Data

- (void)startReading {
}

- (void)didReceiveCompleteRequestHeaders {
}

- (void)didReceiveRequestBody {
}

- (void)didReceiveCompleteRequest {
//    NSMutableString* string = [NSMutableString stringWithString:@"<h1>Hello world!</h1>"];
//    self.response = [[CRFCGIResponse alloc] initWithConnection:self HTTPStatusCode:200 description:nil version:self.request.version];
//    [self.response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-type"];
//    [self.response writeString:string];
//    [self.response finish];
//
//    NSMutableString* string = [NSMutableString stringWithString:@"<h1>Hello world!</h1>"];
//    self.response = [[CRHTTPResponse alloc] initWithConnection:self HTTPStatusCode:200 description:@"asdfadsfas" version:self.request.version];
//    [self.response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-type"];
//    [self.response sendString:string];
}

- (void)handleError:(NSUInteger)errorType object:(id)object {
//    NSUInteger statusCode = 500;
//
//    switch (errorType) {
//        case CRErrorRequestMalformedRequest:
//            statusCode = 400;
//            [CRApp logErrorFormat:@"Malformed request: %@", [[NSString alloc] initWithData:object encoding:NSUTF8StringEncoding] ];
//            break;
//
//        case CRErrorRequestUnsupportedMethod:
//            statusCode = 405;
//            [CRApp logErrorFormat:@"Cannot %@", object[CRRequestKey]];
//            break;
//
//        default:
//            break;
//    }
//
//    self.response = [[CRFCGIResponse alloc] initWithConnection:self HTTPStatusCode:statusCode];
//    self.response = [[CRHTTPResponse alloc] initWithConnection:self HTTPStatusCode:statusCode];
//    [self.response setValue:@"close" forHTTPHeaderField:@"Connection"];
//    [self.response setValue:@"text/plain" forHTTPHeaderField:@"Content-type"];
//    [self.response writeFormat:@"Cannot %@", object[CRRequestKey]];
//    [self.response finish];
}

#pragma mark - State
- (BOOL)shouldClose {
    return NO;
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {

    switch ( tag ) {
        case CRConnectionSocketTagFinishSendingResponseAndClosing:
        case CRConnectionSocketTagFinishSendingResponse:
            if ( tag == CRConnectionSocketTagFinishSendingResponseAndClosing || self.shouldClose) {
                [self.socket disconnectAfterWriting];
            } else {
                [self startReading];
            }
            break;

        default:
            break;
    }

}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    [self.server didCloseConnection:self];
}



@end
