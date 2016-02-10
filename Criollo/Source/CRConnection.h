//
//  CRConnection.h
//  Criollo
//
//  Created by Cătălin Stan on 10/23/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

@class CRConnection, GCDAsyncSocket, CRServer, CRRequest, CRResponse;

@protocol CRConnectionDelegate <NSObject>

- (void)connection:(nonnull CRConnection *)connection didReceiveRequest:(nonnull CRRequest *)request response:(nonnull CRResponse *)response;
- (void)connection:(nonnull CRConnection *)connection didFinishRequest:(nonnull CRRequest *)request response:(nonnull CRResponse *)response;

@end

@interface CRConnection : NSObject

@property (nonatomic, weak, nullable) id<CRConnectionDelegate> delegate;

@property (nonatomic, readonly, nonnull) NSString* remoteAddress;
@property (nonatomic, readonly) NSUInteger remotePort;
@property (nonatomic, readonly, nonnull) NSString* localAddress;
@property (nonatomic, readonly) NSUInteger localPort;

@end
