//
//  CRRequestTests.m
//
//
//  Created by Cătălin Stan on 23/05/2020.
//

#import <XCTest/XCTest.h>

#import "CRRequest_Internal.h"

NS_INLINE NSString *URLEncodedQueryString(NSDictionary *params);
NS_INLINE NSDictionary *ParseURLEncodedBodyData(NSDictionary *params);
NS_INLINE NSDictionary *ParseQueryString(NSDictionary *params);

@interface CRRequestTests : XCTestCase
@end

@implementation CRRequestTests

- (void)test_parseQueryString_valuesContainingPercent_decodedCorrectly {
    NSDictionary *params = @{
        @"foo": @"%bar",
        @"baz": @"%qux"
    };
    
    NSDictionary *query = ParseQueryString(params);
    
    XCTAssertNotNil(query[@"foo"]);
    XCTAssertNotNil(query[@"baz"]);
    
    XCTAssertEqual(NSOrderedSame, [query[@"foo"] localizedCompare:params[@"foo"]]);
    XCTAssertEqual(NSOrderedSame, [query[@"baz"] localizedCompare:params[@"baz"]]);
    
    XCTAssertTrue([query[@"foo"] isEqualToString:@"%bar"]);
    XCTAssertTrue([query[@"baz"] isEqualToString:@"%qux"]);
}

- (void)test_parseQueryString_keysContainingPercent_decodedCorrectly {
    NSDictionary *params = @{
        @"%foo": @"bar",
        @"%baz": @"qux"
    };
    
    NSDictionary *query = ParseQueryString(params);
    
    XCTAssertNotNil(query[@"%foo"]);
    XCTAssertNotNil(query[@"%baz"]);
    
    XCTAssertEqual(NSOrderedSame, [query[@"%foo"] localizedCompare:params[@"%foo"]]);
    XCTAssertEqual(NSOrderedSame, [query[@"%baz"] localizedCompare:params[@"%baz"]]);
            
    XCTAssertTrue([query[@"%foo"] isEqualToString:@"bar"]);
    XCTAssertTrue([query[@"%baz"] isEqualToString:@"qux"]);
}


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

NSString *URLEncodedQueryString(NSDictionary *params) {
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
    return URLEncodedString;
}

NSDictionary *ParseURLEncodedBodyData(NSDictionary *params) {
    CRRequest *req = [[CRRequest alloc] initWithMethod:CRHTTPMethodPost URL:nil version:CRHTTPVersion1_1];
    NSString *string = URLEncodedQueryString(params);
    
    // No need to actually make a mutable copy as parseURLEncodedBodyData doesn't
    // mutate the object. Should this ever change, we'll get an `unrecognized selector`
    req.bufferedBodyData = (NSMutableData *)[string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    
    [req parseURLEncodedBodyData:nil];
    return (NSDictionary *)req.body;
}

NSDictionary *ParseQueryString(NSDictionary *params) {
    CRRequest *req = [[CRRequest alloc] initWithMethod:CRHTTPMethodPost URL:nil version:CRHTTPVersion1_1];
    [req setEnv:URLEncodedQueryString(params) forKey:@"QUERY_STRING"];
    [req parseQueryString];
    return req.query;
}
