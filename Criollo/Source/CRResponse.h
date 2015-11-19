//
//  CRResponse.h
//  Criollo
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "CRMessage.h"

@class CRRequest, CRConnection;

@interface CRResponse : CRMessage

@property (nonatomic, weak) CRRequest *request;

@property (nonatomic, readonly) NSUInteger statusCode;
@property (nonatomic, readonly) BOOL finished;
@property (nonatomic, weak) CRConnection *connection;

- (instancetype)initWithConnection:(CRConnection *)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode;
- (instancetype)initWithConnection:(CRConnection *)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description;
- (instancetype)initWithConnection:(CRConnection *)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description version:(NSString *)version NS_DESIGNATED_INITIALIZER;

- (void)setAllHTTPHeaderFields:(NSDictionary<NSString *, NSString *> *)headerFields;
- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)HTTPHeaderField;
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)HTTPHeaderField;

- (void)setCookie:(NSHTTPCookie *)cookie;
- (NSHTTPCookie*)setCookie:(NSString *)name value:(NSString *)value path:(NSString *)path expires:(NSDate *)expires domain:(NSString *)domain secure:(BOOL)secure;

- (void)writeData:(NSData*)data;
- (void)sendData:(NSData*)data;
- (void)writeData:(NSData*)data finish:(BOOL)flag;

- (void)writeString:(NSString*)string;
- (void)writeFormat:(NSString*)format, ...;
- (void)writeFormat:(NSString*)format args:(va_list)args;

- (void)sendString:(NSString*)string;
- (void)sendFormat:(NSString*)format, ...;
- (void)sendFormat:(NSString*)format args:(va_list)args;

- (void)buildHeaders;
- (void)finish;

@end
