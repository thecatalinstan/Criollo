//
//  CRServer.h
//  Criollo
//
//  Created by Catalin Stan on 7/24/15.
//  Copyright (c) 2015 Cătălin Stan. All rights reserved.
//

#import "CRTypes.h"

@class CRServer, CRServerConfiguration, GCDAsyncSocket, CRConnection, CRRequest, CRResponse, CRRoute;

FOUNDATION_EXPORT NSUInteger const CRErrorSocketError;

@protocol CRServerDelegate <NSObject>

@optional

- (void)serverWillStartListening:(CRServer*)server;
- (void)serverDidStartListening:(CRServer*)server;

- (void)serverWillStopListening:(CRServer*)server;
- (void)serverDidStopListening:(CRServer*)server;

- (void)server:(CRServer*)server didAcceptConnection:(CRConnection*)connection;
- (void)server:(CRServer *)server didCloseConnection:(CRConnection*)connection;

- (void)server:(CRServer*)server didReceiveRequest:(CRRequest*)request;
- (void)server:(CRServer*)server didFinishRequest:(CRRequest*)request;

@end

@interface CRServer : NSObject

@property (nonatomic, strong) id<CRServerDelegate> delegate;

@property (nonatomic, strong) CRRouteBlock notFoundBlock;

- (instancetype)initWithDelegate:(id<CRServerDelegate>)delegate NS_DESIGNATED_INITIALIZER;

- (BOOL)startListening;
- (BOOL)startListening:(NSError**)error;
- (BOOL)startListening:(NSError**)error portNumber:(NSUInteger)portNumber;
- (BOOL)startListening:(NSError**)error portNumber:(NSUInteger)portNumber interface:(NSString*)interface;

- (void)stopListening;
- (void)closeAllConnections;

- (void)addBlock:(CRRouteBlock)block;
- (void)addBlock:(CRRouteBlock)block forPath:(NSString*)path;
- (void)addBlock:(CRRouteBlock)block forPath:(NSString*)path HTTPMethod:(NSString*)HTTPMethod;

@end
