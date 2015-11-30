//
//  CRRequest_Internal.h
//  Criollo
//
//  Created by Cătălin Stan on 11/20/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRRequest.h"

@interface CRRequest ()

@property (nonatomic, readonly) BOOL shouldCloseConnection;
@property (nonatomic, strong, nullable) NSMutableData* bufferedResponseData;

- (nonnull instancetype)initWithMethod:(nullable NSString *)method URL:(nullable NSURL *)URL version:(nullable NSString *)version;
- (nonnull instancetype)initWithMethod:(nullable NSString *)method URL:(nullable NSURL *)URL version:(nullable NSString *)version env:(nullable NSDictionary*)env NS_DESIGNATED_INITIALIZER;

- (BOOL)appendData:(nonnull NSData *)data;

- (void)setEnv:(nonnull NSDictionary<NSString*,NSString*>*)envDictionary;
- (void)setEnv:(nonnull NSString*)obj forKey:(nonnull NSString*)key;

@end
