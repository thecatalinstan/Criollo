//
//  CRConnection_Internal.h
//  Criollo
//
//  Created by Cătălin Stan on 11/20/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import <Criollo/CRConnection.h>

@import CocoaAsyncSocket;

@class CRServer, CRRequest;

NS_ASSUME_NONNULL_BEGIN

@interface CRConnection () <GCDAsyncSocketDelegate>

@property (nonatomic, strong, nullable) GCDAsyncSocket* socket;
@property (nonatomic, weak) CRServer* server;

/// The current request being parsed. This is used internally as the data comes
/// in from the socket. Once the request is fully formed, it can be passed on to
/// be handled.
@property (nonatomic, weak, nullable) CRRequest* requestBeingReceived;

/// HTTP Pipelining allows multiple requests to be send "in one go" and requires
/// their responses to be sent in order. As these requests can be completed out
/// of sequence, we'll keep a reference to the first request we need to send a
/// response for.
@property (nonatomic, weak, nullable) CRRequest* firstRequest;

- (void)addRequest:(CRRequest *)request;
- (void)removeRequest:(CRRequest *)request;

@property (nonatomic, readonly) BOOL willDisconnect;

- (instancetype)initWithSocket:(GCDAsyncSocket * _Nullable)socket
                        server:(CRServer * _Nullable)server
                      delegate:(id<CRConnectionDelegate> _Nullable)delegate
NS_DESIGNATED_INITIALIZER;

- (CRResponse *)responseWithHTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString * _Nullable)description version:(CRHTTPVersion)version;

- (void)startReading;
- (void)didReceiveCompleteHeaders:(CRRequest *)request;
- (void)didReceiveBodyData:(NSData *)data request:(CRRequest *)request;
- (void)didReceiveCompleteRequest:(CRRequest *)request;

- (void)sendData:(NSData *)data request:(CRRequest *)request;
- (void)didFinishResponseForRequest:(CRRequest *)request;

@end

NS_ASSUME_NONNULL_END
