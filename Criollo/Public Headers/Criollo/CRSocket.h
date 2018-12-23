//
//  CRSocket.h
//  Criollo macOS
//
//  Created by Cătălin Stan on 19/12/2018.
//  Copyright © 2018 Cătălin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>


#define CRSocketErrorDomain         @"CRSocketErrorDomain"

#define CRUnableToResolveAddress    5001


NS_ASSUME_NONNULL_BEGIN

@class CRSocket;

@protocol CRSocketDelegate <NSObject>

@optional

/**
 Called when a listening socket has accepted a new connection.

 @param sock The listening `CRSocket` object accepting the connection.
 @param fd The file descriptor of the multiplexed socket
 @param sa The `struct sockaddr` that is filled in with the address of the connecting entity, as known to the communications layer.
 @param len Contains the actual length (in bytes) of the address returned.
 
 @see `accept(2)`
 */
- (void)socket:(CRSocket *)sock didAccept:(int)fd addr:(struct sockaddr *)sa len:(socklen_t)len;

/**
 Called when a socket has closed a multiplexed file descriptor

 @param sock The listening `CRSocket` object accepting the connection.
 @param fd  The file descriptor of the multiplexed socket
 */
- (void)socket:(CRSocket *)sock didDisconnect:(int)fd;

@required

/**
 Called when data has become available on a multiplexed descriptor of a scoket.

 @param sock The listening `CRSocket` object owning the connection.
 @param buf A pointer to the buffer conaining the data.
 @param len The length (in bytes) of the data read.
 @param fd The file descriptor of the multiplexed socket that has read the data.
 */
- (void)socket:(CRSocket *)sock didReadData:(const void *)buf size:(size_t)len descriptor:(int)fd;

@end

@interface CRSocket : NSObject

@property (nonatomic, strong, readonly) id<CRSocketDelegate> delegate;

- (instancetype)initWithDelegate:(id<CRSocketDelegate> _Nullable)delegate delegateQueue:(dispatch_queue_t _Nullable)delegateQueue;

- (BOOL)listen:(NSString * _Nullable)interface port:(NSUInteger)port error:(NSError * __autoreleasing *)error;

+ (BOOL)getSocketAddr:(struct sockaddr *)sa address:(NSString * __autoreleasing * _Nonnull)address port:(NSUInteger * _Nonnull)port error:(NSError * _Nonnull __autoreleasing * _Nonnull)error;
@end

NS_ASSUME_NONNULL_END
