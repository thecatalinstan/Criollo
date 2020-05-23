//
//  CRRequestTests.m
//  Criollo
//
//  Created by Cătălin Stan on 23/05/2020.
//  Copyright © 2020 Cătălin Stan. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "CRRequest.h"
#import "CRRequest_Internal.h"

NS_INLINE NSData *URLEncodedBodyData(NSDictionary *params, NSStringEncoding encoding);
NS_INLINE NSDictionary *ParseURLEncodedBodyData(NSDictionary *params);

@interface CRRequestTests : XCTestCase
@end

@implementation CRRequestTests

- (void)test_parseURLEncodedBodyData_valuesContainingPercent_decodedCorrectly {
    NSDictionary *params = @{
        @"foo": @"%bar",
        @"baz": @"%qux"
    };
    
    NSDictionary *body = ParseURLEncodedBodyData(params);
    
    XCTAssertNotNil(body[@"foo"]);
    XCTAssertNotNil(body[@"baz"]);
    
    XCTAssertEqual(NSOrderedSame, [body[@"foo"] localizedCompare:params[@"foo"]]);
    XCTAssertEqual(NSOrderedSame, [body[@"baz"] localizedCompare:params[@"baz"]]);
    
    XCTAssertTrue([body[@"foo"] isEqualToString:@"%bar"]);
    XCTAssertTrue([body[@"baz"] isEqualToString:@"%qux"]);
}

- (void)test_parseURLEncodedBodyData_keysContainingPercent_decodedCorrectly {
    NSDictionary *params = @{
        @"%foo": @"bar",
        @"%baz": @"qux"
    };
    
    NSDictionary *body = ParseURLEncodedBodyData(params);
    
    XCTAssertNotNil(body[@"%foo"]);
    XCTAssertNotNil(body[@"%baz"]);
    
    XCTAssertEqual(NSOrderedSame, [body[@"%foo"] localizedCompare:params[@"%foo"]]);
    XCTAssertEqual(NSOrderedSame, [body[@"%baz"] localizedCompare:params[@"%baz"]]);
            
    XCTAssertTrue([body[@"%foo"] isEqualToString:@"bar"]);
    XCTAssertTrue([body[@"%baz"] isEqualToString:@"qux"]);
}

@end

NSData *URLEncodedBodyData(NSDictionary *params, NSStringEncoding encoding) {
    NSMutableString *URLEncodedString = [[NSMutableString alloc] initWithCapacity:params.count * 2 * 10];
    NSUInteger idx = 0;
    for (NSString *key in params) {
        [URLEncodedString appendFormat:@"%@=%@",
         [key stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet],
         [params[key] stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]];
        if (++idx < params.count) {
            [URLEncodedString appendString:@"&"];
        }
    }
    return [URLEncodedString dataUsingEncoding:encoding allowLossyConversion:NO];
}

NSDictionary *ParseURLEncodedBodyData(NSDictionary *params) {
    CRRequest *req = [[CRRequest alloc] initWithMethod:CRHTTPMethodPost URL:nil version:CRHTTPVersion1_1];
    // No need to actually make a mutable copy as parseURLEncodedBodyData doesn't
    // mutate the object. Should this ever change, we'll get an `unrecognized selector`
    req.bufferedBodyData = (NSMutableData *)URLEncodedBodyData(params, NSUTF8StringEncoding);
    [req parseURLEncodedBodyData:nil];
    return (NSDictionary *)req.body;
}
