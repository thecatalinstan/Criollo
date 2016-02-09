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

- (void)serverWillStartListening:(nonnull CRServer *)server;
- (void)serverDidStartListening:(nonnull CRServer *)server;

- (void)serverWillStopListening:(nonnull CRServer *)server;
- (void)serverDidStopListening:(nonnull CRServer *)server;

- (void)server:(nonnull CRServer *)server didAcceptConnection:(nonnull CRConnection *)connection;
- (void)server:(nonnull CRServer  *)server didCloseConnection:(nonnull CRConnection *)connection;

- (void)server:(nonnull CRServer *)server didReceiveRequest:(nonnull CRRequest *)request;
- (void)server:(nonnull CRServer *)server didFinishRequest:(nonnull CRRequest *)request;

@end

@interface CRServer : NSObject

@property (nonatomic, strong, nullable) id<CRServerDelegate> delegate;

@property (nonatomic, strong, nonnull) CRRouteBlock notFoundBlock;

- (nonnull instancetype)initWithDelegate:(nullable id<CRServerDelegate>)delegate NS_DESIGNATED_INITIALIZER;

- (BOOL)startListening;
- (BOOL)startListening:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (BOOL)startListening:(NSError * _Nullable __autoreleasing * _Nullable)error portNumber:(NSUInteger)portNumber;
- (BOOL)startListening:(NSError * _Nullable __autoreleasing * _Nullable)error portNumber:(NSUInteger)portNumber interface:(NSString * _Nullable)interface;

- (void)stopListening;
- (void)closeAllConnections;

- (void)addBlock:(CRRouteBlock _Nonnull)block;
- (void)addBlock:(CRRouteBlock _Nonnull)block forPath:(NSString * _Nullable)path;
- (void)addBlock:(CRRouteBlock _Nonnull)block forPath:(NSString * _Nullable)path HTTPMethod:(NSString * _Nullable)HTTPMethod;

- (void)addController:(__unsafe_unretained Class _Nonnull)controllerClass withNibName:(NSString * _Nullable)nibNameOrNil bundle:(NSBundle * _Nullable)nibBundleOrNil forPath:(NSString * _Nonnull)path;
- (void)addController:(__unsafe_unretained Class _Nonnull)controllerClass withNibName:(NSString * _Nullable)nibNameOrNil bundle:(NSBundle * _Nullable)nibBundleOrNil forPath:(NSString * _Nonnull)path HTTPMethod:(NSString * _Nullable)HTTPMethod;

- (void)addStaticDirectory:(NSString * _Nonnull)directoryPath forPath:(NSString * _Nonnull)path;
- (void)addStaticDirectory:(NSString * _Nonnull)directoryPath forPath:(NSString * _Nonnull)path options:(CRStaticDirectoryServingOptions)options;

@end
