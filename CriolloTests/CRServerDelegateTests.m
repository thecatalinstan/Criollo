//
//  CRServerDelegateTests.m
//  CriolloTests macOS
//
//  Created by Cătălin Stan on 21/05/2020.
//  Copyright © 2020 Cătălin Stan. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "CRserver.h"
#import "CRserver_Internal.h"

#define CRServerCreate() CRServer *server = [CRServer new]
#define CRServerCreateWithDelegate() TestServerDelegate *delegate = [TestServerDelegate new]; CRServer *server = [[CRServer alloc] initWithDelegate:delegate]
#define CRServerCreateWithDelegateQueue() TestServerDelegate *delegate = [TestServerDelegate new]; delegate.queue = dispatch_queue_create(NULL, NULL); CRServer *server = [[CRServer alloc] initWithDelegate:delegate delegateQueue:delegate.queue]

#define CRServerDestroy() server = nil

#define CRServerStart() NSError *error; while(![server startListening:&error portNumber:(2000 + (NSUInteger)arc4random_uniform(3000))]) { NSLog(@" *** %@", error); error = nil;}
#define CRServerStop() [server stopListening]

@interface TestServerDelegate : NSObject<CRServerDelegate>

@property (nonatomic, strong) XCTestExpectation *willStartListeningExpectation;
@property (nonatomic, strong) XCTestExpectation *didStartListeningExpectation;

@property (nonatomic, strong) XCTestExpectation *willStopListeningExpectation;
@property (nonatomic, strong) XCTestExpectation *didStopListeningExpectation;

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, strong) XCTestExpectation *willStartListeningQueueExpectation;
@property (nonatomic, strong) XCTestExpectation *didStartListeningQueueExpectation;
@property (nonatomic, strong) XCTestExpectation *willStopListeningQueueExpectation;
@property (nonatomic, strong) XCTestExpectation *didStopListeningQueueExpectation;

@end

@implementation TestServerDelegate

- (void)serverWillStartListening:(CRServer *)server {
    [self.willStartListeningExpectation fulfill];
    if (self.queue && server.delegateQueue == self.queue) {
        [self.willStartListeningQueueExpectation fulfill];
    }
}

- (void)serverDidStartListening:(CRServer *)server {
    [self.didStartListeningExpectation fulfill];
    if (self.queue && server.delegateQueue == self.queue) {
        [self.didStartListeningQueueExpectation fulfill];
    }
}

- (void)serverWillStopListening:(CRServer *)server {
    [self.willStopListeningExpectation fulfill];
    if (self.queue && server.delegateQueue == self.queue) {
        [self.willStopListeningQueueExpectation fulfill];
    }
}

- (void)serverDidStopListening:(CRServer *)server {
    [self.didStopListeningExpectation fulfill];
    if (self.queue && server.delegateQueue == self.queue) {
        [self.didStopListeningQueueExpectation fulfill];
    }
}

@end

@interface CRServerDelegateTests : XCTestCase

@end

@implementation CRServerDelegateTests

- (void)test_delegate_isSet {
    CRServerCreateWithDelegate();
 
    XCTAssertNotNil(delegate);
    XCTAssertEqual(delegate, server.delegate);
}

- (void)test_serverWillStartListening_isCalled {
    CRServerCreateWithDelegate();
    
    delegate.willStartListeningExpectation = [[XCTestExpectation alloc] initWithDescription:@(__PRETTY_FUNCTION__)];
    delegate.willStartListeningExpectation.assertForOverFulfill = YES;
    
    CRServerStart();
    
    [self waitForExpectations:@[delegate.willStartListeningExpectation] timeout:5.];
    
    CRServerStop();
}

- (void)test_serverWillStartListening_isCalledOnDelegateQueue {
    CRServerCreateWithDelegateQueue();
    
    delegate.willStartListeningQueueExpectation = [[XCTestExpectation alloc] initWithDescription:@(__PRETTY_FUNCTION__)];
    delegate.willStopListeningQueueExpectation.assertForOverFulfill = YES;
    
    CRServerStart();
    
    [self waitForExpectations:@[delegate.willStartListeningQueueExpectation] timeout:5.];
    
    CRServerStop();
}

- (void)test_serverDidStartListening_isCalled {
    CRServerCreateWithDelegate();
    
    delegate.didStartListeningExpectation = [[XCTestExpectation alloc] initWithDescription:@(__PRETTY_FUNCTION__)];
    delegate.didStartListeningExpectation.assertForOverFulfill = YES;
    
    CRServerStart();
    
    [self waitForExpectations:@[delegate.didStartListeningExpectation] timeout:5.];
    
    CRServerStop();
}

- (void)test_serverDidStartListening_isCalledOnDelegateQueue {
    CRServerCreateWithDelegateQueue();
    
    delegate.didStartListeningQueueExpectation = [[XCTestExpectation alloc] initWithDescription:@(__PRETTY_FUNCTION__)];
    delegate.didStartListeningQueueExpectation.assertForOverFulfill = YES;
    
    CRServerStart();
    
    [self waitForExpectations:@[delegate.didStartListeningQueueExpectation] timeout:5.];
    
    CRServerStop();
}

- (void)test_serverDidStartListening_isCalledAfterWillStartListening {
    CRServerCreateWithDelegate();
    
    delegate.willStartListeningExpectation = [[XCTestExpectation alloc] initWithDescription:@"willStart"];
    delegate.willStartListeningExpectation.assertForOverFulfill = YES;
    delegate.didStartListeningExpectation = [[XCTestExpectation alloc] initWithDescription:@"didStart"];
    delegate.didStartListeningExpectation.assertForOverFulfill = YES;
    
    CRServerStart();
    
    [self waitForExpectations:@[
        delegate.willStartListeningExpectation,
        delegate.didStartListeningExpectation
    ] timeout:5. enforceOrder:YES];
    
    CRServerStop();
}

- (void)test_serverWillStopListening_isCalled {
    CRServerCreateWithDelegate();
    
    delegate.willStopListeningExpectation = [[XCTestExpectation alloc] initWithDescription:@(__PRETTY_FUNCTION__)];
    delegate.willStopListeningExpectation.assertForOverFulfill = YES;
    
    CRServerStart();
    CRServerStop();
    
    [self waitForExpectations:@[delegate.willStopListeningExpectation] timeout:5.];
}

- (void)test_serverWillStopListening_isCalledOnDelegateQueue {
    CRServerCreateWithDelegateQueue();
    
    delegate.willStopListeningQueueExpectation = [[XCTestExpectation alloc] initWithDescription:@(__PRETTY_FUNCTION__)];
    delegate.willStopListeningQueueExpectation.assertForOverFulfill = YES;
    
    CRServerStart();
    CRServerStop();
    
    [self waitForExpectations:@[delegate.willStopListeningQueueExpectation] timeout:5.];
}

- (void)test_serverDidStopListening_isCalled {
    CRServerCreateWithDelegate();

    delegate.didStopListeningExpectation = [[XCTestExpectation alloc] initWithDescription:@(__PRETTY_FUNCTION__)];
    delegate.didStopListeningExpectation.assertForOverFulfill = YES;

    CRServerStart();
    CRServerStop();

    [self waitForExpectations:@[delegate.didStopListeningExpectation] timeout:5.];
}

- (void)test_serverDidStopListening_isCalledOnDelegateQueue {
    CRServerCreateWithDelegateQueue();
    
    delegate.didStopListeningQueueExpectation = [[XCTestExpectation alloc] initWithDescription:@(__PRETTY_FUNCTION__)];
    delegate.didStopListeningQueueExpectation.assertForOverFulfill = YES;

    
    CRServerStart();
    CRServerStop();
    
    [self waitForExpectations:@[delegate.didStopListeningQueueExpectation] timeout:5.];
}

- (void)test_serverDidStopListening_isCalledAfterWillStopListening {
    CRServerCreateWithDelegate();

    delegate.willStopListeningExpectation = [[XCTestExpectation alloc] initWithDescription:@"willStop"];
    delegate.willStopListeningExpectation.assertForOverFulfill = YES;
    delegate.didStopListeningExpectation = [[XCTestExpectation alloc] initWithDescription:@"didStop"];
    delegate.didStopListeningExpectation.assertForOverFulfill = YES;

    CRServerStart();
    CRServerStop();

    [self waitForExpectations:@[
        delegate.willStopListeningExpectation,
        delegate.didStopListeningExpectation
    ] timeout:5. enforceOrder:YES];

}

@end
