//
//  CRHTTPConnectionTests.m
//  CriolloTests macOS
//
//  Created by Adam Fedor on 4/19/19.
//  Copyright © 2019 Cătălin Stan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CRHTTPConnection.h"
#import "CRConnection_Internal.h"
#import "CRRequest.h"

@class GCDAsyncSocket;

#define CRHTTPConnectionCreate() CRHTTPConnection *connection = [[CRHTTPConnection alloc] init]

#define HTTP11Header ([@"GET /myendpoint HTTP/1.1\r\n\
Host: criollo.io\r\n\
Connection: keep-alive\r\n\
Cache-Control: max-age=0\r\n\
Upgrade-Insecure-Requests: 1\r\n\
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36\r\n\
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3\r\n\
Accept-Encoding: gzip, deflate\r\n\
Accept-Language: en-US,en;q=0.9\r\n" dataUsingEncoding:NSUTF8StringEncoding])

#define HTTP10Header ([@"GET /myendpoint HTTP/1.0\r\n\
Connection: keep-alive\r\n\
Cache-Control: max-age=0\r\n\
Upgrade-Insecure-Requests: 1\r\n\
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36\r\n\
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3\r\n\
Accept-Encoding: gzip, deflate\r\n\
Accept-Language: en-US,en;q=0.9\r\n" dataUsingEncoding:NSUTF8StringEncoding])


@interface CRHTTPConnectionTests : XCTestCase

@end

@implementation CRHTTPConnectionTests

- (void)testSocketDidReadData_WithHTTPVersion10_ShouldNotThrow {
    CRHTTPConnectionCreate();
    
    XCTAssertNoThrow([connection socket:(GCDAsyncSocket * _Nonnull)nil didReadData:HTTP10Header withTag:CRHTTPConnectionSocketTagBeginReadingRequest]);
}

- (void)testSocketDidReadData_WithHTTPVersion10_ShouldCreateRequest {
    CRHTTPConnectionCreate();
    
    [connection socket:connection.socket didReadData:HTTP10Header withTag:CRHTTPConnectionSocketTagBeginReadingRequest];

    XCTAssertNotNil(connection.requestBeingReceived, "Nil HTTP Version 1.0 request");
}

- (void)testSocketDidReadData_WithHTTPVersion11_ShouldCreateRequest {
    CRHTTPConnectionCreate();
    
    [connection socket:connection.socket didReadData:HTTP11Header withTag:CRHTTPConnectionSocketTagBeginReadingRequest];
    
    XCTAssertNotNil(connection.requestBeingReceived, "Nil HTTP Version 1.1 request");
    XCTAssertEqualObjects(connection.requestBeingReceived.URL.host, @"criollo.io", @"Incorrect host for HTTP 1.1 request");
}

@end
