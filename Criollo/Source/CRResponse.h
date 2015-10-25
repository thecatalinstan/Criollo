//
//  CRResponse.h
//  Criollo
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "CRMessage.h"

@class CRConnection;

@interface CRResponse : CRMessage

@property (atomic, readonly) NSUInteger statusCode;
@property (nonatomic, assign) CRConnection* connection;

- (instancetype)initWithHTTPConnection:(CRConnection*)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode;
- (instancetype)initWithHTTPConnection:(CRConnection*)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description;
- (instancetype)initWithHTTPConnection:(CRConnection*)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description version:(NSString *)version;

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
