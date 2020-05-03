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

- (void)test_startListening_DefaultWorkerQueue_IsCreated {
    CRServerCreate();
    
    XCTAssertTrue([server startListening]);
    
    XCTAssertNotNil(server.workerQueue);
    XCTAssertTrue(server.workerQueueIsDefaultQueue);
}

- (void)test_stopListening_DefaultWorkerQueue_IsDestroyed {
    CRServerCreate();
    
    XCTAssertTrue([server startListening]);
    [server stopListening];
    
    XCTAssertNil(server.workerQueue);
    XCTAssertFalse(server.workerQueueIsDefaultQueue);
}

- (void)test_startListening_CustomWorkerQueue_IsSet {
    CRServerCreate();
    
    NSOperationQueue *queue = [NSOperationQueue new];
    server.workerQueue = queue;
    
    XCTAssertTrue([server startListening]);
    
    XCTAssertEqual(queue, server.workerQueue);
    XCTAssertFalse(server.workerQueueIsDefaultQueue);
}

- (void)test_startListening_CustomWorkerQueue_IsNotSetAfterStartListening {
    CRServerCreate();

    XCTAssertTrue([server startListening]);
    
    NSOperationQueue *queue = [NSOperationQueue new];
    XCTAssertThrows(server.workerQueue = queue);
}

- (void)test_stopListening_CustomWorkerQueue_IsNotDestroyed {
    CRServerCreate();
    
    NSOperationQueue *queue = [NSOperationQueue new];
    server.workerQueue = queue;
    
    XCTAssertTrue([server startListening]);
    [server stopListening];
    
    XCTAssertNotNil(server.workerQueue);
    XCTAssertEqual(queue, server.workerQueue);
    XCTAssertFalse(server.workerQueueIsDefaultQueue);
}

@end
