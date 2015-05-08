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
        self.message = CFHTTPMessageCreateEmpty(NULL, YES);
    }
    return self;
}

- (void)dealloc
{
    CFRelease(self.message);
}

- (NSString *)version
{
    return (__bridge_transfer NSString *)CFHTTPMessageCopyVersion(self.message);
}

- (NSData *)data
{
    return (__bridge_transfer NSData *)CFHTTPMessageCopySerializedMessage(self.message);
}

- (NSDictionary *)allHTTPHeaderFields
{
    return (__bridge_transfer NSDictionary *)CFHTTPMessageCopyAllHeaderFields(self.message);
}

- (NSString *)valueForHTTPHeaderField:(NSString *)HTTPHeaderField
{
    return (__bridge_transfer NSString *)CFHTTPMessageCopyHeaderFieldValue(self.message, (__bridge CFStringRef)HTTPHeaderField);
}

- (NSData *)body
{
    return (__bridge_transfer NSData *)CFHTTPMessageCopyBody(self.message);
}

- (void)setBody:(NSData *)body
{
    CFHTTPMessageSetBody(self.message, (__bridge CFDataRef)body);
}

@end
