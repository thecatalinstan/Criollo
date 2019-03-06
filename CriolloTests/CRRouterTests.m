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

@interface CRRouterTests : XCTestCase

@end

static CRRouteBlock noop;

@implementation CRRouterTests

- (void)setUp {
    [super setUp];
    noop = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        completionHandler();
    };
}

- (void)testPlaceholderRoutes {
    CRRouter *router = [[CRRouter alloc] init];
    CRRoute *route = [[CRRoute alloc] initWithBlock:noop method:CRHTTPMethodAll path:@"/routes/:foo" recursive:NO];
    [router addRoute:route];
    
    NSArray<NSString *> *paths = @[
                                   @"/routes/1234",
                                   @"/routes/abcd",
                                   @"/routes/AbCD",
                                   @"/routes/AbCd",
                                   @"/routes/1234abcd",
                                   @"/routes/A-b-C-d",
                                   @"/routes/A.b.C.d"
                                   ];
    
    for (NSString *path in paths ) {
        NSArray<CRRouteMatchingResult *> *routes = [router routesForPath:path method:CRHTTPMethodGet];
        XCTAssertNotNil(routes);
        XCTAssertEqual(1, routes.count, @"Path %@ should match 1 routes", path);
        XCTAssertTrue(routes.firstObject.route == route);
    }
}

@end
