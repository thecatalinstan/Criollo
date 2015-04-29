//
//  CLHTTPResponse.h
//  Criollo
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

@class CLHTTPMessage;

@interface CLHTTPResponse : CLHTTPMessage

@property (atomic, readonly) NSUInteger statusCode;

- (instancetype)initWithHTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description version:(NSString *)version;

@end
