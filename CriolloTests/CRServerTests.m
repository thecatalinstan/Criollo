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

@interface CRServerTests : XCTestCase

@end

@implementation CRServerTests

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

- (void)test_getDispatchQueueLabelForQueueLabel_NilLabelReturnsNULL {
    CRServerCreate();
    
    const char *out = "foo";
    [server getDispatchQueueLabel:&out forQueueLabel:nil];
    
    XCTAssertTrue(out == NULL);
}

- (void)test_getDispatchQueueLabelForQueueLabel_ASCIILabelReturnsAllCharacters {
    CRServerCreate();
    
    const char *in = "foobarbaz";
    const char *out;
    [server getDispatchQueueLabel:&out forQueueLabel:[NSString stringWithCString:in encoding:NSASCIIStringEncoding]];
    
    XCTAssertEqual(0, strcmp(in, out));
}

- (void)test_getDispatchQueueLabelForQueueLabel_UTF8LabelReturnsNotNull {
    CRServerCreate();
    
    const char *in = "🕸🎸🍻🤷🏻‍♂️";
    const char *out;
    [server getDispatchQueueLabel:&out forQueueLabel:[NSString stringWithUTF8String:in]];
    
    XCTAssertFalse(out == NULL);
}

- (void)test_CreateQueueWithNameConcurrentQOS_NilName_ReturnsNonnull {
    CRServerCreate();
    dispatch_queue_t q = [server createQueueWithName:nil concurrent:NO qos:QOS_CLASS_UNSPECIFIED];
    
    XCTAssertNotNil(q);
}

- (void)test_startListening_DefaultWorkerQueue_IsCreated {
    CRServerCreate();
    
    NSError *error;
    BOOL res = [server startListening:&error];
    XCTAssertTrue(res);
    if (!res) {
        NSLog(@" *** %@", error);
    }
    
    XCTAssertNotNil(server.workerQueue);
    XCTAssertTrue(server.workerQueueIsDefaultQueue);
    
    [server stopListening];
}

- (void)test_stopListening_DefaultWorkerQueue_IsDestroyed {
    CRServerCreate();
    
    NSError *error;
    BOOL res = [server startListening:&error];
    XCTAssertTrue(res);
    if (!res) {
        NSLog(@" *** %@", error);
    }
    [server stopListening];
    
    XCTAssertNil(server.workerQueue);
    XCTAssertFalse(server.workerQueueIsDefaultQueue);
}

- (void)test_startListening_CustomWorkerQueue_IsSet {
    CRServerCreate();
    
    NSOperationQueue *queue = [NSOperationQueue new];
    server.workerQueue = queue;
    
    NSError *error;
    BOOL res = [server startListening:&error];
    XCTAssertTrue(res);
    if (!res) {
        NSLog(@" *** %@", error);
    }
    
    XCTAssertEqual(queue, server.workerQueue);
    XCTAssertFalse(server.workerQueueIsDefaultQueue);
        
    [server stopListening];
}

- (void)test_startListening_CustomWorkerQueue_SetAfterStartListeningThrows {
    CRServerCreate();

    NSError *error;
    BOOL res = [server startListening:&error];
    XCTAssertTrue(res);
    if (!res) {
        NSLog(@" *** %@", error);
    }
    
    NSOperationQueue *queue = [NSOperationQueue new];
    XCTAssertThrows(server.workerQueue = queue);
        
    [server stopListening];
}

- (void)test_stopListening_CustomWorkerQueue_IsNotDestroyed {
    CRServerCreate();
    
    NSOperationQueue *queue = [NSOperationQueue new];
    server.workerQueue = queue;
    
    NSError *error;
    BOOL res = [server startListening:&error];
    XCTAssertTrue(res);
    if (!res) {
        NSLog(@" *** %@", error);
    }
    
    [server stopListening];
    
    XCTAssertNotNil(server.workerQueue);
    XCTAssertEqual(queue, server.workerQueue);
    XCTAssertFalse(server.workerQueueIsDefaultQueue);
}

@end
