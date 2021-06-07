//
//  CRServer_Internal.h
//  Criollo
//
//  Created by Cătălin Stan on 11/20/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import <Criollo/CRServer.h>

#import <Criollo/CRConnection.h>

#import "CocoaAsyncSocket.h"

NS_ASSUME_NONNULL_BEGIN

@interface CRServer () <GCDAsyncSocketDelegate, CRConnectionDelegate>

@property (nonatomic, strong) CRServerConfiguration * configuration;

//TODO: Consider using NSSet or NSHashTable instead
@property (nonatomic, strong) NSMutableArray<CRConnection *> * connections;

- (void)didCloseConnection:(CRConnection *)connection;

#pragma mark - Queues

@property (nonatomic, readonly) BOOL workerQueueIsDefaultQueue;
@property (nonatomic, readonly) BOOL delegateQueueIsDefaultQueue;

@property (nonatomic, strong, nullable) dispatch_queue_t isolationQueue;
@property (nonatomic, strong, nullable) dispatch_queue_t socketDelegateQueue;
@property (nonatomic, strong, nullable) dispatch_queue_t acceptedSocketDelegateTargetQueue;

- (NSString * _Nullable)queueLabelForName:(NSString * _Nullable)name bundleIdentifier:(NSString * _Nullable)bundleIndentifier;
- (void)getDispatchQueueLabel:(const char *_Nullable* _Nonnull)dispatchLabel forQueueLabel:(NSString * _Nullable)label;

- (dispatch_queue_t)createQueueWithName:(NSString * _Nullable)name concurrent:(BOOL)concurrent qos:(qos_class_t)qos;

@end

NS_ASSUME_NONNULL_END
