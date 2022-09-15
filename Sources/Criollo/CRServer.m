//
//  CRServer.m
//
//
//  Created by Catalin Stan on 7/24/15.
//

#import <Criollo/CRServer.h>

#import <Criollo/CRConnection.h>
#import <Criollo/CRRequest.h>
#import <Criollo/CRResponse.h>
#import <Criollo/CRViewController.h>

#import "CocoaAsyncSocket.h"
#import "CRConnection_Internal.h"
#import "CRMessage_Internal.h"
#import "CRRoute.h"
#import "CRRouter_Internal.h"
#import "CRServer_Internal.h"
#import "CRServerConfiguration.h"

NSErrorDomain const CRServerErrorDomain = @"CRServerErrorDomain";

static NSUInteger const InitialConnectionCapacity = 1 << 10;

static NSString *const CRServerDefaultWorkerQueueName = @"CRServerDefaultWorkerQueue";
static NSString *const CRServerDefaultDelegateQueueName = @"CRServerDefaultDelegateQueue";
static NSString *const CRServerIsolationQueueName = @"CRServerIsolationQueue";
static NSString *const CRServerSocketDelegateQueueName = @"CRServerSocketDelegateQueue";
static NSString *const CRServerAcceptedSocketDelegateTargetQueueName = @"CRServerAcceptedSocketDelegateTargetQueue";

static NSString *const IsListeningKey = @"isListening";
static NSString *const WorkerQueueKey = @"workerQueue";

NS_ASSUME_NONNULL_BEGIN

@interface CRServer ()

@property (nonatomic, strong, nullable) GCDAsyncSocket *socket;
- (CRConnection *)acceptConnectionWithSocket:(GCDAsyncSocket *)socket delegate:(id<CRConnectionDelegate> _Nullable)delegate;

- (NSOperationQueue *)createDefaultWorkerQueue NS_WARN_UNUSED_RESULT;
- (dispatch_queue_t)createDefaultDelegateQueue NS_WARN_UNUSED_RESULT;

- (dispatch_queue_t)createIsolationQueue NS_WARN_UNUSED_RESULT;
- (dispatch_queue_t)createSocketDelegateQueue NS_WARN_UNUSED_RESULT;
- (dispatch_queue_t)createAcceptedSocketDelegateTargetQueue NS_WARN_UNUSED_RESULT;

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
        if (_delegateQueue == nil) {
            _delegateQueue = [self createDefaultDelegateQueue];
            _delegateQueueIsDefaultQueue = YES;
        }
    }
    return self;
}

- (void)dealloc {
    if (_delegateQueueIsDefaultQueue) {
        _delegateQueue = nil;
    }
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
    if (portNumber != 0 ) {
        self.configuration.CRServerPort = portNumber;
    }

    if (interface.length != 0 ) {
        self.configuration.CRServerInterface = interface;
    }

    if (self.workerQueue == nil) {
        _workerQueue = [self createDefaultWorkerQueue];
        _workerQueueIsDefaultQueue = YES;
    }
    
    self.isolationQueue = [self createIsolationQueue];
    self.socketDelegateQueue = [self createSocketDelegateQueue];
    self.acceptedSocketDelegateTargetQueue = [self createSocketDelegateQueue];

    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.socketDelegateQueue];
    self.connections = [NSMutableArray arrayWithCapacity:InitialConnectionCapacity];

    if ([self.delegate respondsToSelector:@selector(serverWillStartListening:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate serverWillStartListening:self];
        });
    }
    
    [self willChangeValueForKey:IsListeningKey];
    if(!(_isListening = [self.socket acceptOnInterface:self.configuration.CRServerInterface port:self.configuration.CRServerPort error:error])) {
        [self stopListening];
        return NO;
    }
    [self didChangeValueForKey:IsListeningKey];
    
    if (self.isListening && [self.delegate respondsToSelector:@selector(serverDidStartListening:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate serverDidStartListening:self];
        });
    }
    
    return YES;
}

- (void)stopListening {
    if ([self.delegate respondsToSelector:@selector(serverWillStopListening:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate serverWillStopListening:self];
        });
    }

    [self willChangeValueForKey:IsListeningKey];
    
    [self.workerQueue cancelAllOperations];
    
    self.socket.delegate = nil;
    [self.socket disconnect];
    self.socket = nil;

    _isListening = NO;
    
    if(self.workerQueueIsDefaultQueue) {
        self.workerQueue = nil;
        _workerQueueIsDefaultQueue = NO;
    }
    self.isolationQueue = nil;
    self.socketDelegateQueue = nil;
    self.acceptedSocketDelegateTargetQueue = nil;
    
    [self didChangeValueForKey:IsListeningKey];
    
    if ([self.delegate respondsToSelector:@selector(serverDidStopListening:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate serverDidStopListening:self];
        });
    }
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

- (CRConnection*)acceptConnectionWithSocket:(GCDAsyncSocket*)socket delegate:(id<CRConnectionDelegate> _Nullable)delegate CR_OBJC_ABSTRACT;

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    dispatch_queue_t acceptedSocketDelegateQueue = dispatch_queue_create([[NSBundle.mainBundle.bundleIdentifier stringByAppendingPathExtension:[NSString stringWithFormat:@"SocketDelegateQueue-%hu", newSocket.connectedPort]] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
    dispatch_set_target_queue(acceptedSocketDelegateQueue, self.acceptedSocketDelegateTargetQueue);
    newSocket.delegateQueue = acceptedSocketDelegateQueue;

    CRConnection* connection = [self acceptConnectionWithSocket:newSocket delegate:self];
    CRServer * __weak server = self;
    dispatch_async(self.isolationQueue, ^(){
        [server.connections addObject:connection];
    });
    if ([self.delegate respondsToSelector:@selector(server:didAcceptConnection:)]) {
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
        [server executeRoutes:routes request:request response:response withCompletion:^{} notFoundBlock:server.notFoundBlock];
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

- (dispatch_queue_t)createQueueWithName:(NSString *)name concurrent:(BOOL)concurrent qos:(qos_class_t)qos {
    NSString *label = [self queueLabelForName:name bundleIdentifier:NSBundle.mainBundle.bundleIdentifier];

    dispatch_queue_attr_t attr = concurrent ? DISPATCH_QUEUE_CONCURRENT : DISPATCH_QUEUE_SERIAL;
    dispatch_queue_t queue = dispatch_queue_create(label.UTF8String, attr);
    
    if (qos != QOS_CLASS_UNSPECIFIED) {
        dispatch_set_target_queue(queue, dispatch_get_global_queue(qos, 0));
    }
    
    return queue;
}

- (dispatch_queue_t)createDefaultDelegateQueue {
    return [self createQueueWithName:CRServerDefaultDelegateQueueName concurrent:NO qos:QOS_CLASS_BACKGROUND];
}

- (dispatch_queue_t)createIsolationQueue {
    return [self createQueueWithName:CRServerIsolationQueueName concurrent:NO qos:QOS_CLASS_DEFAULT];
}

- (dispatch_queue_t)createSocketDelegateQueue {
    return [self createQueueWithName:CRServerSocketDelegateQueueName concurrent:YES qos:QOS_CLASS_USER_INTERACTIVE];
}

- (dispatch_queue_t)createAcceptedSocketDelegateTargetQueue {
    return [self createQueueWithName:CRServerAcceptedSocketDelegateTargetQueueName concurrent:NO qos:QOS_CLASS_USER_INITIATED];
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
