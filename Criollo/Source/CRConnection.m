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
    return [self initWithSocket:nil server:nil delegateQueue:nil];
}

- (instancetype)initWithSocket:(GCDAsyncSocket *)socket server:(CRServer *)server {
    NSString* acceptedSocketDelegateQueueLabel = [[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:[NSString stringWithFormat:@"SocketDelegateQueue-%hu", socket.connectedPort]];
    dispatch_queue_t acceptedSocketDelegateQueue = dispatch_queue_create([acceptedSocketDelegateQueueLabel cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    return  [self initWithSocket:socket server:server delegateQueue:acceptedSocketDelegateQueue];
}

- (instancetype)initWithSocket:(GCDAsyncSocket *)socket server:(CRServer *)server delegateQueue:(dispatch_queue_t)delegateQueue {
    self = [super init];
    if (self != nil) {
        self.server = server;
        self.socket = socket;
        [self.socket setDelegate:self delegateQueue:delegateQueue];
    }
    return self;
}

#pragma mark - Data

- (void)startReading {
    [self.socket readDataToData:[CRConnection CRLFData] withTimeout:self.server.configuration.CRConnectionInitialReadTimeout tag:0];
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.socket writeData:data withTimeout:self.server.configuration.CRConnectionInitialReadTimeout tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self.socket = nil;
    dispatch_async(self.server.delegateQueue, ^{ @autoreleasepool {
        [self.server didCloseConnection:self];
    }});
}

@end
