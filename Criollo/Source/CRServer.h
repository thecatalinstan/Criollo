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
- (BOOL)startListening:(NSError * __nullable __autoreleasing * __nullable)error;
- (BOOL)startListening:(NSError * __nullable __autoreleasing * __nullable)error portNumber:(NSUInteger)portNumber;
- (BOOL)startListening:(NSError * __nullable __autoreleasing * __nullable)error portNumber:(NSUInteger)portNumber interface:(nullable NSString *)interface;

- (void)stopListening;
- (void)closeAllConnections;

- (void)addBlock:(nonnull CRRouteBlock)block;

- (void)addBlock:(nonnull CRRouteBlock)block forPath:(nullable NSString*)path;
- (void)addBlock:(nonnull CRRouteBlock)block forPath:(nullable NSString*)path HTTPMethod:(nullable NSString*)HTTPMethod;

- (void)addController:(nonnull __unsafe_unretained Class)controllerClass withNibName:(nullable NSString*)nibNameOrNil bundle:(nullable NSBundle*)nibBundleOrNil forPath:(nonnull NSString*)path;
- (void)addController:(nonnull __unsafe_unretained Class)controllerClass withNibName:(nullable NSString*)nibNameOrNil bundle:(nullable NSBundle*)nibBundleOrNil forPath:(nonnull NSString*)path HTTPMethod:(nullable NSString*)HTTPMethod;

@end
