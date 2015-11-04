//
//  CRRequest.m
//  Criollo
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "CRRequest.h"

@implementation CRRequest {
    NSMutableDictionary* _env;
}

- (instancetype)init {
    return [self initWithMethod:nil URL:nil version:nil env:nil];
}

- (instancetype)initWithMethod:(NSString *)method URL:(NSURL *)URL version:(NSString *)version {
    return [self initWithMethod:method URL:URL version:version env:nil];
}

- (instancetype)initWithMethod:(NSString *)method URL:(NSURL *)URL version:(NSString *)version env:(NSDictionary *)env {
    self = [super init];
    if ( self != nil ) {
        self.message = CFBridgingRelease( CFHTTPMessageCreateRequest(NULL, (__bridge CFStringRef)method, (__bridge CFURLRef)URL, (__bridge CFStringRef)version) );
        if ( env == nil ) {
            _env = [NSMutableDictionary dictionary];
        } else {
            [self setEnv:env];
        }
    }
    return self;
}

- (NSURL *)URL {
    return (__bridge_transfer NSURL *)CFHTTPMessageCopyRequestURL((__bridge CFHTTPMessageRef)self.message);
}

- (NSString *)method {
	return (__bridge_transfer NSString *)CFHTTPMessageCopyRequestMethod((__bridge CFHTTPMessageRef _Nonnull)(self.message));
}

- (NSDictionary<NSString *,NSString *> *)env {
    return _env;
}

- (void)setEnv:(NSDictionary<NSString *,NSString *> *)envDictionary {
    if ( [envDictionary isKindOfClass:[NSMutableDictionary class]] ) {
        _env = (NSMutableDictionary*)envDictionary;
    } else {
        _env = envDictionary.mutableCopy;
    }
}

- (void)setEnv:(NSString *)obj forKey:(NSString *)key {
    [_env setObject:obj forKey:key];
}

@end
