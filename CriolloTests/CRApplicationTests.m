//
//  CRApplicationTests.m
//  Criollo
//
//  Created by Cătălin Stan on 07/07/2020.
//  Copyright © 2020 Cătălin Stan. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <Criollo/CRApplication.h>

@interface CRApplicationTests : XCTestCase <CRApplicationDelegate>

@end

@implementation CRApplicationTests

- (void)test_sharedApplication__CRAppShouldNotBeNil {
    [CRApplication sharedApplication];
    XCTAssertNotNil(CRApp);
}

- (void)test_sharedApplication__CRAppShouldBeIdenticalToSharedApplication {
    CRApplication *sharedApplication = [CRApplication sharedApplication];
    XCTAssertEqual(CRApp, sharedApplication);
}

- (void)applicationDidFinishLaunching:(nonnull NSNotification *)notification {
}

@end
