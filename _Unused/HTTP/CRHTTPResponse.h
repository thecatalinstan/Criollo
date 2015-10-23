//
//  CRHTTPResponse.h
//  Criollo
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Criollo/CRHTTPMessage.h>

@class CRHTTPConnection;

@interface CRHTTPResponse : CRHTTPMessage

@property (atomic, readonly) NSUInteger statusCode;
@property (nonatomic, assign) CRHTTPConnection* connection;

- (instancetype)initWithHTTPConnection:(CRHTTPConnection*)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode;
- (instancetype)initWithHTTPConnection:(CRHTTPConnection*)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description;
- (instancetype)initWithHTTPConnection:(CRHTTPConnection*)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description version:(NSString *)version;

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
