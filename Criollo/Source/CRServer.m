//
//  CRServer.m
//  Criollo
//
//  Created by Catalin Stan on 7/24/15.
//  Copyright (c) 2015 Cătălin Stan. All rights reserved.
//

#import "CRServer.h"
#import "CRServer_Internal.h"
#import "CRServerConfiguration.h"
#import "GCDAsyncSocket.h"
#import "CRConnection.h"
#import "CRConnection_Internal.h"
#import "CRRequest.h"
#import "CRResponse.h"
#import "CRRoute.h"
#import "CRViewController.h"

NSUInteger const CRErrorSocketError = 2001;

@interface CRServer () <GCDAsyncSocketDelegate, CRConnectionDelegate>

@property (nonatomic, strong, nonnull) GCDAsyncSocket* socket;
@property (nonatomic, strong, nonnull) dispatch_queue_t isolationQueue;
@property (nonatomic, strong, nonnull) dispatch_queue_t socketDelegateQueue;
@property (nonatomic, strong, nonnull) dispatch_queue_t acceptedSocketDelegateTargetQueue;
@property (nonatomic, strong, nonnull) dispatch_queue_t acceptedSocketSocketTargetQueue;

@property (nonatomic, strong, nonnull) NSMutableDictionary<NSString*, NSMutableArray<CRRoute*>*>* routes;

@property (nonatomic, strong, nonnull) NSOperationQueue* workerQueue;

- (nonnull NSArray<CRRoute*>*)routesForPath:(nonnull NSString*)path;
- (nonnull NSArray<CRRoute*>*)routesForPath:(nonnull NSString*)path HTTPMethod:(nullable NSString*)HTTPMethod;

- (nonnull CRConnection*)newConnectionWithSocket:(nonnull GCDAsyncSocket*)socket;

@end

@implementation CRServer

+ (CRRouteBlock)errorHandlingBlockWithStatus:(NSUInteger)statusCode {
    return ^(CRRequest *request, CRResponse *response, CRRouteCompletionBlock completionHandler) {
        [response setStatusCode:statusCode description:nil];
        [response setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        [response sendFormat:@"Cennot %@ %@", request.method, request.URL.path];
    };
}

- (instancetype)init {
    return [self initWithDelegate:nil];
}

- (instancetype)initWithDelegate:(id<CRServerDelegate>)delegate {
    self = [super init];
    if ( self != nil ) {
        self.configuration = [[CRServerConfiguration alloc] init];
        self.delegate = delegate;
        self.routes = [NSMutableDictionary dictionary];
        self.notFoundBlock = [CRServer errorHandlingBlockWithStatus:404];
    }
    return self;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    NSLog(@"%@.%@ = %lu", object, keyPath, (unsigned long)((NSArray*)change[NSKeyValueChangeNewKey]).count);
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

    self.isolationQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"IsolationQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(self.isolationQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));

    self.socketDelegateQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"DelegateQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
    dispatch_set_target_queue(self.socketDelegateQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));

    self.acceptedSocketSocketTargetQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"AcceptedSocketSocketTargetQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(self.acceptedSocketSocketTargetQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));

    self.acceptedSocketDelegateTargetQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"AcceptedSocketDelegateTargetQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(self.acceptedSocketDelegateTargetQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));

    self.workerQueue = [[NSOperationQueue alloc] init];
    if ( [self.workerQueue respondsToSelector:@selector(qualityOfService)] ) {
        self.workerQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    }
    self.workerQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;

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

    [self.workerQueue cancelAllOperations];
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

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    [newSocket markSocketQueueTargetQueue:self.acceptedSocketSocketTargetQueue];

    dispatch_queue_t acceptedSocketDelegateQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:[NSString stringWithFormat:@"SocketDelegateQueue-%hu", newSocket.connectedPort]] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
    dispatch_set_target_queue(acceptedSocketDelegateQueue, self.acceptedSocketDelegateTargetQueue);
    newSocket.delegateQueue = acceptedSocketDelegateQueue;

    CRConnection* connection = [self newConnectionWithSocket:newSocket];
    connection.delegate = self;
    dispatch_async(self.isolationQueue, ^(){
        [self.connections addObject:connection];
    });
    if ( [self.delegate respondsToSelector:@selector(server:didAcceptConnection:)]) {
        [self.delegate server:self didAcceptConnection:connection];
    }
    [connection startReading];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
}

#pragma mark - CRConnectionDelegate

- (void)connection:(CRConnection *)connection didReceiveRequest:(CRRequest *)request response:(CRResponse *)response {
    [self.workerQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
        if ( [self.delegate respondsToSelector:@selector(server:didReceiveRequest:)] ) {
            [self.delegate server:self didReceiveRequest:request];
        }
        NSArray<CRRoute*>* routes = [self routesForPath:request.URL.path HTTPMethod:request.method];
        if ( routes == nil ) {
            routes = @[[CRRoute routeWithBlock:self.notFoundBlock]];
        }
        __block BOOL shouldStopExecutingBlocks = NO;
        __block NSUInteger currentRouteIndex = 0;
        void(^completionHandler)(void) = ^{
            shouldStopExecutingBlocks = NO;
            currentRouteIndex++;
        };
        while (!shouldStopExecutingBlocks && currentRouteIndex < routes.count ) {
            shouldStopExecutingBlocks = YES;
            CRRouteBlock block = routes[currentRouteIndex].block;
            block(request, response, completionHandler);
        }
    }]];

}

- (void)connection:(CRConnection *)connection didFinishRequest:(CRRequest *)request response:(CRResponse *)response {
    if ( [self.delegate respondsToSelector:@selector(server:didFinishRequest:)]  ) {
        [self.delegate server:self didFinishRequest:request];
    }
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

- (BOOL)canHandleHTTPMethod:(NSString *)HTTPMethod forPath:(NSString *)path {
    return YES;
}

- (void)addBlock:(CRRouteBlock)block {
    [self addBlock:block forPath:nil HTTPMethod:nil];
}

- (void)addBlock:(CRRouteBlock)block forPath:(NSString*)path {
    [self addBlock:block forPath:path HTTPMethod:nil];
}

- (void)addBlock:(CRRouteBlock)block forPath:(NSString *)path HTTPMethod:(NSString *)HTTPMethod {
    CRRoute* route = [CRRoute routeWithBlock:block];
    [self addRoute:route forPath:path HTTPMethod:HTTPMethod];
}

- (void)addController:(__unsafe_unretained Class)controllerClass withNibName:(NSString *)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil forPath:(NSString *)path {
    [self addController:controllerClass withNibName:nibNameOrNil bundle:nibBundleOrNil forPath:path HTTPMethod:nil];
}

- (void)addController:(__unsafe_unretained Class)controllerClass withNibName:(NSString *)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil forPath:(NSString *)path HTTPMethod:(NSString *)HTTPMethod {
    CRRoute* route = [CRRoute routeWithControllerClass:controllerClass nibName:nibNameOrNil bundle:nibBundleOrNil];
    [self addRoute:route forPath:path HTTPMethod:HTTPMethod];
}

- (void)addStaticDirectoryAtPath:(NSString *)directoryPath forPath:(NSString *)path {
    [self addStaticDirectoryAtPath:directoryPath forPath:path options:0];
}

- (void)addStaticDirectoryAtPath:(NSString *)directoryPath forPath:(NSString *)path options:(CRStaticDirectoryServingOptions)options {
    CRRoute* route = [CRRoute routeWithStaticDirectoryAtPath:directoryPath prefix:path options:options];
    [self addRoute:route forPath:path HTTPMethod:CRHTTPMethodGET];
}

- (void)addRoute:(CRRoute*)route forPath:(NSString *)path HTTPMethod:(NSString *)HTTPMethod {
    NSArray<NSString*>* methods;

    if ( HTTPMethod == nil ) {
        methods = CRHTTPAllMethods;
    } else {
        methods = @[HTTPMethod];
    }

    if ( path == nil ) {
        path = CRPathAnyPath;
    }

    if ( ![path isEqualToString:CRPathAnyPath] && ![path hasSuffix:CRPathSeparator] ) {
        path = [path stringByAppendingString:CRPathSeparator];
    }

    // Add the
    [methods enumerateObjectsUsingBlock:^(NSString * _Nonnull method, NSUInteger idx, BOOL * _Nonnull stop) {

        NSString* routePath = [method stringByAppendingString:path];

        if ( ![self.routes[routePath] isKindOfClass:[NSMutableArray class]] ) {
            NSMutableArray<CRRoute*>* parentRoutes = [NSMutableArray array];

            // Add the "*" routes
            NSString* anyPathRoutePath = [method stringByAppendingString:CRPathAnyPath];
            if ( self.routes[anyPathRoutePath] != nil ) {
                [parentRoutes addObjectsFromArray:self.routes[anyPathRoutePath]];
            }

            // Add all parent routes
            __block NSString* parentRoutePath = [method stringByAppendingString:CRPathSeparator];
            [routePath.pathComponents enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ( [parentRoutePath isEqualToString:[method stringByAppendingString:CRPathSeparator]] ) {
                    return;
                }

                if ( self.routes[parentRoutePath] != nil ) {
                    [parentRoutes addObjectsFromArray:self.routes[parentRoutePath]];
                }
                parentRoutePath = [parentRoutePath stringByAppendingFormat:@"%@/", obj];
            }];

            self.routes[routePath] = parentRoutes;
        }

        // Add the route to all other descendant routes
        NSArray<NSString*>* descendantRoutesKeys = [self.routes.allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString*  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [evaluatedObject hasPrefix:routePath];
        }]];

        [descendantRoutesKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.routes[obj] addObject:route];
        }];

        if ( [path isEqualToString:CRPathAnyPath] ) {
            [self.routes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<CRRoute *> * _Nonnull obj, BOOL * _Nonnull stop) {
                if ( ![obj.lastObject isEqual:route] ) {
                    [obj addObject:route];
                }
            }];
        }
        
    }];
}

- (NSArray<CRRoute*>*)routesForPath:(NSString*)path {
    return [self routesForPath:path HTTPMethod:nil];
}

- (NSArray<CRRoute*>*)routesForPath:(NSString*)path HTTPMethod:(NSString*)HTTPMethod {
    if ( path == nil ) {
        path = @"";
    }

    if ( ![path hasSuffix:CRPathSeparator] ) {
        path = [path stringByAppendingString:CRPathSeparator];
    }
    path = [HTTPMethod stringByAppendingString:path];

    NSArray<CRRoute*>* routes;
    while ( routes.count == 0 ) {
        routes = self.routes[path];
        path = [[path stringByDeletingLastPathComponent] stringByAppendingString:CRPathSeparator];
    }

    return routes;
}

@end
