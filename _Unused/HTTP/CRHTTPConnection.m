//
//  CRHTTPConnection.m
//  Criollo
//
//  Created by Cătălin Stan on 28/04/15.
//
//

#import <Criollo/CRApplication.h>
#import <Criollo/CRHTTPRequest.h>
#import <Criollo/CRHTTPResponse.h>
#import <Criollo/GCDAsyncSocket.h>

#import "GCDAsyncSocket+Criollo.h"
#import "CRHTTPConnection.h"
#import "CRApplication+Internal.h"

@interface CRHTTPConnection () <GCDAsyncSocketDelegate> {
    NSUInteger requestBodyLength;
    NSUInteger requestBodyReceivedBytesLength;
}

@property (nonatomic, strong) CRHTTPRequest* request;
@property (nonatomic, strong) CRHTTPResponse* response;

- (void)initialize;

- (void)didReceiveCompleteRequestHeaders;
- (void)didReceiveRequestHeaderData:(NSData*)data;

- (void)didReceiveRequestBody;
- (void)didReceiveRequestBodyData:(NSData*)data;

- (void)didReceiveCompleteRequest;

- (void)handleError:(CRError)errorType object:(id)object;

- (BOOL)shouldCloseConnection;

@end

@implementation CRHTTPConnection



- (void)dealloc
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self.socket setDelegate:nil delegateQueue:NULL];
    [self.socket disconnect];
}

#pragma mark - Request Processing

- (void)initialize
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    requestBodyReceivedBytesLength = 0;
    requestBodyLength = 0;
    
    [self.socket readDataToData:[GCDAsyncSocket CRLFCRLFData] withTimeout:CRSocketReadInitialTimeout maxLength:CRRequestMaxHeaderLength tag:CRSocketTagBeginReadingRequest];

}

- (void)didReceiveCompleteRequestHeaders
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"%@", self.request.allHTTPHeaderFields);
    NSLog(@"Method: %@", self.request.method);
}

- (void)didReceiveRequestHeaderData:(NSData *)data
{
    NSLog(@"%s %lu bytes", __PRETTY_FUNCTION__, data.length);
}

- (void)didReceiveRequestBody
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)didReceiveRequestBodyData:(NSData*)data
{
    NSLog(@"%s %lu bytes", __PRETTY_FUNCTION__, data.length);
}

- (void)didReceiveCompleteRequest
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [[CRApp workerQueue] addOperationWithBlock:^{
        self.response = [[CRHTTPResponse alloc] initWithHTTPConnection:self HTTPStatusCode:200];
        [self.response setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
        [self.response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-type"];

//        [response setValue:@"chunked" forHTTPHeaderField:@"Transfer-encoding"];

        [self.response writeString:@"<h1>Hello world!</h1>"];
        @synchronized([CRApp connections]) {
            [self.response writeFormat:@"<pre>Conntections: %@</pre>", [[CRApp connections] valueForKeyPath:@"request.URL.path"]];
        }
        [self.response end];
    }];
    
}

- (void)handleError:(CRError)errorType object:(id)object
{
    NSLog(@"%s %lu %@", __PRETTY_FUNCTION__, errorType, object);

    NSUInteger statusCode = 500;
    
    switch (errorType) {
        case CRErrorRequestMalformedRequest:
            statusCode = 400;
            [CRApp logErrorFormat:@"Malformed request: %@", [[NSString alloc] initWithData:object encoding:NSUTF8StringEncoding] ];
            break;
            
        case CRErrorRequestUnsupportedMethod:
            statusCode = 405;
            [CRApp logErrorFormat:@"Unsuppoerted method %@ for path %@", [object method], [object URL]];
            break;
            
        default:
            break;
    }
    
    self.response = [[CRHTTPResponse alloc] initWithHTTPConnection:self HTTPStatusCode:statusCode];
    [self.response setValue:@"0" forHTTPHeaderField:@"Content-length"];
    [self.response setValue:@"close" forHTTPHeaderField:@"Connection"];
    [self.response end];
}

- (BOOL)shouldCloseConnection
{

    BOOL shouldClose = NO;
    NSString *connection = [self.request valueForHTTPHeaderField:@"Connection"];
    if ( connection != nil ) {
        shouldClose = [connection caseInsensitiveCompare:@"close"] == NSOrderedSame;
    }
//    shouldClose = YES;
    return shouldClose;
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag
{
    NSLog(@"%s %lu bytes", __PRETTY_FUNCTION__, data.length);
    
    if (tag == CRSocketTagBeginReadingRequest || tag == CRSocketTagReadingRequestHeader)
    {
        BOOL result = [self.request appendData:data];
        if (!result) {
            
            // This is the first read, and it went wrong
            [self handleError:CRErrorRequestMalformedRequest object:data];
            return;
            
//        } else if ( !self.request.headerComplete ) {
//
//            [self didReceiveRequestHeaderData:data];
//            
//            // Continue to read until we get all the headers
//            [self.socket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:CRSocketReadHeaderLineTimeout maxLength:CRRequestMaxHeaderLineLength tag:CRSocketTagReadingRequestHeader];
            
        } else {
            
            [self didReceiveRequestHeaderData:data];
            [self didReceiveCompleteRequestHeaders];
            
            // We have all the headers
            if ( ![CRApp canHandleRequest:self.request] ) {
                [self handleError:CRErrorRequestUnsupportedMethod object:self.request];
                return;
            }
            
            requestBodyLength = [self.request valueForHTTPHeaderField:@"Content-Length"].integerValue;
            
            if ( requestBodyLength > 0 ) {
                NSUInteger bytesToRead = requestBodyLength < CRRequestBodyBufferSize ? requestBodyLength : CRRequestBodyBufferSize;
                [self.socket readDataToLength:bytesToRead withTimeout:CRSocketReadBodyTimeout tag:CRSocketTagReadingRequestBody];
            } else {
                [self didReceiveCompleteRequest];
            }
            
        }
    } if ( tag == CRSocketTagReadingRequestBody ) {

        requestBodyReceivedBytesLength += data.length;
        [self didReceiveRequestBodyData:data];
        
        if (requestBodyReceivedBytesLength < requestBodyLength) {
            NSUInteger requestBodyLeftBytesLength = requestBodyLength - requestBodyReceivedBytesLength;
            NSUInteger bytesToRead = requestBodyLeftBytesLength < CRRequestBodyBufferSize ? requestBodyLeftBytesLength : CRRequestBodyBufferSize;
            
            [self.socket readDataToLength:bytesToRead withTimeout:CRSocketReadBodyTimeout tag:CRSocketTagReadingRequestBody];
        } else {
            [self didReceiveCompleteRequest];
        }
        
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
 
    if ( tag == CRSocketTagFinishSendingResponseAndClosing || tag == CRSocketTagFinishSendingResponse ) {
        self.request = nil;
        self.response = nil;
        
        if ( tag == CRSocketTagFinishSendingResponseAndClosing || self.shouldCloseConnection) {
            [self.socket disconnect];
            return;
        } else {
            self.request = [[CRHTTPRequest alloc] init];
            [self initialize];
        }
        
    } else {

    }
    
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    self.socket = nil;
    self.request = nil;
    self.response = nil;

    dispatch_queue_t queue = [CRApplication sharedApplication].delegateQueue;
    dispatch_async(queue, ^{ @autoreleasepool {
        [CRApp socketDidDisconnect:self.socket withError:err];
        [CRApp didCloseConnection:self];
    }});
}

@end
