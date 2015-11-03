//
//  CRConnection.h
//  Criollo
//
//  Created by Cătălin Stan on 10/23/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#define CRConnectionSocketTagFinishSendingResponse                  90
#define CRConnectionSocketTagFinishSendingResponseAndClosing        91

@class GCDAsyncSocket, CRServer, CRRequest, CRResponse;

@interface CRConnection : NSObject

@property (nonatomic, weak) CRServer* server;
@property (nonatomic, strong) GCDAsyncSocket* socket;

@property (nonatomic, strong) CRRequest* request;
@property (nonatomic, strong) CRResponse* response;

@property (nonatomic, assign) BOOL ignoreKeepAlive;
@property (nonatomic, readonly) BOOL shouldClose;

@property (nonatomic, strong) NSDate* requestTime;

+ (NSData*)CRLFData;
+ (NSData*)CRLFCRLFData;

- (instancetype)initWithSocket:(GCDAsyncSocket*)socket server:(CRServer*)server NS_DESIGNATED_INITIALIZER;

- (void)startReading;

- (void)didReceiveCompleteRequestHeaders;
- (void)didReceiveRequestBody;
- (void)didReceiveCompleteRequest;

- (void)handleError:(NSUInteger)errorType object:(id)object;

- (CRResponse*)responseWithHTTPStatusCode:(NSUInteger)HTTPStatusCode;
- (CRResponse*)responseWithHTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description;
- (CRResponse*)responseWithHTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description version:(NSString *)version;


@end
