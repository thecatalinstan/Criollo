//
//  CRConnection.h
//
//
//  Created by Cătălin Stan on 10/23/15.
//

#import <Criollo/CRTypes.h>
#import <Foundation/Foundation.h>

@class CRConnection, GCDAsyncSocket, CRServer, CRRequest, CRResponse;

NS_ASSUME_NONNULL_BEGIN

// TODO: Remove inheritance from NSObject
@protocol CRConnectionDelegate <NSObject>

- (void)connection:(CRConnection *)connection didReceiveRequest:(CRRequest *)request response:(CRResponse *)response;
- (void)connection:(CRConnection *)connection didFinishRequest:(CRRequest *)request response:(CRResponse *)response;

@end

@interface CRConnection : NSObject

@property (nonatomic, readonly) NSString* remoteAddress;
@property (nonatomic, readonly) NSUInteger remotePort;
@property (nonatomic, readonly) NSString* localAddress;
@property (nonatomic, readonly) NSUInteger localPort;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
