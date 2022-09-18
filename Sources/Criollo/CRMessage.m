//
//  CRMessage.m
//
//
//  Created by Cătălin Stan on 29/04/15.
//
//

#import "CRMessage_Internal.h"

@implementation CRMessage

static const NSHashTable<CRHTTPMethod> *acceptedHTTPMethods;

+ (void)initialize {
    acceptedHTTPMethods = [NSHashTable weakObjectsHashTable];
    [acceptedHTTPMethods addObject:CRHTTPMethodGet];
    [acceptedHTTPMethods addObject:CRHTTPMethodHead];
    [acceptedHTTPMethods addObject:CRHTTPMethodPost];
    [acceptedHTTPMethods addObject:CRHTTPMethodPut];
    [acceptedHTTPMethods addObject:CRHTTPMethodDelete];
    [acceptedHTTPMethods addObject:CRHTTPMethodConnect];
    [acceptedHTTPMethods addObject:CRHTTPMethodOptions];
    [acceptedHTTPMethods addObject:CRHTTPMethodPatch];
}

+ (const NSHashTable<CRHTTPMethod> *)acceptedHTTPMethods {
    return acceptedHTTPMethods;
}

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        _message = CFBridgingRelease(CFHTTPMessageCreateEmpty(NULL, YES));
    }
    return self;
}

- (CRHTTPVersion)version {
    return CRHTTPVersionFromString((__bridge_transfer NSString *)CFHTTPMessageCopyVersion((__bridge CFHTTPMessageRef)self.message));
}

- (NSData *)serializedData {
    return (__bridge_transfer NSData *)CFHTTPMessageCopySerializedMessage((__bridge CFHTTPMessageRef)self.message);
}

- (NSDictionary<NSString*, NSString*> *)allHTTPHeaderFields {
    return (__bridge_transfer NSDictionary *)CFHTTPMessageCopyAllHeaderFields((__bridge CFHTTPMessageRef)self.message);
}

- (NSString *)valueForHTTPHeaderField:(NSString *)HTTPHeaderField {
    return (__bridge_transfer NSString *)CFHTTPMessageCopyHeaderFieldValue((__bridge CFHTTPMessageRef)self.message, (__bridge CFStringRef)HTTPHeaderField);
}

- (NSData *)bodyData {
    return (__bridge_transfer NSData *)CFHTTPMessageCopyBody((__bridge CFHTTPMessageRef)self.message);
}

- (void)setBodyData:(NSData *)bodyData {
    CFHTTPMessageSetBody((__bridge CFHTTPMessageRef)self.message, (__bridge CFDataRef)bodyData);
}

- (BOOL)headersComplete {
    return CFHTTPMessageIsHeaderComplete((__bridge CFHTTPMessageRef)self.message);
}

@end
