//
//  CRServer.h
//  Criollo
//
//  Created by Catalin Stan on 7/24/15.
//  Copyright (c) 2015 Cătălin Stan. All rights reserved.
//

#import "CRTypes.h"
#import "CRRouter.h"

#define CRServerErrorDomain                   @"CRServerErrorDomain"
#define CRServerSocketError                   2001

@class CRServer, CRServerConfiguration, GCDAsyncSocket, CRConnection, CRRequest, CRResponse, CRRoute;

NS_ASSUME_NONNULL_BEGIN

@protocol CRServerDelegate <NSObject>

@optional
- (void)serverWillStartListening:(CRServer *)server;
- (void)serverDidStartListening:(CRServer *)server;

- (void)serverWillStopListening:(CRServer *)server;
- (void)serverDidStopListening:(CRServer *)server;

- (void)server:(CRServer *)server didAcceptConnection:(CRConnection *)connection;
- (void)server:(CRServer  *)server didCloseConnection:(CRConnection *)connection;

- (void)server:(CRServer *)server didReceiveRequest:(CRRequest *)request;
- (void)server:(CRServer *)server didFinishRequest:(CRRequest *)request;

@end

@interface CRServer : CRRouter

@property (nonatomic, strong, nullable) id<CRServerDelegate> delegate;
@property (nonatomic, strong) CRRouteBlock notFoundBlock;
@property (nonatomic, strong, nullable) dispatch_queue_t delegateQueue;

- (instancetype)initWithDelegate:(id<CRServerDelegate> _Nullable)delegate;
- (instancetype)initWithDelegate:(id<CRServerDelegate> _Nullable)delegate delegateQueue:(dispatch_queue_t _Nullable)delegateQueue NS_DESIGNATED_INITIALIZER;

- (BOOL)startListening;
- (BOOL)startListening:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (BOOL)startListening:(NSError * _Nullable __autoreleasing * _Nullable)error portNumber:(NSUInteger)portNumber;
- (BOOL)startListening:(NSError * _Nullable __autoreleasing * _Nullable)error portNumber:(NSUInteger)portNumber interface:(NSString * _Nullable)interface;

- (void)stopListening;
- (void)closeAllConnections:(dispatch_block_t _Nullable)completion;

- (void)mountStaticDirectoryAtPath:(NSString *)directoryPath forPath:(NSString *)path;
- (void)mountStaticDirectoryAtPath:(NSString *)directoryPath forPath:(NSString *)path options:(CRStaticDirectoryServingOptions)options;

- (void)mountStaticFileAtPath:(NSString *)filePath forPath:(NSString *)path;
- (void)mountStaticFileAtPath:(NSString *)filePath forPath:(NSString *)path options:(CRStaticFileServingOptions)options;
- (void)mountStaticFileAtPath:(NSString *)filePath forPath:(NSString *)path options:(CRStaticFileServingOptions)options fileName:(NSString * _Nullable)fileName;
- (void)mountStaticFileAtPath:(NSString *)filePath forPath:(NSString *)path options:(CRStaticFileServingOptions)options fileName:(NSString * _Nullable)fileName contentType:(NSString * _Nullable)contentType;
- (void)mountStaticFileAtPath:(NSString *)filePath forPath:(NSString *)path options:(CRStaticFileServingOptions)options fileName:(NSString * _Nullable)fileName contentType:(NSString * _Nullable)contentType contentDisposition:(CRStaticFileContentDisposition)contentDisposition;

+ (CRRouteBlock)errorHandlingBlockWithStatus:(NSUInteger)statusCode error:(NSError * _Nullable)error;

@end
NS_ASSUME_NONNULL_END