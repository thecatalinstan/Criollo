//
//  CRRequest_Internal.h
//  Criollo
//
//  Created by Cătălin Stan on 11/20/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRRequest.h"

#define CRRequestHeaderSeparator            @";"
#define CRRequestKeySeparator               @"&"
#define CRRequestValueSeparator             @"="
#define CRRequestBoundaryParameter          @"boundary"
#define CRRequestBoundaryPrefix             @"--"

@class CRConnection;

@interface CRRequest ()

@property (nonatomic, readonly) BOOL shouldCloseConnection;

@property (nonatomic, weak) CRConnection *connection;

@property (nonatomic, strong, nullable) NSMutableData * bufferedRequestBodyData;
@property (nonatomic, strong, nullable) NSMutableData * bufferedResponseData;

@property (nonatomic, readonly, nullable) NSString * multipartBoundary;
@property (nonatomic, readonly, nonnull) NSData * multipartBoundaryPrefixData;
@property (nonatomic, readonly, nullable) NSString * multipartBoundaryPrefixedString;
@property (nonatomic, readonly, nullable) NSData * multipartBoundaryPrefixedData;

- (nonnull instancetype)initWithMethod:(nullable NSString *)method URL:(nullable NSURL *)URL version:(nullable NSString *)version;
- (nonnull instancetype)initWithMethod:(nullable NSString *)method URL:(nullable NSURL *)URL version:(nullable NSString *)version connection:(nullable CRConnection*) connection;
- (nonnull instancetype)initWithMethod:(nullable NSString *)method URL:(nullable NSURL *)URL version:(nullable NSString *)version connection:(nullable CRConnection*) connection env:(nullable NSDictionary*)env NS_DESIGNATED_INITIALIZER;

- (BOOL)appendData:(nonnull NSData *)data;

- (void)setEnv:(nonnull NSDictionary<NSString*,NSString*>*)envDictionary;
- (void)setEnv:(nonnull NSString*)obj forKey:(nonnull NSString*)key;

- (BOOL)parseJSONBodyData:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (BOOL)parseMultipartBodyDataChunk:(nonnull NSData *)data error:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (BOOL)parseURLEncodedBodyData:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (BOOL)parseBufferedBodyData:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end