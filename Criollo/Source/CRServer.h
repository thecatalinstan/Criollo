//
//  CRServer.h
//  Criollo
//
//  Created by Catalin Stan on 7/24/15.
//  Copyright (c) 2015 Cătălin Stan. All rights reserved.
//

@class CRServer, CRServerConfiguration, GCDAsyncSocket, CRConnection, CRRequest, CRResponse;

FOUNDATION_EXPORT NSUInteger const CRErrorSocketError;

FOUNDATION_EXPORT NSString* const CRRequestKey;
FOUNDATION_EXPORT NSString* const CRResponseKey;

typedef void(^CRServerOperationBlock)(CRRequest* request, CRResponse* response);

@protocol CRServerDelegate <NSObject>

@optional

- (void)serverWillStartListening:(CRServer*)server;
- (void)serverDidStartListening:(CRServer*)server;

- (void)serverWillStopListening:(CRServer*)server;
- (void)serverDidStopListening:(CRServer*)server;

- (void)server:(CRServer*)server didAcceptConnection:(CRConnection*)connection;
- (void)server:(CRServer*)server didCloseConnection:(CRConnection*)connection;

@end

@interface CRServer : NSObject

@property (nonatomic, strong) id<CRServerDelegate> delegate;
@property (nonatomic, strong) CRServerConfiguration* configuration;
@property (nonatomic, strong) GCDAsyncSocket* socket;
@property (nonatomic, strong) NSMutableArray<CRConnection*>* connections;

- (instancetype)initWithDelegate:(id<CRServerDelegate>)delegate NS_DESIGNATED_INITIALIZER;

- (BOOL)startListening;
- (BOOL)startListening:(NSError**)error;
- (BOOL)startListeningOnPortNumber:(NSUInteger)portNumber error:(NSError**)error;
- (BOOL)startListeningOnPortNumber:(NSUInteger)portNumber interface:(NSString*)interface error:(NSError**)error;
- (void)stopListening;
- (void)closeAllConnections;

- (CRConnection*)newConnectionWithSocket:(GCDAsyncSocket*)socket;
- (void)didCloseConnection:(CRConnection*)connection;

- (BOOL)canHandleHTTPMethod:(NSString*)HTTPMethod forPath:(NSString*)path;

@end
