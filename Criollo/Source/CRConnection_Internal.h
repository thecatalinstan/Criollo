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

@property (nonatomic, strong, nonnull) GCDAsyncSocket* socket;
@property (nonatomic, weak) CRServer* server;

@property (nonatomic, strong, nonnull) NSMutableArray<CRRequest*>* requests;

@property (nonatomic, strong, nullable) CRRequest* currentRequest;

+ (nonnull NSData *)CRLFData;
+ (nonnull NSData *)CRLFCRLFData;

- (nonnull instancetype)initWithSocket:(nullable GCDAsyncSocket*)socket server:(nullable CRServer*)server NS_DESIGNATED_INITIALIZER;

- (nonnull CRResponse *)responseWithHTTPStatusCode:(NSUInteger)HTTPStatusCode;
- (nonnull CRResponse *)responseWithHTTPStatusCode:(NSUInteger)HTTPStatusCode description:(nullable NSString *)description;
- (nonnull CRResponse *)responseWithHTTPStatusCode:(NSUInteger)HTTPStatusCode description:(nullable NSString *)description version:(nullable NSString *)version;

- (void)startReading;
- (void)didReceiveCompleteRequestHeaders;
- (void)didReceiveRequestBody;
- (void)didReceiveCompleteRequest;
- (void)sendDataToSocket:(nonnull NSData *)data forRequest:(nonnull CRRequest *)request;
- (void)didFinishResponseForRequest:(nonnull CRRequest *)request;

@end
