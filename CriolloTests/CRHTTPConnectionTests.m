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
#import "GCDAsyncSocket.h"

#define http11Header @"GET /myendpoint HTTP/1.1\r\n\
Host: www.criollo.com\r\n\
Connection: keep-alive\r\n\
Cache-Control: max-age=0\r\n\
Upgrade-Insecure-Requests: 1\r\n\
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36\r\n\
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3\r\n\
Accept-Encoding: gzip, deflate\r\n\
Accept-Language: en-US,en;q=0.9\r\n"

#define http10Header @"GET /myendpoint HTTP/1.0\r\n\
Connection: keep-alive\r\n\
Cache-Control: max-age=0\r\n\
Upgrade-Insecure-Requests: 1\r\n\
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.103 Safari/537.36\r\n\
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3\r\n\
Accept-Encoding: gzip, deflate\r\n\
Accept-Language: en-US,en;q=0.9\r\n"

@interface CRHTTPConnection (PrivateTesting) <GCDAsyncSocketDelegate>
@end

@interface CRHTTPConnectionTests : XCTestCase

@end

@implementation CRHTTPConnectionTests
{
    CRHTTPConnection *sut;
}

- (void)setUp {
    sut = [[CRHTTPConnection alloc] init];
}

- (void)tearDown {
    sut = nil;
}

- (NSData *) dataFromHeaderString:(NSString *)string
{
    return [string dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)testSocketDidReadData_WithHTTPVersion10_ShouldNotThrow {
    NSData *data = [self dataFromHeaderString:http10Header];
    
    XCTAssertNoThrow([sut socket:(GCDAsyncSocket * _Nonnull)nil didReadData:data withTag:CRHTTPConnectionSocketTagBeginReadingRequest]);
}

- (void)testSocketDidReadData_WithHTTPVersion10_ShouldCreateRequest {
    NSData *data = [self dataFromHeaderString:http10Header];
    
    [sut socket:(GCDAsyncSocket * _Nonnull)nil didReadData:data withTag:CRHTTPConnectionSocketTagBeginReadingRequest];
    
    XCTAssertNotNil(sut.currentRequest, "Nil HTTP Version 1.0 request");
}

- (void)testSocketDidReadData_WithHTTPVersion11_ShouldCreateRequest {
    NSData *data = [self dataFromHeaderString:http11Header];
    
    [sut socket:(GCDAsyncSocket * _Nonnull)nil didReadData:data withTag:CRHTTPConnectionSocketTagBeginReadingRequest];
    
    XCTAssertNotNil(sut.currentRequest, "Nil HTTP Version 1.1 request");
    XCTAssertEqualObjects(sut.currentRequest.URL.host, @"www.criollo.com", @"Incorrect host for HTTP 1.1 request");
}


@end
