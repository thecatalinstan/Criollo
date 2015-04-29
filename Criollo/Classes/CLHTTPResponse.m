//
//  CLHTTPResponse.m
//  Criollo
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Criollo/CLHTTPMessage.h>

#import "CLHTTPResponse.h"

@implementation CLHTTPResponse

- (instancetype)initWithHTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description version:(NSString *)version
{
    self  = [super init];
    if ( self != nil ) {
        self.message = CFHTTPMessageCreateResponse(NULL, (CFIndex)HTTPStatusCode, (__bridge CFStringRef)description, (__bridge CFStringRef)version);
    }
    return self;
}

- (NSUInteger)statusCode
{
    return (NSUInteger)CFHTTPMessageGetResponseStatusCode(self.message);
}

@end
