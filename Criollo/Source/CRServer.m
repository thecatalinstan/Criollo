//
//  CRServer.m
//  Criollo
//
//  Created by Catalin Stan on 7/24/15.
//  Copyright (c) 2015 Cătălin Stan. All rights reserved.
//

#import "CRServer.h"
#import "CRServer_Internal.h"
#import "CRRouter_Internal.h"
#import "CRServerConfiguration.h"
#import "GCDAsyncSocket.h"
#import "CRConnection.h"
#import "CRConnection_Internal.h"
#import "CRMessage_Internal.h"
#import "CRRequest.h"
#import "CRResponse.h"
#import "CRRoute.h"
#import "CRViewController.h"

static NSUInteger const InitialConnectionCapacity = 1 << 10;
static NSString *const CRServerDefaultWorkerQueueName = @"CRServerDefaultWorkerQueue";

static NSString *const IsListeningKey = @"isListening";
static NSString *const WorkerQueueKey = @"workerQueue";

NS_ASSUME_NONNULL_BEGIN

@interface CRServer () <GCDAsyncSocketDelegate, CRConnectionDelegate>

@property (nonatomic, strong) dispatch_queue_t isolationQueue;
@property (nonatomic, strong) dispatch_queue_t socketDelegateQueue;
@property (nonatomic, strong) dispatch_queue_t acceptedSocketDelegateTargetQueue;
@property (nonatomic, strong, nullable) GCDAsyncSocket* socket;

- (CRConnection *)newConnectionWithSocket:(GCDAsyncSocket *)socket;

- (NSOperationQueue *)createDefaultWorkerQueue NS_WARN_UNUSED_RESULT;
@end

NS_ASSUME_NONNULL_END

@implementation CRServer

- (instancetype)init {
    return [self initWithDelegate:nil delegateQueue:nil];
}

- (instancetype)initWithDelegate:(id<CRServerDelegate>)delegate {
    return [self initWithDelegate:delegate delegateQueue:nil];
}

- (instancetype)initWithDelegate:(id<CRServerDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    self = [super init];
    if ( self != nil ) {
        _configuration = [[CRServerConfiguration alloc] init];
        _delegate = delegate;
        _delegateQueue = delegateQueue;
        if ( _delegateQueue == nil ) {
            _delegateQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"ServerDelegateQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
            dispatch_set_target_queue(_delegateQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
        }
    }
    return self;
}

#pragma mark - Listening

- (BOOL)startListening {
    return [self startListening:nil portNumber:0 interface:nil];
}

- (BOOL)startListening:(NSError *__autoreleasing *)error {
    return [self startListening:error portNumber:0 interface:nil];
}

- (BOOL)startListening:(NSError *__autoreleasing *)error portNumber:(NSUInteger)portNumber {
    return [self startListening:error portNumber:portNumber interface:nil];
}

- (BOOL)startListening:(NSError *__autoreleasing *)error portNumber:(NSUInteger)portNumber interface:(NSString *)interface {

    if ( portNumber != 0 ) {
        self.configuration.CRServerPort = portNumber;
    }

    if ( interface.length != 0 ) {
        self.configuration.CRServerInterface = interface;
    }

    self.isolationQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"ServerIsolationQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(self.isolationQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));

    self.socketDelegateQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"SocketDelegateQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
    dispatch_set_target_queue(self.socketDelegateQueue, dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0));

    self.acceptedSocketDelegateTargetQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"AcceptedSocketDelegateTargetQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(self.acceptedSocketDelegateTargetQueue, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0));

    if (self.workerQueue == nil) {
        _workerQueue = [self createDefaultWorkerQueue];
        _workerQueueIsDefaultQueue = YES;
    }

    self.connections = [NSMutableArray arrayWithCapacity:InitialConnectionCapacity];
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.socketDelegateQueue];

    [self willChangeValueForKey:IsListeningKey];
    
    if ([self.delegate respondsToSelector:@selector(serverWillStartListening:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate serverWillStartListening:self];
        });
    }

    BOOL listening = [self.socket acceptOnInterface:self.configuration.CRServerInterface port:self.configuration.CRServerPort error:error];
    if (listening && [self.delegate respondsToSelector:@selector(serverDidStartListening:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate serverDidStartListening:self];
        });
    }
    
    _isListening = listening;
    [self didChangeValueForKey:IsListeningKey];
    
    return listening;
}

- (void)stopListening {
    [self willChangeValueForKey:IsListeningKey];
    
    if ([self.delegate respondsToSelector:@selector(serverWillStopListening:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate serverWillStopListening:self];
        });
    }

    [self.workerQueue cancelAllOperations];
    
    self.socket.delegate = nil;
    [self.socket disconnect];
    self.socket = nil;

    _isListening = NO;
    
    if(self.workerQueueIsDefaultQueue) {
        self.workerQueue = nil;
        _workerQueueIsDefaultQueue = NO;
    }
    

    [self didChangeValueForKey:IsListeningKey];
}

#pragma mark - Connections

- (void)closeAllConnections:(dispatch_block_t)completion {
    CRServer * __weak server = self;
    dispatch_async(self.isolationQueue ? : dispatch_get_main_queue(), ^{ @autoreleasepool {
        [server.connections enumerateObjectsUsingBlock:^(CRConnection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) { @autoreleasepool {
            [obj.socket disconnectAfterReadingAndWriting];
        }}];
        [server.connections removeAllObjects];
        if ( completion ) {
            dispatch_async(server.delegateQueue, completion);
        }
    }});
}

- (CRConnection*)newConnectionWithSocket:(GCDAsyncSocket*)socket {
    return [[CRConnection alloc] initWithSocket:socket server:self];
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    dispatch_queue_t acceptedSocketDelegateQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:[NSString stringWithFormat:@"SocketDelegateQueue-%hu", newSocket.connectedPort]] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
    dispatch_set_target_queue(acceptedSocketDelegateQueue, self.acceptedSocketDelegateTargetQueue);
    newSocket.delegateQueue = acceptedSocketDelegateQueue;

    CRConnection* connection = [self newConnectionWithSocket:newSocket];
    connection.delegate = self;

    CRServer * __weak server = self;
    dispatch_async(self.isolationQueue, ^(){
        [server.connections addObject:connection];
    });
    if ( [self.delegate respondsToSelector:@selector(server:didAcceptConnection:)]) {
        dispatch_async(self.delegateQueue, ^{
            [server.delegate server:server didAcceptConnection:connection];
        });
    }
    [connection startReading];
}

#pragma mark - CRConnectionDelegate

- (void)connection:(CRConnection *)connection didReceiveRequest:(CRRequest *)request response:(CRResponse *)response {
    CRServer * __weak server = self;
    [self.workerQueue addOperationWithBlock:^{ @autoreleasepool {
        NSArray<CRRouteMatchingResult *> * routes = [server routesForPath:request.URL.path method:request.method];
        [server executeRoutes:routes forRequest:request response:response withCompletion:^{} notFoundBlock:server.notFoundBlock];
    }}];
    if ( [self.delegate respondsToSelector:@selector(server:didReceiveRequest:)] ) {
        dispatch_async(self.delegateQueue, ^{ @autoreleasepool {
            [self.delegate server:server didReceiveRequest:request];
        }});
    }
}

- (void)connection:(CRConnection *)connection didFinishRequest:(CRRequest *)request response:(CRResponse *)response {
    if ( [self.delegate respondsToSelector:@selector(server:didFinishRequest:)]  ) {
        CRServer * __weak server = self;
        dispatch_async(self.delegateQueue, ^{
            [server.delegate server:server didFinishRequest:request];
        });
    }
}

- (void)didCloseConnection:(CRConnection*)connection {
    CRServer * __weak server = self;
    if ( [self.delegate respondsToSelector:@selector(server:didCloseConnection:)]) {
        dispatch_async(self.delegateQueue, ^{
            [server.delegate server:server didCloseConnection:connection];
        });
    }
    dispatch_async(self.isolationQueue, ^(){
        [server.connections removeObject:connection];
    });
}

#pragma mark - Queues

- (NSString *)queueLabelForName:(NSString *)name bundleIdentifier:(NSString *)bundleIndentifier {
    if (name.length == 0) {
        return nil;
    }
    
    if (bundleIndentifier.length == 0) {
        return name;
    }
    
    return [bundleIndentifier stringByAppendingPathExtension:name];
}

- (void)getDispatchQueueLabel:(const char **)dispatchLabel forQueueLabel:(NSString *)label {
    if (label.length == 0) {
        *dispatchLabel = NULL;
        return;
    }
    
    NSStringEncoding encoding = NSASCIIStringEncoding;
    if ([label canBeConvertedToEncoding:encoding]) {
        *dispatchLabel = [label cStringUsingEncoding:encoding];
        return;
    }
       
    NSData *labelData = [label dataUsingEncoding:encoding allowLossyConversion:YES];
    unsigned long size = labelData.length;
    char buf[size + 1]; // NULL terminated string
    [labelData getBytes:(void *)&buf length:labelData.length];
    buf[size] = '\0';
    *dispatchLabel = buf;
}

- (dispatch_queue_t)createQueueWithName:(NSString *)name concurrent:(BOOL)concurrent qos:(qos_class_t)qos {
    const char *label;
    [self getDispatchQueueLabel:&label forQueueLabel:[self queueLabelForName:name bundleIdentifier:NSBundle.mainBundle.bundleIdentifier]];

    dispatch_queue_attr_t attr = concurrent ? DISPATCH_QUEUE_CONCURRENT : DISPATCH_QUEUE_SERIAL;
    dispatch_queue_t queue = dispatch_queue_create(label, attr);
    
    if (qos != QOS_CLASS_UNSPECIFIED) {
        dispatch_set_target_queue(queue, dispatch_get_global_queue(qos, 0));
    }
    
    return queue;
}

- (NSOperationQueue *)createDefaultWorkerQueue {
    NSOperationQueue *workerQueue = [[NSOperationQueue alloc] init];
    if ( [workerQueue respondsToSelector:@selector(qualityOfService)] ) {
        workerQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    }
    workerQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    workerQueue.name = [NSBundle.mainBundle.bundleIdentifier stringByAppendingPathExtension:CRServerDefaultWorkerQueueName];
    return workerQueue;
}

- (void)setWorkerQueue:(NSOperationQueue *)workerQueue {
    if (self.isListening) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot set the worker queue after the server has started listening." userInfo:nil];
    }
    
    [self willChangeValueForKey:WorkerQueueKey];
    _workerQueue = workerQueue;
    [self didChangeValueForKey:WorkerQueueKey];
}

@end
