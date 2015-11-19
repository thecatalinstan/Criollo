//
//  CRResponse.m
//  Criollo
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "CRResponse.h"
#import "CRApplication.h"
#import "CRServer.h"
#import "CRServerConfiguration.h"
#import "CRConnection.h"
#import "CRRequest.h"
#import "GCDAsyncSocket.h"
#import "NSDate+RFC1123.h"
#import "NSHTTPCookie+Criollo.h"

@interface CRResponse ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSHTTPCookie *> *HTTPCookies;

@end

@implementation CRResponse

- (instancetype)init {
    return [self initWithConnection:nil HTTPStatusCode:200 description:nil version:nil];
}

- (instancetype)initWithConnection:(CRConnection*)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode {
    return [self initWithConnection:connection HTTPStatusCode:HTTPStatusCode description:nil version:nil];
}

- (instancetype)initWithConnection:(CRConnection*)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description {
    return [self initWithConnection:connection HTTPStatusCode:HTTPStatusCode description:description version:nil];
}

- (instancetype)initWithConnection:(CRConnection*)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description version:(NSString *)version {
    self  = [super init];
    if ( self != nil ) {
        version = version == nil ? CRHTTP11 : version;
        self.message = CFBridgingRelease(CFHTTPMessageCreateResponse(NULL, (CFIndex)HTTPStatusCode, (__bridge CFStringRef)description, (__bridge CFStringRef) version));
        self.connection = connection;
        self.HTTPCookies = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSUInteger)statusCode {
    return (NSUInteger)CFHTTPMessageGetResponseStatusCode((__bridge CFHTTPMessageRef _Nonnull)(self.message));
}

- (void)setAllHTTPHeaderFields:(NSDictionary<NSString *, NSString *> *)headerFields
{
    [headerFields enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ( [key isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]] ) {
            [self setValue:obj forHTTPHeaderField:key];
        }
    }];
}

- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)HTTPHeaderField {
    NSString *headerValue = [self valueForHTTPHeaderField:HTTPHeaderField];
    if ( headerValue == nil ) {
        headerValue = @"";
    }
    headerValue = [headerValue stringByAppendingFormat:@", %@", value];
    [self setValue:headerValue forHTTPHeaderField:HTTPHeaderField];
}

- (void)setValue:(NSString*)value forHTTPHeaderField:(NSString *)HTTPHeaderField {
    CFHTTPMessageSetHeaderFieldValue((__bridge CFHTTPMessageRef _Nonnull)(self.message), (__bridge CFStringRef)HTTPHeaderField, (__bridge CFStringRef)value);
}

#pragma mark - Cookies

- (void)setCookie:(NSHTTPCookie *)cookie {
    if ( cookie != nil ) {
        self.HTTPCookies[cookie.name] = cookie;
    }
}

- (NSHTTPCookie *)setCookie:(NSString*)name value:(NSString*)value path:(NSString*)path expires:(NSDate*)expires domain:(NSString*)domain secure:(BOOL)secure {
    NSMutableDictionary* cookieProperties = [[NSMutableDictionary alloc] init];
    cookieProperties[NSHTTPCookieName] = name;
    cookieProperties[NSHTTPCookieValue] = value;

    if ( expires != nil ) {
        cookieProperties[NSHTTPCookieExpires] = expires;
    } else {
        cookieProperties[NSHTTPCookieDiscard] = @"TRUE";
    }

    if ( path != nil ) {
        cookieProperties[NSHTTPCookiePath] = path;
    }

    if ( domain != nil ) {
        cookieProperties[NSHTTPCookieDomain] = domain;
    } else {
        cookieProperties[NSHTTPCookieOriginURL] = self.request.URL;        
    }

    if ( secure ) {
        cookieProperties[NSHTTPCookieSecure] = @"TRUE";
    }

    NSHTTPCookie* cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
    [self setCookie:cookie];

    return cookie;
}

#pragma mark - Write

- (void)writeData:(NSData*)data {
    [self writeData:data finish:NO];
}

- (void)sendData:(NSData*)data {
    [self writeData:data finish:YES];
}

- (void)writeString:(NSString*)string {
    [self writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)sendString:(NSString*)string {
    [self sendData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)writeFormat:(NSString*)format, ... {
    va_list args;
    va_start(args, format);
    [self writeFormat:format args:args];
    va_end(args);
}

- (void)writeFormat:(NSString *)format args:(va_list)args {
    NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    [self writeString:formattedString];
}

- (void)sendFormat:(NSString*)format, ... {
    va_list args;
    va_start(args, format);
    [self sendFormat:format args:args];
    va_end(args);
}

- (void)sendFormat:(NSString *)format args:(va_list)args {
    NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    [self sendString:formattedString];
}

- (void)writeData:(NSData *)data finish:(BOOL)flag {
    if ( flag ) {
        _finished = YES;
    }
    [self.connection sendDataToSocket:data forRequest:self.request];
}

- (void)buildHeaders {
    // Add the cookie headers
    NSDictionary * cookieHeaders = [NSHTTPCookie responseHeaderFieldsWithCookies:self.HTTPCookies.allValues];
    [self setAllHTTPHeaderFields:cookieHeaders];
}

- (void)finish {
    _finished = YES;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %lu %@ %@", self.version, (unsigned long)self.statusCode, self.allHTTPHeaderFields[@"Content-type"], self.allHTTPHeaderFields[@"Content-length"]];
}

@end
