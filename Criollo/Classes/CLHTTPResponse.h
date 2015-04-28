//
//  CLHTTPResponse.h
//  Criollo
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLHTTPRequest, FCGIRequest;

@interface CLHTTPResponse : NSObject {
    CLHTTPRequest* _HTTPRequest;

    NSMutableDictionary* HTTPHeaders;
    NSMutableDictionary* HTTPCookies;

    BOOL _headersAlreadySent;
    NSUInteger _HTTPStatus;
    
    BOOL _isRedirecting;
}

@property (nonatomic, retain) CLHTTPRequest* HTTPRequest;
@property (atomic, readonly) BOOL headersAlreadySent;
@property (atomic, assign) NSUInteger HTTPStatus;
@property (atomic, readonly) BOOL isRedirecting;

- (instancetype)initWithHTTPRequest:(CLHTTPRequest*)anHTTPRequest;
+ (instancetype)responseWithHTTPRequest:(CLHTTPRequest*)anHTTPRequest;

- (void)write:(NSData*)data;
- (void)writeString:(NSString*)format, ...;

- (void)log:(NSData*)data;
- (void)logString:(NSString*)format, ...;

@property (nonatomic, copy) NSDictionary *allHTTPHeaderFields;

- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field;
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

- (void)setCookie:(NSHTTPCookie*)cookie;
- (void)setCookie:(NSString*)name value:(NSString*)value expires:(NSDate*)expires path:(NSString*)path domain:(NSString*)domain secure:(BOOL)secure;

- (void)redirectToLocation:(NSString *)location withStatus:(NSUInteger)redirectStatus;

- (void)finish;

@end
