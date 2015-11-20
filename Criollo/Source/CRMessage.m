//
//  CRMessage.m
//  Criollo
//
//  Created by Cătălin Stan on 29/04/15.
//
//

#import "CRMessage.h"
#import "CRMessage_Internal.h"

@implementation CRMessage

- (instancetype)init {
    self = [super init];
    if ( self != nil ) {
        self.message = CFBridgingRelease( CFHTTPMessageCreateEmpty(NULL, YES) );
    }
    return self;
}

- (void)dealloc {
}

- (NSString *)version {
    return (__bridge_transfer NSString *)CFHTTPMessageCopyVersion((__bridge CFHTTPMessageRef _Nonnull)(self.message));
}

- (NSData *)serializedData {
    return (__bridge_transfer NSData *)CFHTTPMessageCopySerializedMessage((__bridge CFHTTPMessageRef _Nonnull)(self.message));
}

- (NSDictionary<NSString*, NSString*> *)allHTTPHeaderFields {
    return (__bridge_transfer NSDictionary *)CFHTTPMessageCopyAllHeaderFields((__bridge CFHTTPMessageRef _Nonnull)(self.message));
}

- (NSString *)valueForHTTPHeaderField:(NSString *)HTTPHeaderField {
    return (__bridge_transfer NSString *)CFHTTPMessageCopyHeaderFieldValue((__bridge CFHTTPMessageRef _Nonnull)(self.message), (__bridge CFStringRef)HTTPHeaderField);
}

- (NSData *)body {
    return (__bridge_transfer NSData *)CFHTTPMessageCopyBody((__bridge CFHTTPMessageRef _Nonnull)(self.message));
}

- (void)setBody:(NSData *)body {
    CFHTTPMessageSetBody((__bridge CFHTTPMessageRef _Nonnull)(self.message), (__bridge CFDataRef)body);
}

- (BOOL)headersComplete {
    return CFHTTPMessageIsHeaderComplete((__bridge CFHTTPMessageRef _Nonnull)(self.message));
}

@end
