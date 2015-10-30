//
//  CRConnection.h
//  Criollo
//
//  Created by Cătălin Stan on 10/23/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

@class GCDAsyncSocket, CRServer, CRRequest, CRResponse;

@interface CRConnection : NSObject

@property (nonatomic, weak) CRServer* server;
@property (nonatomic, strong) GCDAsyncSocket* socket;

@property (nonatomic, strong) CRRequest* request;
@property (nonatomic, strong) CRResponse* response;

@property (nonatomic, assign) BOOL ignoreKeepAlive;
@property (nonatomic, readonly) BOOL shouldClose;

+ (NSData*)CRLFData;
+ (NSData*)CRLFCRLFData;

- (instancetype)initWithSocket:(GCDAsyncSocket*)socket server:(CRServer*)server NS_DESIGNATED_INITIALIZER;

- (void)startReading;

- (void)didReceiveCompleteRequestHeaders;
- (void)didReceiveRequestBody;
- (void)didReceiveCompleteRequest;

@end
