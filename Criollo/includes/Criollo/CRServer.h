//
//  CRServer.h
//  Criollo
//
//  Created by Catalin Stan on 7/24/15.
//  Copyright (c) 2015 Cătălin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Criollo/CRRouter.h>
#import <Criollo/CRTypes.h>

@class CRServer, CRServerConfiguration, GCDAsyncSocket, CRConnection, CRRequest, CRResponse, CRRoute;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const CRServerErrorDomain;

NS_ERROR_ENUM(CRServerErrorDomain) {
    CRServerSocketError = 2001,
};

// TODO: Remove inheritance from NSObject
@protocol CRServerDelegate <NSObject>

@optional

- (void)serverWillStartListening:(CRServer *)server;
- (void)serverDidStartListening:(CRServer *)server;

- (void)serverWillStopListening:(CRServer *)server;
- (void)serverDidStopListening:(CRServer *)server;

- (void)server:(CRServer *)server didAcceptConnection:(CRConnection *)connection;
- (void)server:(CRServer *)server didCloseConnection:(CRConnection *)connection;

- (void)server:(CRServer *)server didReceiveRequest:(CRRequest *)request;
- (void)server:(CRServer *)server didFinishRequest:(CRRequest *)request;

@end

@interface CRServer : CRRouter

@property (nonatomic, readonly) BOOL isListening;

@property (nonatomic, weak, nullable) id<CRServerDelegate> delegate;
@property (nonatomic, strong, nullable) dispatch_queue_t delegateQueue;

@property (nonatomic, strong, nullable) NSOperationQueue *workerQueue;

- (instancetype)initWithDelegate:(id<CRServerDelegate> _Nullable)delegate;
- (instancetype)initWithDelegate:(id<CRServerDelegate> _Nullable)delegate delegateQueue:(dispatch_queue_t _Nullable)delegateQueue NS_DESIGNATED_INITIALIZER;

// TODO: Move error param to the end
- (BOOL)startListening;
- (BOOL)startListening:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (BOOL)startListening:(NSError * _Nullable __autoreleasing * _Nullable)error portNumber:(NSUInteger)portNumber;
- (BOOL)startListening:(NSError * _Nullable __autoreleasing * _Nullable)error portNumber:(NSUInteger)portNumber interface:(NSString * _Nullable)interface;

- (void)stopListening;
- (void)closeAllConnections:(dispatch_block_t _Nullable)completion;

@end

NS_ASSUME_NONNULL_END
