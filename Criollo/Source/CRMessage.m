//
//  CRMessage.m
//  Criollo
//
//  Created by Cătălin Stan on 29/04/15.
//
//

#import "CRMessage.h"
#import "CRMessage_Internal.h"

NSString * const CRHTTPMethodGetValue = @"GET";
NSString * const CRHTTPMethodPostValue = @"POST";
NSString * const CRHTTPMethodPutValue = @"PUT";
NSString * const CRHTTPMethodDeleteValue = @"DELETE";
NSString * const CRHTTPMethodPatchValue = @"PATCH";
NSString * const CRHTTPMethodOptionsValue = @"OPTIONS";

NSString * NSStringFromCRHTTPMethod(CRHTTPMethod HTTPMethod) {
    switch (HTTPMethod) {
        case CRHTTPMethodGet:
            return CRHTTPMethodGetValue;
        case CRHTTPMethodPost:
            return CRHTTPMethodPostValue;
        case CRHTTPMethodPut:
            return CRHTTPMethodPutValue;
        case CRHTTPMethodDelete:
            return CRHTTPMethodDeleteValue;
        case CRHTTPMethodPatch:
            return CRHTTPMethodPatchValue;
        case CRHTTPMethodOptions:
            return CRHTTPMethodOptionsValue;
    }
}

CRHTTPMethod CRHTTMethodMake(NSString * HTTPMethodName) {
    CRHTTPMethod HTTPMethod;
    if ( [HTTPMethodName isEqualToString:CRHTTPMethodGetValue] ) {
        HTTPMethod = CRHTTPMethodGet;
    } else if ( [HTTPMethodName isEqualToString:CRHTTPMethodPostValue] ) {
        HTTPMethod = CRHTTPMethodPost;
    } else if ( [HTTPMethodName isEqualToString:CRHTTPMethodPutValue] ) {
        HTTPMethod = CRHTTPMethodPut;
    } else if ( [HTTPMethodName isEqualToString:CRHTTPMethodDeleteValue] ) {
        HTTPMethod = CRHTTPMethodDelete;
    } else if ( [HTTPMethodName isEqualToString:CRHTTPMethodPatchValue] ) {
        HTTPMethod = CRHTTPMethodPatch;
    } else if ( [HTTPMethodName isEqualToString:CRHTTPMethodOptionsValue] ) {
        HTTPMethod = CRHTTPMethodOptions;
    }
    return HTTPMethod;
}


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

- (NSData *)bodyData {
    return (__bridge_transfer NSData *)CFHTTPMessageCopyBody((__bridge CFHTTPMessageRef _Nonnull)(self.message));
}

- (void)setBodyData:(NSData *)bodyData {
    CFHTTPMessageSetBody((__bridge CFHTTPMessageRef _Nonnull)(self.message), (__bridge CFDataRef)bodyData);
}

- (BOOL)headersComplete {
    return CFHTTPMessageIsHeaderComplete((__bridge CFHTTPMessageRef _Nonnull)(self.message));
}

@end
