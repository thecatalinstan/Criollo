//
//  CLHTTPResponse.h
//  Criollo
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Criollo/CLHTTPMessage.h>

@class CLHTTPConnection;

@interface CLHTTPResponse : CLHTTPMessage

@property (atomic, readonly) NSUInteger statusCode;
@property (nonatomic, assign) CLHTTPConnection* connection;

- (instancetype)initWithHTTPConnection:(CLHTTPConnection*)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode;
- (instancetype)initWithHTTPConnection:(CLHTTPConnection*)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description;
- (instancetype)initWithHTTPConnection:(CLHTTPConnection*)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description version:(NSString *)version NS_DESIGNATED_INITIALIZER;

- (void)setValue:(NSString*)value forHTTPHeaderField:(NSString *)HTTPHeaderField;

- (void)writeData:(NSData*)data;
- (void)sendData:(NSData*)data;

- (void)writeString:(NSString*)string;
- (void)sendString:(NSString*)string;

- (void)writeFormat:(NSString*)format, ...;
- (void)sendFormat:(NSString*)format, ...;

- (void)finish;
- (void)end;

@end
