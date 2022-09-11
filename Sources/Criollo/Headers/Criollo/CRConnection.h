//
//  CRConnection.h
//
//
//  Created by Cătălin Stan on 10/23/15.
//

#import <Foundation/Foundation.h>

@class CRConnection, CRRequest, CRResponse;

NS_ASSUME_NONNULL_BEGIN

@protocol CRConnectionDelegate

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
