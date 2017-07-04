//
//  CRHTTPServerTests.m
//  Criollo
//
//  Created by Cătălin Stan on 04/07/2017.
//  Copyright © 2017 Cătălin Stan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CRiollo/Criollo.h>

#define Port        10781

@interface CRHTTPServerTests : XCTestCase {
}

@property (nonatomic, nonnull, strong) CRHTTPServer *server;
@property (nonatomic, nonnull, strong) NSURL *baseURL;

@end

@implementation CRHTTPServerTests

- (void)setUp {
    [super setUp];
    
    self.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://127.0.0.1:%d/", Port]];
    self.server = [[CRHTTPServer alloc] init];
    
    [self setupRoutes];
}

- (void)setupRoutes {
    // All headers
    [self.server add:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        static NSBundle *bundle;
        static NSString *serverVersion;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            bundle = [NSBundle bundleForClass:[CRServer class]];
            serverVersion = [NSString stringWithFormat:@"%@-%@", bundle.bundleIdentifier, [bundle objectForInfoDictionaryKey:(__bridge NSString *)kCFBundleInfoDictionaryVersionKey]];
        });
        
        [response setValue:serverVersion forHTTPHeaderField:@"Server"];
        [response setValue:@"text/plain" forHTTPHeaderField:@"Content-type"];
    }];
    
    // Hello
    [self.server get:@"/" block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response send:@"Hello world"];
    }];
}

- (void)tearDown {
    [self.server closeAllConnections:^{
        [self.server stopListening];
    }];
    
    [super tearDown];
}

- (void)testServerStart {
    NSError *error;
    [self.server startListening:&error portNumber:Port];
    if ( error ) {
        NSLog(@"%@", error);
    }
    XCTAssertNil(error, @"Server should be able to start listening");
}

- (void)testCloseConnection {
    
}

- (void)testValidHTTPResponse {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request to /"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithURL:self.baseURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        XCTAssertNil(error, @"Connections to the server should succeed");
        XCTAssertNotNil(data, @"The server should not send an empty response");
        XCTAssertTrue([response isKindOfClass:[NSHTTPURLResponse class]], @"Response should be a valid NSHTTPURLResponse");
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        XCTAssertEqual(httpResponse.statusCode, 200, @"HTTP response status code should be 200");
        XCTAssertEqual(httpResponse.URL.absoluteString, self.baseURL.absoluteString, @"HTTP response URL should be equal to original URL");
        XCTAssertEqual(httpResponse.MIMEType, @"text/plain", @"HTTP response content type should be text/html");
        
        [expectation fulfill];
    }];
    
    [task resume];
    
    [self waitForExpectationsWithTimeout:[NSURLSessionConfiguration defaultSessionConfiguration].timeoutIntervalForRequest handler:^(NSError * _Nullable error) {
        if ( error ) {
            NSLog(@"%@", error);
        }
        [task cancel];
    }];
}


@end
