//
//  CRRouterTests.m
//
//
//  Created by Catalin Stan on 06/03/2019.
//

#import <XCTest/XCTest.h>

#import "CRRoute_Internal.h"
#import "CRRouter_Internal.h"
#import "CRRouteMatchingResult_Internal.h"
#import "CRMessage_Internal.h"
#import "CRRequest_Internal.h"
#import "CRResponse_Internal.h"

@interface CRRouterTests : XCTestCase

@end

static CRRouteBlock noop;

@implementation CRRouterTests


- (void)testPlaceholderRoutes {
    
    CRRouteBlock block = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, dispatch_block_t  _Nonnull completionHandler){};
    CRRouter *router = [[CRRouter alloc] init];
    CRRoute *route = [[CRRoute alloc] initWithBlock:block method:CRHTTPMethodAny path:@"/routes/:foo" recursive:NO];
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

@end
