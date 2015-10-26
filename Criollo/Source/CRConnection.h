//
//  CRConnection.h
//  Criollo
//
//  Created by Cătălin Stan on 10/23/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#define CRSocketTagSendingResponse                      20
#define CRSocketTagSendingResponseHeaders               21
#define CRSocketTagSendingResponseBody                  22

#define CRSocketTagBeginReadingRequest                  10
#define CRSocketTagReadingRequestHeader                 11
#define CRSocketTagReadingRequestBody                   12

#define CRSocketTagFinishSendingResponse                90
#define CRSocketTagFinishSendingResponseAndClosing      91

@class GCDAsyncSocket, CRServer, CRRequest, CRResponse;

@interface CRConnection : NSObject

@property (nonatomic, weak) CRServer* server;
@property (nonatomic, strong) GCDAsyncSocket* socket;

@property (nonatomic, strong) CRRequest* request;
@property (nonatomic, strong) CRResponse* response;

@property (nonatomic, readonly) BOOL shouldClose;

+ (NSData*)CRLFData;
+ (NSData*)CRLFCRLFData;

- (instancetype)initWithSocket:(GCDAsyncSocket*)socket server:(CRServer*)server;
- (instancetype)initWithSocket:(GCDAsyncSocket*)socket server:(CRServer*)server delegateQueue:(dispatch_queue_t)delegateQueue NS_DESIGNATED_INITIALIZER;

- (void)startReading;

- (void)didReceiveCompleteRequestHeaders;
- (void)didReceiveRequestBody;
- (void)didReceiveCompleteRequest;

@end
