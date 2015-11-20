//
//  CRConnection_Internal.h
//  Criollo
//
//  Created by Cătălin Stan on 11/20/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRConnection.h"

@class GCDAsyncSocket, CRServer, CRRequest;

@interface CRConnection ()

@property (nonatomic, strong) GCDAsyncSocket* socket;
@property (nonatomic, weak) CRServer* server;

@property (nonatomic, strong) NSMutableArray<CRRequest*>* requests;

@property (nonatomic, strong) CRRequest* currentRequest;

+ (NSData*)CRLFData;
+ (NSData*)CRLFCRLFData;

- (instancetype)initWithSocket:(GCDAsyncSocket*)socket server:(CRServer*)server NS_DESIGNATED_INITIALIZER;

- (CRResponse*)responseWithHTTPStatusCode:(NSUInteger)HTTPStatusCode;
- (CRResponse*)responseWithHTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description;
- (CRResponse*)responseWithHTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description version:(NSString *)version;

- (void)startReading;
- (void)didReceiveCompleteRequestHeaders;
- (void)didReceiveRequestBody;
- (void)didReceiveCompleteRequest;
- (void)sendDataToSocket:(NSData*)data forRequest:(CRRequest*)request;
- (void)didFinishResponseForRequest:(CRRequest*)request;

@end
