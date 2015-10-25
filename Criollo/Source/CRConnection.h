//
//  CRConnection.h
//  Criollo
//
//  Created by Cătălin Stan on 10/23/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

@class GCDAsyncSocket, CRServer;

@interface CRConnection : NSObject

@property (nonatomic, weak) CRServer* server;
@property (nonatomic, strong) GCDAsyncSocket* socket;

+ (NSData*)CRLFData;
+ (NSData*)CRLFCRLFData;

- (instancetype)initWithSocket:(GCDAsyncSocket*)socket server:(CRServer*)server;
- (instancetype)initWithSocket:(GCDAsyncSocket*)socket server:(CRServer*)server delegateQueue:(dispatch_queue_t)delegateQueue NS_DESIGNATED_INITIALIZER;

- (void)startReading;

@end
