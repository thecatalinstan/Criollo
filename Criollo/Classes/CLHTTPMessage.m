//
//  CLHTTPMessage.m
//  Criollo
//
//  Created by Cătălin Stan on 29/04/15.
//
//

#import "CLHTTPMessage.h"

@implementation CLHTTPMessage

- (instancetype)init
{
    self = [super init];
    if ( self != nil ) {
        _message = CFHTTPMessageCreateEmpty(NULL, YES);
    }
    return self;
}

- (void)dealloc
{
    if (_message) {
        CFRelease(_message);
    }
}

- (NSURL *)URL
{
    return (__bridge_transfer NSURL *)CFHTTPMessageCopyRequestURL(_message);
}

- (NSString *)version
{
    return (__bridge_transfer NSString *)CFHTTPMessageCopyVersion(_message);
}

- (NSData *)data
{
    return (__bridge_transfer NSData *)CFHTTPMessageCopySerializedMessage(_message);
}

- (NSDictionary *)allHTTPHeaderFields
{
    return (__bridge_transfer NSDictionary *)CFHTTPMessageCopyAllHeaderFields(_message);
}

- (NSString *)valueForHTTPHeaderField:(NSString *)HTTPHeaderField
{
    return (__bridge_transfer NSString *)CFHTTPMessageCopyHeaderFieldValue(_message, (__bridge CFStringRef)HTTPHeaderField);
}

- (void)setValue:(NSString*)value forHTTPHeaderField:(NSString *)HTTPHeaderField
{
    CFHTTPMessageSetHeaderFieldValue(_message, (__bridge CFStringRef)HTTPHeaderField, (__bridge CFStringRef)value);
}

- (NSData *)body
{
    return (__bridge_transfer NSData *)CFHTTPMessageCopyBody(_message);
}

- (void)setBody:(NSData *)body
{
    CFHTTPMessageSetBody(_message, (__bridge CFDataRef)body);
}

@end
