//
//  CRHTTPRequest.m
//  Criollo
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Criollo/CRHTTPMessage.h>

#import "CRHTTPRequest.h"

@implementation CRHTTPRequest

- (instancetype)initWithMethod:(NSString *)method URL:(NSURL *)URL version:(NSString *)version
{
    self = [super init];
    if ( self != nil ) {
        self.message = CFBridgingRelease( CFHTTPMessageCreateRequest(NULL, (__bridge CFStringRef)method, (__bridge CFURLRef)URL, (__bridge CFStringRef)version) );
    }
    return self;
}

- (NSURL *)URL
{
    return (__bridge_transfer NSURL *)CFHTTPMessageCopyRequestURL((__bridge CFHTTPMessageRef)self.message);
}

- (BOOL)appendData:(NSData *)data
{
    return CFHTTPMessageAppendBytes((__bridge CFHTTPMessageRef)self.message, data.bytes, data.length);
}

- (BOOL)headerComplete
{
    return CFHTTPMessageIsHeaderComplete((__bridge CFHTTPMessageRef _Nonnull)(self.message));
}

- (NSString *)method
{
	return (__bridge_transfer NSString *)CFHTTPMessageCopyRequestMethod((__bridge CFHTTPMessageRef _Nonnull)(self.message));
}

@end
