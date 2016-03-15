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
#import "CRMessage_Internal.h"
#import "CRRequest.h"
#import "CRResponse.h"
#import "CRRoute.h"
#import "CRViewController.h"

NS_ASSUME_NONNULL_BEGIN
@interface CRServer () <GCDAsyncSocketDelegate, CRConnectionDelegate>

@property (nonatomic, strong) GCDAsyncSocket* socket;
@property (nonatomic, strong) dispatch_queue_t isolationQueue;
@property (nonatomic, strong) dispatch_queue_t socketDelegateQueue;
@property (nonatomic, strong) dispatch_queue_t acceptedSocketDelegateTargetQueue;
@property (nonatomic, strong) dispatch_queue_t acceptedSocketSocketTargetQueue;

@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*, NSMutableArray<CRRoute *> *> * routes;
@property (nonatomic, strong, readonly) NSMutableArray<NSString *> * recursiveMatchRoutePathPrefixes;

@property (nonatomic, strong) NSOperationQueue* workerQueue;

- (NSArray<CRRoute *> *)routesForPath:(NSString *)path HTTPMethod:(CRHTTPMethod)method;

- (CRConnection *)newConnectionWithSocket:(GCDAsyncSocket *)socket;

- (void)addRoute:(CRRoute *)route forPath:(NSString *)path HTTPMethod:(CRHTTPMethod)method recursive:(BOOL)recursive;

@end
NS_ASSUME_NONNULL_END

@implementation CRServer

+ (CRRouteBlock)errorHandlingBlockWithStatus:(NSUInteger)statusCode error:(NSError *)error {
    return ^(CRRequest *request, CRResponse *response, CRRouteCompletionBlock completionHandler) {
        [response setStatusCode:statusCode description:nil];
        [response setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-type"];

        NSMutableString* responseString = [NSMutableString string];

#if DEBUG
        NSError* err;
        if (error == nil) {
            NSMutableDictionary* mutableUserInfo = [NSMutableDictionary dictionaryWithCapacity:2];
            NSString* errorDescription;
            switch (statusCode) {
                case 404:
                    errorDescription = [NSString stringWithFormat:NSLocalizedString(@"No routes defined for “%@%@%@”",), NSStringFromCRHTTPMethod(request.method), request.URL.path, [request.URL.path hasSuffix:CRPathSeparator] ? @"" : CRPathSeparator];
                    break;
            }
            if ( errorDescription ) {
                mutableUserInfo[NSLocalizedDescriptionKey] = errorDescription;
            }
            mutableUserInfo[NSURLErrorFailingURLErrorKey] = request.URL;
            err = [NSError errorWithDomain:CRServerErrorDomain code:statusCode userInfo:mutableUserInfo];
        } else {
            err = error;
        }

        // Error details
        [responseString appendFormat:@"%@ %lu\n%@\n", err.domain, (long)err.code, err.localizedDescription];

        // Error user-info
        if ( err.userInfo.count > 0 ) {
            [responseString appendString:@"\nUser Info\n"];
            [err.userInfo enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                [responseString appendFormat:@"%@: %@\n", key, obj];
            }];
        }

        // Stack trace
        [responseString appendString:@"\nStack Trace\n"];
        [[NSThread callStackSymbols] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [responseString appendFormat:@"%@\n", obj];
        }];
#else
        [responseString appendFormat:@"Cannot %@ %@", NSStringFromCRHTTPMethod(request.method), request.URL.path];
#endif

        [response setValue:@(responseString.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [response sendString:responseString];

        completionHandler();
    };
}

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
        _routes = [NSMutableDictionary dictionary];
        _recursiveMatchRoutePathPrefixes = [NSMutableArray array];

        _delegate = delegate;
        _delegateQueue = delegateQueue;
        if ( _delegateQueue == nil ) {
            _delegateQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"ServerDelegateQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
            dispatch_set_target_queue(_delegateQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
        }

        _notFoundBlock = [CRServer errorHandlingBlockWithStatus:404 error:nil];
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

    self.isolationQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"ServerIsolationQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(self.isolationQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));

    self.socketDelegateQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"SocketDelegateQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
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
        dispatch_async(self.delegateQueue, ^{
            [self.delegate serverWillStartListening:self];
        });
    }

    BOOL listening = [self.socket acceptOnInterface:self.configuration.CRServerInterface port:self.configuration.CRServerPort error:error];
    if ( listening && [self.delegate respondsToSelector:@selector(serverDidStartListening:)] ) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate serverDidStartListening:self];
        });
    }

    return listening;
}

- (void)stopListening {

    if ( [self.delegate respondsToSelector:@selector(serverWillStopListening:)] ) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate serverWillStopListening:self];
        });
    }

    [self.workerQueue cancelAllOperations];
    [self.socket disconnect];

    if ( [self.delegate respondsToSelector:@selector(serverDidStopListening:)] ) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate serverDidStopListening:self];
        });
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
        dispatch_async(self.delegateQueue, ^{
            [self.delegate server:self didAcceptConnection:connection];
        });
    }
    [connection startReading];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
}

#pragma mark - CRConnectionDelegate

- (void)connection:(CRConnection *)connection didReceiveRequest:(CRRequest *)request response:(CRResponse *)response {
    [self.workerQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
        if ( [self.delegate respondsToSelector:@selector(server:didReceiveRequest:)] ) {
            dispatch_async(self.delegateQueue, ^{
                [self.delegate server:self didReceiveRequest:request];
            });
        }
        NSArray<CRRoute*>* routes = [self routesForPath:request.URL.path HTTPMethod:request.method];
        if ( routes.count == 0 ) {
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
        dispatch_async(self.delegateQueue, ^{
            [self.delegate server:self didFinishRequest:request];
        });
    }
}

- (void)didCloseConnection:(CRConnection*)connection {
    if ( [self.delegate respondsToSelector:@selector(server:didCloseConnection:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate server:self didCloseConnection:connection];
        });
    }
    dispatch_async(self.isolationQueue, ^(){
        [self.connections removeObject:connection];
    });
}

#pragma mark - Routing

- (void)addBlock:(CRRouteBlock)block {
    [self addBlock:block forPath:nil HTTPMethod:CRHTTPMethodAll recursive:NO];
}

- (void)addBlock:(CRRouteBlock)block forPath:(NSString*)path {
    [self addBlock:block forPath:path HTTPMethod:CRHTTPMethodAll recursive:NO];
}

- (void)addBlock:(CRRouteBlock)block forPath:(NSString *)path HTTPMethod:(CRHTTPMethod)method {
    [self addBlock:block forPath:path HTTPMethod:method recursive:NO];
}

- (void)addBlock:(CRRouteBlock)block forPath:(NSString *)path HTTPMethod:(CRHTTPMethod)method recursive:(BOOL)recursive {
    CRRoute* route = [CRRoute routeWithBlock:block];
    [self addRoute:route forPath:path HTTPMethod:method recursive:recursive];
}

- (void)addController:(__unsafe_unretained Class)controllerClass withNibName:(NSString *)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil forPath:(NSString *)path {
    [self addController:controllerClass withNibName:nibNameOrNil bundle:nibBundleOrNil forPath:path HTTPMethod:CRHTTPMethodAll recursive:NO];
}

- (void)addController:(__unsafe_unretained Class)controllerClass withNibName:(NSString *)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil forPath:(NSString *)path HTTPMethod:(CRHTTPMethod)method {
    [self addController:controllerClass withNibName:nibNameOrNil bundle:nibBundleOrNil forPath:path HTTPMethod:method recursive:NO];
}

- (void)addController:(__unsafe_unretained Class)controllerClass withNibName:(NSString *)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil forPath:(NSString *)path HTTPMethod:(CRHTTPMethod)method recursive:(BOOL)recursive {
    CRRoute* route = [CRRoute routeWithControllerClass:controllerClass nibName:nibNameOrNil bundle:nibBundleOrNil];
    [self addRoute:route forPath:path HTTPMethod:method recursive:recursive];
}

- (void)mountStaticDirectoryAtPath:(NSString *)directoryPath forPath:(NSString *)path {
    [self mountStaticDirectoryAtPath:directoryPath forPath:path options:0];
}

- (void)mountStaticDirectoryAtPath:(NSString *)directoryPath forPath:(NSString *)path options:(CRStaticDirectoryServingOptions)options {
    CRRoute* route = [CRRoute routeWithStaticDirectoryAtPath:directoryPath prefix:path options:options];
    [self addRoute:route forPath:path HTTPMethod:CRHTTPMethodGet recursive:YES];
}

- (void)mountStaticFileAtPath:(NSString *)filePath forPath:(NSString *)path {
    [self mountStaticFileAtPath:filePath forPath:path options:0 fileName:nil contentType:nil contentDisposition:CRStaticFileContentDispositionNone];
}

- (void)mountStaticFileAtPath:(NSString *)filePath forPath:(NSString *)path options:(CRStaticFileServingOptions)options {
    [self mountStaticFileAtPath:filePath forPath:path options:options fileName:nil contentType:nil contentDisposition:CRStaticFileContentDispositionNone];
}

- (void)mountStaticFileAtPath:(NSString *)filePath forPath:(NSString *)path options:(CRStaticFileServingOptions)options fileName:(NSString *)fileName {
    [self mountStaticFileAtPath:filePath forPath:path options:options fileName:fileName contentType:nil contentDisposition:CRStaticFileContentDispositionNone];
}

- (void)mountStaticFileAtPath:(NSString *)filePath forPath:(NSString *)path options:(CRStaticFileServingOptions)options fileName:(NSString *)fileName contentType:(NSString *)contentType {
    [self mountStaticFileAtPath:filePath forPath:path options:options fileName:fileName contentType:contentType contentDisposition:CRStaticFileContentDispositionNone];
}

- (void)mountStaticFileAtPath:(NSString *)filePath forPath:(NSString *)path options:(CRStaticFileServingOptions)options fileName:(NSString *)fileName contentType:(NSString *)contentType contentDisposition:(CRStaticFileContentDisposition)contentDisposition {
    CRRoute* route = [CRRoute routeWithStaticFileAtPath:filePath options:options fileName:fileName contentType:contentType contentDisposition:contentDisposition];
    [self addRoute:route forPath:path HTTPMethod:CRHTTPMethodGet recursive:NO];
}

- (void)addRoute:(CRRoute*)route forPath:(NSString *)path HTTPMethod:(CRHTTPMethod)method recursive:(BOOL)recursive {
    NSArray<NSString*>* methods;

    if ( method == CRHTTPMethodAll ) {
        methods = [CRMessage acceptedHTTPMethods];
    } else {
        methods = @[NSStringFromCRHTTPMethod(method), NSStringFromCRHTTPMethod(CRHTTPMethodHead)];
    }

    if ( path == nil ) {
        path = CRPathAnyPath;
        recursive = NO;
    }

    if ( ![path isEqualToString:CRPathAnyPath] && ![path hasSuffix:CRPathSeparator] ) {
        path = [path stringByAppendingString:CRPathSeparator];
    }

    [methods enumerateObjectsUsingBlock:^(NSString * _Nonnull method, NSUInteger idx, BOOL * _Nonnull stop) {

        NSString* routePath = [method stringByAppendingString:path];

        if ( ![self.routes[routePath] isKindOfClass:[NSMutableArray class]] ) {
            NSMutableArray<CRRoute*>* parentRoutes = [NSMutableArray array];

            // Add the "*" routes
            NSString* anyPathRoutePath = [method stringByAppendingString:CRPathAnyPath];
            if ( self.routes[anyPathRoutePath] != nil ) {
                [parentRoutes addObjectsFromArray:self.routes[anyPathRoutePath]];
            }

            self.routes[routePath] = parentRoutes;
        }

        [self.routes[routePath] addObject:route];

        // If the route should be executed on all paths, add it accordingly
        if ( [path isEqualToString:CRPathAnyPath] ) {
            [self.routes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<CRRoute *> * _Nonnull obj, BOOL * _Nonnull stop) {
                if ( ![obj.lastObject isEqual:route] ) {
                    [obj addObject:route];
                }
            }];
        }

        // If the route is recursive add it to the array
        if ( recursive ) {
            [self.recursiveMatchRoutePathPrefixes addObject:routePath];
        }
    }];
}

- (NSArray<CRRoute*>*)routesForPath:(NSString*)path HTTPMethod:(CRHTTPMethod)method {
    if ( path == nil ) {
        path = @"";
    }

    if ( ![path hasSuffix:CRPathSeparator] ) {
        path = [path stringByAppendingString:CRPathSeparator];
    }
    path = [NSStringFromCRHTTPMethod(method) stringByAppendingString:path];

    __block BOOL shouldRecursivelyMatchRoutePathPrefix = NO;
    [self.recursiveMatchRoutePathPrefixes enumerateObjectsUsingBlock:^(NSString * _Nonnull recursiveMatchRoutePathPrefix, NSUInteger idx, BOOL * _Nonnull stop) {
        if ( [path hasPrefix:recursiveMatchRoutePathPrefix] ) {
            shouldRecursivelyMatchRoutePathPrefix = YES;
            *stop = YES;
        }
    }];

    NSArray<CRRoute*>* routes;
    while ( routes.count == 0 ) {
        routes = self.routes[path];
        if ( !shouldRecursivelyMatchRoutePathPrefix) {
            break;
        }
        path = [[path stringByDeletingLastPathComponent] stringByAppendingString:CRPathSeparator];
    }

    return routes;
}

@end
