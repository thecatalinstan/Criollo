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
@property (nonatomic, strong) NSMutableData* bufferedResponseData;

- (instancetype)initWithMethod:(NSString *)method URL:(NSURL *)URL version:(NSString *)version;
- (instancetype)initWithMethod:(NSString *)method URL:(NSURL *)URL version:(NSString *)version env:(NSDictionary*)env NS_DESIGNATED_INITIALIZER;

- (BOOL)appendData:(NSData *)data;

- (void)setEnv:(NSDictionary<NSString*,NSString*>*)envDictionary;
- (void)setEnv:(NSString*)obj forKey:(NSString*)key;

@end
