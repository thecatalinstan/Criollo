//
//  CRServer.m
//  Criollo
//
//  Created by Catalin Stan on 7/24/15.
//  Copyright (c) 2015 Cătălin Stan. All rights reserved.
//

#import "CRServer.h"
#import "CRServerConfiguration.h"
#import "GCDAsyncSocket.h"
#import "CRConnection.h"

NSUInteger const CRErrorSocketError = 2001;

NSString* const CRRequestKey = @"CRRequest";
NSString* const CRResponseKey = @"CRResponse";

@interface CRServer ()

@end

@implementation CRServer

- (instancetype)init {
    return [self initWithDelegate:nil portNumber:0 interface:nil];
}

- (instancetype)initWithDelegate:(id<CRServerDelegate>)delegate {
    return [self initWithDelegate:delegate portNumber:0 interface:nil];
}

- (instancetype)initWithDelegate:(id<CRServerDelegate>)delegate portNumber:(NSUInteger)portNumber {
    return [self initWithDelegate:delegate portNumber:portNumber interface:nil];
}

- (instancetype)initWithDelegate:(id<CRServerDelegate>)delegate portNumber:(NSUInteger)portNumber interface:(NSString *)interface {
    self = [super init];
    if ( self != nil ) {
        self.connections = [NSMutableArray array];
        self.configuration = [[CRServerConfiguration alloc] init];
        if ( portNumber != 0 ) {
            self.configuration.CRServerPort = portNumber;
        }
        if ( interface.length != 0 ) {
            self.configuration.CRServerInterface = interface;
        }
    }
    return self;
}

#pragma mark - Listening

- (BOOL)startListening:(NSError**)error {

    self.delegateQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"DelegateQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(self.delegateQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));

    self.acceptedSocketSocketTargetQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"AcceptedSocketSocketTargetQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(self.acceptedSocketSocketTargetQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));

    self.acceptedSocketDelegateTargetQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"AcceptedSocketDelegateTargetQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(self.acceptedSocketDelegateTargetQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));

    if ( [self.delegate respondsToSelector:@selector(serverWillStartListening:)] ) {
        [self.delegate serverWillStartListening:self];
    }

    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.delegateQueue];

    BOOL listening = [self.socket acceptOnInterface:self.configuration.CRServerInterface port:self.configuration.CRServerPort error:error];
    if ( listening && [self.delegate respondsToSelector:@selector(serverDidStartListening:)] ) {
        [self.delegate serverDidStartListening:self];
    }

    return listening;
}

- (void)stopListening {

    if ( [self.delegate respondsToSelector:@selector(serverWillStopListening:)] ) {
        [self.delegate serverWillStopListening:self];
    }

    [self.socket disconnect];
    self.socket.delegate = nil;
    self.socket = nil;

    self.delegateQueue = nil;

    [self.connections removeAllObjects];

    if ( [self.delegate respondsToSelector:@selector(serverDidStopListening:)] ) {
        [self.delegate serverDidStopListening:self];
    }
}

#pragma mark - Connections

- (CRConnection*)newConnectionWithSocket:(GCDAsyncSocket*)socket {
    return [[CRConnection alloc] initWithSocket:socket server:self];
}

- (void)didCloseConnection:(CRConnection*)connection {
    if ( [self.delegate respondsToSelector:@selector(server:didCloseConnection:)]) {
        [self.delegate server:self didCloseConnection:connection];
    }
    @synchronized(self.connections) {
        [self.connections removeObject:connection];
    }
}

#pragma mark - Routing

- (BOOL)canHandleHTTPMethod:(NSString *)HTTPMethod forPath:(NSString *)path
{
    return YES;
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    [newSocket markSocketQueueTargetQueue:self.acceptedSocketSocketTargetQueue];
    CRConnection* connection = [self newConnectionWithSocket:newSocket];
    @synchronized(self.connections) {
        [self.connections addObject:connection];
        connection.ignoreKeepAlive = self.connections.count >= self.configuration.CRHTTPConnectionMaxKeepAliveConnections;
    }
    if ( [self.delegate respondsToSelector:@selector(server:didAcceptConnection:)]) {
        [self.delegate server:self didAcceptConnection:connection];
    }
    [connection startReading];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
}

@end
