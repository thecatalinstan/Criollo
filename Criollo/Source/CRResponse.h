//
//  CRResponse.h
//  Criollo
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "CRMessage.h"

// Initial size of the response body data
#define CRResponseDataInitialCapacity       1024

@class CRRequest, CRConnection;

@interface CRResponse : CRMessage

@property (nonatomic, weak) CRConnection *connection;
@property (nonatomic, weak) CRRequest *request;

@property (nonatomic, readonly) NSUInteger statusCode;
@property (nonatomic, strong, readonly, nullable) NSString* statusDescription;

- (void)setStatusCode:(NSUInteger)statusCode description:(nullable NSString *)description;

- (void)setAllHTTPHeaderFields:(nonnull NSDictionary<NSString *, NSString *> *)headerFields;
- (void)addValue:(nonnull NSString *)value forHTTPHeaderField:(nonnull NSString *)HTTPHeaderField;
- (void)setValue:(nonnull NSString *)value forHTTPHeaderField:(nonnull NSString *)HTTPHeaderField;

- (void)setCookie:(nonnull NSHTTPCookie *)cookie;
- (nonnull NSHTTPCookie*)setCookie:(nonnull NSString *)name value:(nonnull NSString *)value path:(nonnull NSString *)path expires:(nullable NSDate *)expires domain:(nullable NSString *)domain secure:(BOOL)secure;

- (void)writeData:(nonnull NSData *)data;
- (void)sendData:(nonnull NSData *)data;

- (void)writeString:(nonnull NSString *)string;
- (void)sendString:(nonnull NSString *)string;

- (void)writeFormat:(nonnull NSString *)format, ...;
- (void)sendFormat:(nonnull NSString *)format, ...;

NS_ASSUME_NONNULL_BEGIN
- (void)writeFormat:(nonnull NSString *)format args:(va_list)args;
- (void)sendFormat:(nonnull NSString *)format args:(va_list)args;
NS_ASSUME_NONNULL_END

- (void)finish;

@end
