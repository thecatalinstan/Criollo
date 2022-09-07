//
//  CRServer.m
//  CriolloTests macOS
//
//  Created by Cătălin Stan on 03/05/2020.
//  Copyright © 2020 Cătălin Stan. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "CRServer.h"
#import "CRServer_Internal.h"

#define CRServerCreate() CRServer *server = [CRServer new]

#define CRServerCreateWithDelegateQueue() dispatch_queue_t queue = dispatch_queue_create(NULL, NULL); CRServer *server = [[CRServer alloc] initWithDelegate:nil delegateQueue:queue]

#define CRServerDestroy() server = nil

#define CRServerStart() NSError *error; while(![server startListening:&error portNumber:(2000 + (NSUInteger)arc4random_uniform(3000))]) { NSLog(@" *** %@", error); error = nil;}

#define CRServerStop() [server stopListening]

@interface CRServerTests : XCTestCase

@end

@implementation CRServerTests

- (void)test_init_DefaultDelegateQueue_IsCreated {
    CRServerCreate();
    
    XCTAssertNotNil(server.delegateQueue);
    XCTAssertTrue(server.delegateQueueIsDefaultQueue);
}

- (void)test_init_CustomDelegateQueue_IsSet {
    CRServerCreateWithDelegateQueue();
    
    XCTAssertEqual(queue, server.delegateQueue);
    XCTAssertFalse(server.delegateQueueIsDefaultQueue);
}

- (void)test_dealloc_DefaultDelegateQueue_IsDestroyed {
    CRServerCreate();
    CRServerDestroy();
    
    XCTAssertNil(server.delegateQueue);
}

- (void)test_dealloc_CustomDelegateQueue_IsNotDestroyed {
    CRServerCreateWithDelegateQueue();
    CRServerDestroy();
    
    XCTAssertNotNil(queue);
}

- (void)test_startListening_IsListening_ReturnsTrue {
    CRServerCreate();
    CRServerStart();
    
    XCTAssertTrue(server.isListening);
}

- (void)test_startListening_DefaultWorkerQueue_IsCreated {
    CRServerCreate();
    CRServerStart();
    
    XCTAssertNotNil(server.workerQueue);
    XCTAssertTrue(server.workerQueueIsDefaultQueue);
    
    CRServerStop();
}

- (void)test_startListening_CustomWorkerQueue_IsSet {
    CRServerCreate();
    
    NSOperationQueue *queue = [NSOperationQueue new];
    server.workerQueue = queue;
    
    CRServerStart();
    
    XCTAssertEqual(queue, server.workerQueue);
    XCTAssertFalse(server.workerQueueIsDefaultQueue);
        
    CRServerStop();
}

- (void)test_startListening_IsolationQueue_IsCreated {
    CRServerCreate();
    CRServerStart();
    
    XCTAssertNotNil(server.isolationQueue);
    
    CRServerStop();
}

- (void)test_startListening_SocketDelegateQueue_IsCreated {
    CRServerCreate();
    CRServerStart();
    
    XCTAssertNotNil(server.socketDelegateQueue);
    
    CRServerStop();
}

- (void)test_startListening_AcceptedSocketDelegateTargetQueue_IsCreated {
    CRServerCreate();
    CRServerStart();
    
    XCTAssertNotNil(server.acceptedSocketDelegateTargetQueue);
    
    CRServerStop();
}

- (void)test_stopListening_IsListening_ReturnsFalse {
    CRServerCreate();
    CRServerStart();
    CRServerStop();
    
    XCTAssertFalse(server.isListening);
}

- (void)test_stopListening_DefaultWorkerQueue_IsDestroyed {
    CRServerCreate();
    CRServerStart();
    CRServerStop();
    
    XCTAssertNil(server.workerQueue);
    XCTAssertFalse(server.workerQueueIsDefaultQueue);
}

- (void)test_stopListening_CustomWorkerQueue_IsNotDestroyed {
    CRServerCreate();
    
    NSOperationQueue *queue = [NSOperationQueue new];
    server.workerQueue = queue;
    
    CRServerStart();
    CRServerStop();
    
    XCTAssertNotNil(server.workerQueue);
    XCTAssertEqual(queue, server.workerQueue);
    XCTAssertFalse(server.workerQueueIsDefaultQueue);
}

- (void)test_stopListening_IsolationQueue_IsDestroyed {
    CRServerCreate();
    CRServerStart();
    CRServerStop();
    
    XCTAssertNil(server.isolationQueue);
}

- (void)test_stopListening_SocketDelegateQueue_IsDestroyed {
    CRServerCreate();
    CRServerStart();
    CRServerStop();
    
    XCTAssertNil(server.socketDelegateQueue);
}

- (void)test_stopListening_AcceptedSocketDelegateTargetQueue_IsDestroyed {
    CRServerCreate();
    CRServerStart();
    CRServerStop();
    
    XCTAssertNil(server.acceptedSocketDelegateTargetQueue);
}

- (void)test_setWorkerQueue_SetAfterStartListening_Throws {
    CRServerCreate();
    CRServerStart();
    
    NSOperationQueue *queue = [NSOperationQueue new];
    XCTAssertThrows(server.workerQueue = queue);
        
    CRServerStop();
}

- (void)test_queueLabelForName_NilNameNilBundle_ReturnsNil {
    CRServerCreate();
    
    XCTAssertNil([server queueLabelForName:nil bundleIdentifier:nil]);
}

- (void)test_queueLabelForName_NonnullNameNilBundle_ReturnsName {
    CRServerCreate();
    
    NSString *name = NSUUID.UUID.UUIDString;
    NSString *label = [server queueLabelForName:name bundleIdentifier:nil];
    XCTAssertNotNil(label);
    
    XCTAssertEqualObjects(name, label);
}

- (void)test_queueLabelForName_NonnullNameNonnullBundle_ReturnsReverseDNSBundleAndName {
    CRServerCreate();
    
    NSString *name = NSUUID.UUID.UUIDString;
    NSString *bundleIdentifier = NSBundle.mainBundle.bundleIdentifier ?: @"com.example.bundle";
    NSString *label = [server queueLabelForName:name bundleIdentifier:bundleIdentifier];
    XCTAssertNotNil(label);
    
    NSString *expected = [bundleIdentifier stringByAppendingPathExtension:name];
    XCTAssertEqualObjects(expected, label);
}

- (void)test_createQueueWithNameConcurrentQOS_NilName_ReturnsNonnull {
    CRServerCreate();
    
    dispatch_queue_t q = [server createQueueWithName:nil concurrent:NO qos:QOS_CLASS_UNSPECIFIED];
    
    XCTAssertNotNil(q);
}

@end
