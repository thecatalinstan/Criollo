//
//  CRServer.m
//  Criollo
//
//  Created by Catalin Stan on 7/24/15.
//  Copyright (c) 2015 Cătălin Stan. All rights reserved.
//

#import "CRServer.h"

NSUInteger const CRErrorSocketError = 2001;
NSUInteger const CRErrorRequestMalformedRequest = 3001;
NSUInteger const CRErrorRequestUnsupportedMethod = 3002;

NSUInteger const CRDefaultPortNumber = 1338;

NSString* const CRRequestKey = @"CRRequest";
NSString* const CRResponseKey = @"CRResponse";

@implementation CRServer

//+ (NSData *)CRLFCRLFData
//{
//    return [NSData dataWithBytes:"\x0D\x0A\x0D\x0A" length:4];
//}


//- (instancetype)init {
//    self = [super init];
//    if ( self != nil ) {
//    }
//    return self;
//}
//
//- (instancetype)initWithDelegate:(id<CRServerDelegate>)delegate {
//
//}
//
//- (instancetype)initWithDelegate:(id<CRServerDelegate>)delegate portNumber:(NSUInteger)portNumber {
//
//}
//
//- (instancetype)initWithDelegate:(id<CRServerDelegate>)delegate portNumber:(NSUInteger)portNumber interface:(NSString *)interface {
//
//}


//static NSArray* validHTTPMethods;
//
//+ (void)initialize
//{
//    validHTTPMethods = @[@"GET",@"POST", @"PUT", @"DELETE"];
//}


//NSUserDefaults *args = [NSUserDefaults standardUserDefaults];
//
//NSString* interface = [args stringForKey:@"i"];
//if ( interface == nil ) {
//    interface = [args stringForKey:@"interface"];
//    if ( interface == nil ) {
//        interface = @"";
//    }
//}
//
//NSUInteger portNumber = [args integerForKey:@"p"];
//if ( portNumber == 0 ) {
//    portNumber = [args integerForKey:@"port"];
//    if ( portNumber == 0 ) {
//        portNumber = CRDefaultPortNumber;
//    }
//}
//portNumber = MIN(INT16_MAX, MAX(0, portNumber));

//#pragma mark - Routing
//- (BOOL)canHandleRequest:(CRHTTPRequest *)request
//{
//    //    NSLog(@"%s %@", __PRETTY_FUNCTION__, request.method);
//    BOOL canHandle = YES;
//    if ( request.method == nil || ![validHTTPMethods containsObject:request.method.uppercaseString] ) {
//        canHandle = NO;
//    }
//    return canHandle;
//}
//
//
//#pragma mark - Listening
//
//- (void)startListening
//{
//    self.workerQueue = [[NSOperationQueue alloc] init];
//    self.workerQueue.name = [[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"WorkerQueue"];
//    self.workerQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
//    self.workerQueue.qualityOfService = NSQualityOfServiceUserInitiated;
//
//    self.delegateQueue = dispatch_queue_create([[[NSBundle mainBundle].bundleIdentifier stringByAppendingPathExtension:@"DelegateQueue"] cStringUsingEncoding:NSASCIIStringEncoding], NULL);
//
//    self.httpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.delegateQueue];
//
//    NSError *error;
//    BOOL listening = NO;
//
//    listening = [self.httpSocket acceptOnInterface:(self.interface.length == 0 ? nil : self.interface) port:self.portNumber error:&error];
//    if ( !listening ) {
//        [self presentError:error];
//        [self terminate:self];
//    }
//}
//
//- (void)stopListening
//{
//    [self.httpSocket setDelegate:nil];
//    [self.httpSocket disconnect];
//    self.httpSocket = nil;
//
//    [self.workerQueue cancelAllOperations];
//
//    self.workerQueue = nil;
//    self.delegateQueue = nil;
//
//    [self.connections removeAllObjects];
//}
//
//#pragma mark - GCDAsyncSocketDelegate
//
//- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
//{
//    //    NSLog(@"%s", __PRETTY_FUNCTION__);
//    CRHTTPConnection* connection = [[CRHTTPConnection alloc] initWithSocket:newSocket];
//
//    @synchronized(self.connections) {
//        [self.connections addObject:connection];
//        //        NSLog(@"Connections: %lu", (unsigned long)self.connections.count);
//    }
//}
//
//- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
//{
//    //    NSLog(@"%s", __PRETTY_FUNCTION__);
//}
//
//- (void)didCloseConnection:(CRHTTPConnection*)connection
//{
//    //    NSLog(@"%s", __PRETTY_FUNCTION__);
//    @synchronized(self.connections) {
//        [self.connections removeObject:connection];
//        //        NSLog(@"Connections: %lu", (unsigned long)self.connections.count);
//    }
//}



@end
