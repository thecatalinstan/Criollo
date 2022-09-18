//
//  CRConnection.m
//
//
//  Created by Cătălin Stan on 10/23/15.
//

#import "CRConnection_Internal.h"

#import <sys/sysctl.h>
#import <sys/types.h>

#import "CocoaAsyncSocket.h"
#import "CRRequest_Internal.h"
#import "CRResponse_Internal.h"
#import "CRServer_Internal.h"
#import "CRServerConfiguration.h"
#import "NSDate+RFC1123.h"

static int const CRConnectionSocketTagSendingResponse = 20;

static NSUInteger const InitialRequestsCapacity = 1 << 8;

NS_ASSUME_NONNULL_BEGIN

@interface CRConnection ()

@property (nonatomic, weak, nullable) id<CRConnectionDelegate> delegate;

@property (nonatomic, strong) NSLock *requestsLock;
@property (nonatomic, strong) NSMutableArray<CRRequest *> *requests;

- (void)bufferBodyData:(NSData *)data request:(CRRequest *)request;

- (void)bufferResponseData:(NSData *)data request:(CRRequest *)request;

@end

NS_ASSUME_NONNULL_END

@implementation CRConnection

#pragma mark - Responses

- (CRResponse *)responseWithHTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description version:(CRHTTPVersion)version CR_OBJC_ABSTRACT;

#pragma mark - Initializers

- (instancetype)initWithSocket:(GCDAsyncSocket *)socket server:(CRServer *)server delegate:(id<CRConnectionDelegate> _Nullable)delegate {
    self = [super init];
    if (self != nil) {
        _server = server;
        _socket = socket;
        _socket.delegate = self;
        _delegate = delegate;
        
        _requests = [NSMutableArray arrayWithCapacity:InitialRequestsCapacity];
        _requestsLock = [NSLock new];

        _remoteAddress = _socket.connectedHost;
        _remotePort = _socket.connectedPort;
        _localAddress = _socket.localHost;
        _localPort = _socket.localPort;
    }
    return self;
}

- (void)dealloc {
    [_socket disconnect];
    _socket.delegate = nil;
    _socket = nil;
    
    _requestBeingReceived = nil;
    _firstRequest = nil;
}

- (void)addRequest:(CRRequest *)request {
    [self.requestsLock lock];
    [self.requests addObject:request];
    if (self.requests.count == 1) {
        self.firstRequest = request;
    }
    [self.requestsLock unlock];
}

- (void)removeRequest:(CRRequest *)request {
    [self.requestsLock lock];
    [self.requests removeObject:request];
    self.firstRequest = self.requests.firstObject;
    [self.requestsLock unlock];
}

#pragma mark - Data

- (void)startReading CR_OBJC_ABSTRACT;
- (void)didReceiveCompleteHeaders:(CRRequest *)request CR_OBJC_ABSTRACT;

- (void)didReceiveBodyData:(NSData *)data request:(CRRequest *)request {
    if (self.willDisconnect) {
        return;
    }

    NSString * contentType = request.env[@"HTTP_CONTENT_TYPE"];
    if (contentType.requestContentType == CRRequestContentTypeURLEncoded) {
        // URL-encoded requests are parsed after we have all the data
        [self bufferBodyData:data request:request];
    } else if (contentType.requestContentType == CRRequestContentTypeMultipart) {
        NSError* multipartParsingError;
        if (![request parseMultipartBodyDataChunk:data error:&multipartParsingError]) {
            NSLog(@"%@" , multipartParsingError);
        }
    } else if (contentType.requestContentType == CRRequestContentTypeJSON) {
        // JSON requests are parsed after we have all the data
        [self bufferBodyData:data request:request];
    } else {
        NSError* mimeParsingError;
        if ( ![request parseMIMEBodyDataChunk:data error:&mimeParsingError] ) {
            NSLog(@"%@" , mimeParsingError);
        }
    }
}

- (void)didReceiveCompleteRequest:(CRRequest *)request {
    if (self.willDisconnect) {
        return;
    }

    // Parse request body
    NSUInteger contentLength = [self.requestBeingReceived.env[@"HTTP_CONTENT_LENGTH"] integerValue];
    if ( contentLength > 0 ) {
        NSError* bodyParsingError;
        NSString* contentType = self.requestBeingReceived.env[@"HTTP_CONTENT_TYPE"];

        BOOL result = YES;

        if (contentType.requestContentType == CRRequestContentTypeJSON) {
            result = [self.requestBeingReceived parseJSONBodyData:&bodyParsingError];
        } else if (contentType.requestContentType == CRRequestContentTypeURLEncoded) {
            result = [self.requestBeingReceived parseURLEncodedBodyData:&bodyParsingError];
        } else if (contentType.requestContentType == CRRequestContentTypeMultipart) {
            // multipart/form-data requests are parsed as they come in and not once the
            // request hast been fully received ;)
        } else {
            // other mime types are assumed to be files and will be treated just like
            // multipart request files. What we need to do here is to reset the target
            [self.requestBeingReceived clearBodyParsingTargets];
        }

        if ( !result ) {
            // TODO: Propagate the error, do not log from here
            NSLog(@"%@" , bodyParsingError);
        }
    }

    CRResponse* response = [self responseWithHTTPStatusCode:200 description:nil version:self.requestBeingReceived.version];
    self.requestBeingReceived.response = response;
    response.request = self.requestBeingReceived;
    [self.delegate connection:self didReceiveRequest:self.requestBeingReceived response:response];
    [self startReading];
}

- (void)bufferBodyData:(NSData *)data request:(CRRequest *)request {
    if (self.willDisconnect) {
        return;
    }

    [request bufferBodyData:data];
}

- (void)bufferResponseData:(NSData *)data request:(CRRequest *)request {
    if ( self.willDisconnect ) {
        return;
    }

    [request bufferResponseData:data];
}

- (void)sendData:(NSData *)data request:(CRRequest *)request {
    if (self.willDisconnect) {
        return;
    }
    
    if ( request == self.firstRequest ) {
        request.bufferedResponseData = nil;
        [self.socket writeData:data withTimeout:self.server.configuration.CRConnectionWriteTimeout tag:CRConnectionSocketTagSendingResponse];
        if ( request.shouldCloseConnection ) {
            _willDisconnect = YES;
            [self.socket disconnectAfterWriting];
        }
        if ( request.response.finished ) {
            [self didFinishResponseForRequest:request];
        }
    } else {
        [self bufferResponseData:data request:request];
    }
}

- (void)didFinishResponseForRequest:(CRRequest *)request {
    [self.delegate connection:self didFinishRequest:request response:request.response];
    [self removeRequest:request];
}

#pragma mark - State

- (BOOL)shouldClose {
    return NO;
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    if (self.willDisconnect) {
        return;
    }
    
    if (tag == CRConnectionSocketTagSendingResponse) {
        NSData *bufferedResponseData = self.firstRequest.bufferedResponseData;
        if (bufferedResponseData.length > 0) {
            [self sendData:bufferedResponseData request:self.firstRequest];
        }
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    [self.server didCloseConnection:self];
}

@end
