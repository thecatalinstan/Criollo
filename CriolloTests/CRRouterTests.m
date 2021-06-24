//
//  CRRouterTests.m
//  Criollo
//
//  Created by Catalin Stan on 06/03/2019.
//  Copyright © 2019 Cătălin Stan. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "CRRoute.h"
#import "CRRoute_Internal.h"
#import "CRRouter.h"
#import "CRRouter_Internal.h"
#import "CRRouteMatchingResult.h"
#import "CRRouteMatchingResult_Internal.h"
#import "CRMessage.h"
#import "CRMessage_Internal.h"
#import "CRRequest.h"
#import "CRRequest_Internal.h"
#import "CRResponse.h"
#import "CRResponse_Internal.h"
#import "CRRouteMatchingResult.h"
#import "CRRouteMatchingResult_Internal.h"

@interface CRRouterTests : XCTestCase

@end

static CRRouteBlock noop;

@implementation CRRouterTests


- (void)testPlaceholderRoutes {
    
    CRRouteBlock block = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler){};
    CRRouter *router = [[CRRouter alloc] init];
    CRRoute *route = [[CRRoute alloc] initWithBlock:block method:CRHTTPMethodAll path:@"/routes/:foo" recursive:NO];
    [router addRoute:route];
    
    NSArray<NSString *> *paths = @[
                                   @"/routes/1234",
                                   @"/routes/abcd",
                                   @"/routes/AbCD",
                                   @"/routes/AbCd",
                                   @"/routes/1234abcd",
                                   @"/routes/A-b-C-d",
                                   @"/routes/A.b.C.d",
                                   @"/routes/A+b+C+d",
                                   @"/routes/A%20b%20C%20d",
                                   @"/routes/A_b_C_d"
                                   ];
    
    for (NSString *path in paths ) {
        NSArray<CRRouteMatchingResult *> *matches = [router routesForPath:path method:CRHTTPMethodGet];
        XCTAssertNotNil(matches);
        XCTAssertEqual(1, matches.count, @"Path %@ should match 1 routes", path);
        
        CRRouteMatchingResult *result = matches.firstObject;
        XCTAssertTrue(result.route == route);
        
        NSString *foo = result.matches.firstObject;
        XCTAssertNotNil(foo);

        NSString *expectedFoo = path.lastPathComponent;
        XCTAssertTrue([expectedFoo isEqualToString:foo]);
    }
}
    
- (void)testReplacingRoutes {
    CRRouteBlock block = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler){};
    CRRouter *router = [[CRRouter alloc] init];
    NSString *testPath = @"/routes/test";
    CRRoute *route = [[CRRoute alloc] initWithBlock:block method:CRHTTPMethodAll path:testPath recursive:NO];
    [router addRoute:route];
    
    NSArray<CRRouteMatchingResult *> *matches = [router routesForPath:testPath method:CRHTTPMethodGet];
    
    XCTAssertNotNil(matches);
    XCTAssertEqual(1, matches.count);
    XCTAssertEqual(matches.firstObject.route.block, block);
    
    CRRouteBlock newBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler){};
    
    [router replace:testPath block:newBlock];
    
    matches = [router routesForPath:testPath method:CRHTTPMethodGet];
    
    XCTAssertNotNil(matches);
    XCTAssertEqual(1, matches.count);
    XCTAssertNotEqual(matches.firstObject.route.block, block);
    XCTAssertEqual(matches.firstObject.route.block, newBlock);
}

@end
