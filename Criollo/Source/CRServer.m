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

@interface CRServer () {

}

@property (nonatomic, strong) dispatch_queue_t isolationQueue;
@property (nonatomic, strong) dispatch_queue_t socketDelegateQueue;
@property (nonatomic, strong) dispatch_queue_t acceptedSocketDelegateTargetQueue;
@property (nonatomic, strong) dispatch_queue_t acceptedSocketSocketTargetQueue;

@end

@implementation CRServer

- (instancetype)init {
    return [self initWithDelegate:nil];
}

- (instancetype)initWithDelegate:(id<CRServerDelegate>)delegate {
    self = [super init];
    if ( self != nil ) {
        self.configuration = [[CRServerConfiguration alloc] init];
        self.delegate = delegate;
    }
    return self;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    NSLog(@"%@.%@ = %lu", object, keyPath, ((NSArray*)change[NSKeyValueChangeNewKey]).count);
}

#pragma mark - Listening

- (BOOL)startListening {
    return [self startListeningOnPortNumber:0 interface:nil error:nil];
}

- (BOOL)startListening:(NSError *__autoreleasing *)error {
    return [self startListeningOnPortNumber:0 interface:nil error:error];
}

- (BOOL)startListeningOnPortNumber:(NSUInteger)portNumber error:(NSError *__autoreleasing *)error {
    return [self startListeningOnPortNumber:portNumber interface:nil error:error];
}

- (BOOL)startListeningOnPortNumber:(NSUInteger)portNumber interface:(NSString *)interface error:(NSError *__autoreleasing *)error {

    if ( portNumber != 0 ) {
        self.configuration.CRServerPort = portNumber;
    }
    if ( interface.length != 0 ) {
        self.configuration.CRServerInterface = interface;
    }

    self.isolationQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"IsolationQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(self.isolationQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));

    self.socketDelegateQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"DelegateQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
    dispatch_set_target_queue(self.socketDelegateQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));

    self.acceptedSocketSocketTargetQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"AcceptedSocketSocketTargetQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(self.acceptedSocketSocketTargetQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));

    self.acceptedSocketDelegateTargetQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"AcceptedSocketDelegateTargetQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(self.acceptedSocketDelegateTargetQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));

    self.connections = [NSMutableArray array];
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.socketDelegateQueue];

    if ( [self.delegate respondsToSelector:@selector(serverWillStartListening:)] ) {
        [self.delegate serverWillStartListening:self];
    }

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

    if ( [self.delegate respondsToSelector:@selector(serverDidStopListening:)] ) {
        [self.delegate serverDidStopListening:self];
    }
    
}

#pragma mark - Connections

- (void)closeAllConnections {
    dispatch_barrier_async(self.isolationQueue, ^{
        [self.connections enumerateObjectsUsingBlock:^(CRConnection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj.socket disconnectAfterReadingAndWriting];
        }];
        [self.connections removeAllObjects];
    });
}

- (CRConnection*)newConnectionWithSocket:(GCDAsyncSocket*)socket {
    return [[CRConnection alloc] initWithSocket:socket server:self];
}

- (void)didCloseConnection:(CRConnection*)connection {
    if ( [self.delegate respondsToSelector:@selector(server:didCloseConnection:)]) {
        [self.delegate server:self didCloseConnection:connection];
    }
    dispatch_async(self.isolationQueue, ^(){
        [self.connections removeObject:connection];
    });
}

#pragma mark - Routing

- (BOOL)canHandleHTTPMethod:(NSString *)HTTPMethod forPath:(NSString *)path
{
    return YES;
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    [newSocket markSocketQueueTargetQueue:self.acceptedSocketSocketTargetQueue];

    dispatch_queue_t acceptedSocketDelegateQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:[NSString stringWithFormat:@"SocketDelegateQueue-%hu", newSocket.connectedPort]] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
    dispatch_set_target_queue(acceptedSocketDelegateQueue, self.acceptedSocketDelegateTargetQueue);
    newSocket.delegateQueue = acceptedSocketDelegateQueue;

    CRConnection* connection = [self newConnectionWithSocket:newSocket];
    dispatch_async(self.isolationQueue, ^(){
        [self.connections addObject:connection];
        connection.ignoreKeepAlive = self.connections.count >= self.configuration.CRHTTPConnectionMaxKeepAliveConnections;
    });
    if ( [self.delegate respondsToSelector:@selector(server:didAcceptConnection:)]) {
        [self.delegate server:self didAcceptConnection:connection];
    }
    [connection startReading];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
}

@end
