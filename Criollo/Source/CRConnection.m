//
//  CRConnection.m
//  Criollo
//
//  Created by Cătălin Stan on 10/23/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import <Criollo/CRConnection.h>

#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import <Criollo/CRApplication.h>
#import <Criollo/CRRequest.h>
#import <Criollo/CRResponse.h>
#import <Criollo/CRServer.h>
#import <sys/sysctl.h>
#import <sys/types.h>

#import "CRConnection_Internal.h"
#import "CRRequest_Internal.h"
#import "CRResponse_Internal.h"
#import "CRServer_Internal.h"
#import "CRServerConfiguration.h"
#import "NSDate+RFC1123.h"

static int const CRConnectionSocketTagSendingResponse = 20;

static NSUInteger const InitialRequestsCapacity = 1 << 8;

NS_ASSUME_NONNULL_BEGIN

@interface CRConnection ()

@property (nonatomic, strong) NSLock *requestsLock;
@property (nonatomic, strong) NSMutableArray<CRRequest *> * requests;

- (void)bufferBodyData:(NSData *)data forRequest:(CRRequest *)request;
- (void)bufferResponseData:(NSData *)data forRequest:(CRRequest *)request;

@end

NS_ASSUME_NONNULL_END

@implementation CRConnection

static const NSData * CRLFData;
static const NSData * CRLFCRLFData;

+ (void)initialize {
    CRLFData = [NSData dataWithBytes:"\x0D\x0A" length:2];
    CRLFCRLFData = [NSData dataWithBytes:"\x0D\x0A\x0D\x0A" length:4];
}

+ (NSData *)CRLFCRLFData {
    return (NSData *)CRLFCRLFData;
}

+ (NSData *)CRLFData {
    return (NSData *)CRLFData;
}

#pragma mark - Responses

- (CRResponse *)responseWithHTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description version:(CRHTTPVersion)version {
    return [[CRResponse alloc] initWithConnection:self HTTPStatusCode:HTTPStatusCode description:description version:version];
}

#pragma mark - Initializers

- (instancetype)init {
    return [self initWithSocket:nil server:nil];
}

- (instancetype)initWithSocket:(GCDAsyncSocket *)socket server:(CRServer *)server {
    self = [super init];
    if (self != nil) {
        _server = server;
        _socket = socket;
        _socket.delegate = self;
        
        _requests = [NSMutableArray arrayWithCapacity:InitialRequestsCapacity];
        _requestsLock = [NSLock new];

        _remoteAddress = self.socket.connectedHost;
        _remotePort = self.socket.connectedPort;
        _localAddress = self.socket.localHost;
        _localPort = self.socket.localPort;
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

- (void)startReading {
    self.requestBeingReceived = nil;
}

- (void)didReceiveCompleteRequestHeaders {
    if (self.willDisconnect) {
        return;
    }
}

- (void)didReceiveRequestBodyData:(NSData *)data {
    if (self.willDisconnect) {
        return;
    }

    NSString * contentType = self.requestBeingReceived.env[@"HTTP_CONTENT_TYPE"];
    if (contentType.requestContentType == CRRequestContentTypeURLEncoded) {
        // URL-encoded requests are parsed after we have all the data
        [self bufferBodyData:data forRequest:self.requestBeingReceived];
    } else if (contentType.requestContentType == CRRequestContentTypeMultipart) {
        NSError* multipartParsingError;
        if (![self.requestBeingReceived parseMultipartBodyDataChunk:data error:&multipartParsingError]) {
            [CRApp logErrorFormat:@"%@" , multipartParsingError];
        }
    } else if (contentType.requestContentType == CRRequestContentTypeJSON) {
        // JSON requests are parsed after we have all the data
        [self bufferBodyData:data forRequest:self.requestBeingReceived];
    } else {
        NSError* mimeParsingError;
        if ( ![self.requestBeingReceived parseMIMEBodyDataChunk:data error:&mimeParsingError] ) {
            [CRApp logErrorFormat:@"%@" , mimeParsingError];
        }
    }
}

- (void)didReceiveCompleteRequest {
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
            [CRApp logErrorFormat:@"%@" , bodyParsingError];
        }
    }

    CRResponse* response = [self responseWithHTTPStatusCode:200 description:nil version:self.requestBeingReceived.version];
    self.requestBeingReceived.response = response;
    response.request = self.requestBeingReceived;
    [self.delegate connection:self didReceiveRequest:self.requestBeingReceived response:response];
    [self startReading];
}

- (void)bufferBodyData:(NSData *)data forRequest:(CRRequest *)request {
    if (self.willDisconnect) {
        return;
    }

    [request bufferBodyData:data];
}

- (void)bufferResponseData:(NSData *)data forRequest:(CRRequest *)request {
    if ( self.willDisconnect ) {
        return;
    }

    [request bufferResponseData:data];
}

- (void)sendDataToSocket:(NSData *)data forRequest:(CRRequest *)request {
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
        [self bufferResponseData:data forRequest:request];
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
            [self sendDataToSocket:bufferedResponseData forRequest:self.firstRequest];
        }
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    [self.server didCloseConnection:self];
}

@end
