//
//  CRFCGIConnectionTests.m
//
//
//  Created by Adam Fedor on 4/19/19.
//

#import <XCTest/XCTest.h>
#import <Criollo/CRRequest.h>

#import "CRConnection_Internal.h"
#import "CRFCGIConnection.h"

@class GCDAsyncSocket;

#define CRFCGIConnectionCreate() CRFCGIConnection *connection = [[CRFCGIConnection alloc] init]

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

@interface CRFCGIConnectionTests : XCTestCase

@end

@implementation CRFCGIConnectionTests

//- (void)testSocketDidReadData_WithHTTPVersion10_ShouldNotThrow {
//    CRFCGIConnectionCreate();
//
////    XCTAssertNoThrow([connection socket:(GCDAsyncSocket * _Nonnull)nil didReadData:HTTP10Header withTag:CRFCGIConnectionSocketTagReadRecordHeader]);
//}
//
//- (void)testSocketDidReadData_WithHTTPVersion10_ShouldCreateRequest {
//    CRFCGIConnectionCreate();
//
//    [connection socket:connection.socket didReadData:HTTP10Header withTag:CRFCGIConnectionSocketTagReadRecordHeader];
//
//    XCTAssertNotNil(connection.requestBeingReceived, "Nil HTTP Version 1.0 request");
//}
//
//- (void)testSocketDidReadData_WithHTTPVersion11_ShouldCreateRequest {
//    CRFCGIConnectionCreate();
//
//    [connection socket:connection.socket didReadData:HTTP11Header withTag:CRFCGIConnectionSocketTagReadRecordHeader];
//
//    XCTAssertNotNil(connection.requestBeingReceived, "Nil HTTP Version 1.1 request");
//    XCTAssertEqualObjects(connection.requestBeingReceived.URL.host, @"criollo.io", @"Incorrect host for HTTP 1.1 request");
//}

@end
