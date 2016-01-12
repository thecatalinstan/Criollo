//
//  CRRequest.m
//  Criollo
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "CRMessage_Internal.h"
#import "CRRequest.h"
#import "CRRequest_Internal.h"

#define CRRequestBoundaryParameter          @"boundary"
#define CRRequestBoundaryPrefix             @"--"

@implementation CRRequest {
    NSMutableDictionary* _env;
}

- (instancetype)init {
    return [self initWithMethod:nil URL:nil version:nil env:nil];
}

- (instancetype)initWithMethod:(NSString *)method URL:(NSURL *)URL version:(NSString *)version {
    return [self initWithMethod:method URL:URL version:version env:nil];
}

- (instancetype)initWithMethod:(NSString *)method URL:(NSURL *)URL version:(NSString *)version env:(NSDictionary *)env {
    self = [super init];
    if ( self != nil ) {
        self.message = CFBridgingRelease( CFHTTPMessageCreateRequest(NULL, (__bridge CFStringRef)method, (__bridge CFURLRef)URL, (__bridge CFStringRef)version) );
        if ( env == nil ) {
            _env = [NSMutableDictionary dictionary];
        } else {
            [self setEnv:env];
        }
    }
    return self;
}

- (NSURL *)URL {
    return (__bridge_transfer NSURL *)CFHTTPMessageCopyRequestURL((__bridge CFHTTPMessageRef)self.message);
}

- (BOOL)appendData:(NSData *)data {
    return CFHTTPMessageAppendBytes((__bridge CFHTTPMessageRef)self.message, data.bytes, data.length);
}

- (NSString *)method {
	return (__bridge_transfer NSString *)CFHTTPMessageCopyRequestMethod((__bridge CFHTTPMessageRef _Nonnull)(self.message));
}

- (NSDictionary<NSString *,NSString *> *)env {
    return _env;
}

- (void)setEnv:(NSDictionary<NSString *,NSString *> *)envDictionary {
    if ( [envDictionary isKindOfClass:[NSMutableDictionary class]] ) {
        _env = (NSMutableDictionary*)envDictionary;
    } else {
        _env = envDictionary.mutableCopy;
    }

    // Parse request query string
    NSMutableDictionary<NSString *,NSString *> *query = [NSMutableDictionary dictionary];
    if ( _env[@"QUERY_STRING"] != nil ) {
        NSArray<NSString *> *queryVars = [_env[@"QUERY_STRING"] componentsSeparatedByString:@"&"];
        [queryVars enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSArray<NSString *> *queryVarComponents = [[obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsSeparatedByString:@"="];
            query[queryVarComponents[0]] = queryVarComponents.count > 1 ? queryVarComponents[1] : @"";
        }];
    }
    _query = query;

    // Parse request cookies
    NSMutableDictionary<NSString *,NSString *> *cookie = [NSMutableDictionary dictionary];
    if ( _env[@"HTTP_COOKIE"] != nil ) {
        NSArray<NSString *> *cookies = [_env[@"HTTP_COOKIE"] componentsSeparatedByString:@";"];
        [cookies enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSArray<NSString *> *cookieComponents = [[obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsSeparatedByString:@"="];
            cookie[cookieComponents[0]] = cookieComponents.count > 1 ? cookieComponents[1] : @"";
        }];
    }
    _cookie = cookie;
}

- (void)setEnv:(NSString *)obj forKey:(NSString *)key {
    [_env setObject:obj forKey:key];
}

- (BOOL)parseBody:(NSError *__autoreleasing  _Nullable *)error {
    BOOL result = YES;

    NSUInteger contentLength = [_env[@"HTTP_CONTENT_LENGTH"] integerValue];
    NSLog(@" * contentLength = %lu", contentLength);

    if ( contentLength > 0 ) {
        NSString* contentType = _env[@"HTTP_CONTENT_TYPE"];
        NSLog(@" * contentType = %@", contentType);
        if ([contentType hasPrefix:CRRequestTypeJSON]) {
            NSData* bodyData = self.bodyData;
            result = [self parseJSONBodyData:bodyData error:error];
        } else if ([contentType hasPrefix:CRRequestTypeMultipart]) {
            NSData* bodyData = self.bodyData;
            result = [self parseMultipartBodyData:bodyData error:error];
        } else if ([contentType hasPrefix:CRRequestTypeURLEncoded]) {
            NSData* bodyData = self.bodyData;
            result = [self parseURLEncodedBodyData:bodyData error:error];
        }
//        } else if ([contentType hasPrefix:CRRequestTypeXML]) {
//            NSData* bodyData = self.bodyData;
//            result = [self parseXMLBodyData:bodyData error:error];
//        }
    }

    return result;
}

- (BOOL)parseJSONBodyData:(NSData *)bodyData error:(NSError *__autoreleasing  _Nullable *)error {
    BOOL result = NO;

    NSError* jsonDecodingError;
    id decodedBody = [NSJSONSerialization JSONObjectWithData:bodyData options:0 error:&jsonDecodingError];

    if ( jsonDecodingError == nil ) {
        _body = decodedBody;
        result = YES;
    } else {
        *error = [NSError errorWithDomain:CRRequestErrorDomain code:CRRequestErrorMalformedBody userInfo:@{NSLocalizedDescriptionKey:@"Unable to parse JSON request.", NSUnderlyingErrorKey:jsonDecodingError}];
    }

    return result;
}

- (BOOL)parseMultipartBodyData:(NSData *)bodyData error:(NSError * _Nullable __autoreleasing *)error {
    BOOL result = YES;

    NSLog(@"%@", [[NSString alloc] initWithBytesNoCopy:(void*)bodyData.bytes length:bodyData.length encoding:NSUTF8StringEncoding freeWhenDone:NO]);

    // Get the boundary
    __block NSString* boundary;
    NSString* contentType = _env[@"HTTP_CONTENT_TYPE"];
    NSArray<NSString*>* headerComponents = [contentType componentsSeparatedByString:@";"];
    [headerComponents enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj = [obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ( ![obj hasPrefix:CRRequestBoundaryParameter] ) {
            return;
        }
        boundary = [[obj componentsSeparatedByString:@"="][1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }];

    if ( boundary.length > 0 ) {
        // Some stuff we'll use for parsing

        NSString * boundaryPrefixString = CRRequestBoundaryPrefix;
        const char * boundaryPrefixBytes = boundaryPrefixString.UTF8String;
        NSData * boundaryPrefixData = [NSData dataWithBytesNoCopy:(void * )boundaryPrefixBytes length:boundaryPrefixString.length freeWhenDone:NO];

        NSString * boundaryString = [NSString stringWithFormat:@"\r\n%@%@", boundaryPrefixString, boundary];
        const char * boundaryBytes = boundaryString.UTF8String;
        NSData * boundaryData = [NSData dataWithBytesNoCopy:(void *)boundaryBytes length:boundaryString.length freeWhenDone:NO];

        // Validate the input
        NSData* prefixData = [NSData dataWithBytesNoCopy:(void *)bodyData.bytes length:boundaryData.length freeWhenDone:NO];
        if ( [prefixData isEqualToData:boundaryData] ) {
            NSData* suffixData = [NSData dataWithBytesNoCopy:(void *)bodyData.bytes + bodyData.length - boundaryPrefixData.length - 2 length:boundaryPrefixData.length freeWhenDone:NO];
            if ( [suffixData isEqualToData:boundaryPrefixData] ) {
                NSData* lastBoundaryData = [NSData dataWithBytesNoCopy:(void *)bodyData.bytes + bodyData.length - boundaryPrefixData.length - boundaryData.length - 2 length:boundaryData.length freeWhenDone:NO];
                if ( [lastBoundaryData isEqualToData:boundaryData] ) {

                    

                } else {
                    result = NO;
                    *error = [NSError errorWithDomain:CRRequestErrorDomain code:CRRequestErrorMalformedBody userInfo:@{NSLocalizedDescriptionKey:@"Malformed multipart request.", NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"The body does not end with %@%@", boundaryString, boundaryPrefixString]}];
                }
            } else {
                result = NO;
                *error = [NSError errorWithDomain:CRRequestErrorDomain code:CRRequestErrorMalformedBody userInfo:@{NSLocalizedDescriptionKey:@"Malformed multipart request.", NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"The body does not end with \"%@\"", boundaryPrefixString]}];
            }
        } else {
            result = NO;
            *error = [NSError errorWithDomain:CRRequestErrorDomain code:CRRequestErrorMalformedBody userInfo:@{NSLocalizedDescriptionKey:@"Malformed multipart request.", NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"The body does not start with the boundary. (%@)", boundaryString]}];
        }
    } else {
        result = NO;
        *error = [NSError errorWithDomain:CRRequestErrorDomain code:CRRequestErrorMalformedBody userInfo:@{NSLocalizedDescriptionKey:@"Malformed multipart request.", NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"The Content-type header does not have a boundary parameter. (%@)", contentType]}];
    }

    return result;
}

- (BOOL)parseURLEncodedBodyData:(NSData *)bodyData error:(NSError * _Nullable __autoreleasing *)error {
    NSMutableDictionary<NSString *,NSString *> *body = [NSMutableDictionary dictionary];

    NSString* bodyString = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
    NSArray<NSString *> *bodyVars = [bodyString componentsSeparatedByString:@"&"];
    [bodyVars enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<NSString *> *bodyVarComponents = [[obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsSeparatedByString:@"="];
        body[bodyVarComponents[0]] = bodyVarComponents.count > 1 ? bodyVarComponents[1] : @"";
    }];
    _body = body;
    return YES;
}

//- (BOOL)parseXMLBodyData:(NSData *)bodyData error:(NSError * _Nullable __autoreleasing *)error {
//    BOOL result = NO;
//    *error = [NSError errorWithDomain:CRRequestErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%s not implemented yet.", __PRETTY_FUNCTION__]}];
//    return result;
//}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@ %@", self.method, self.URL.path, self.version];
}

- (BOOL)shouldCloseConnection {
    BOOL shouldClose = NO;

    NSString *connectionHeader = [self valueForHTTPHeaderField:@"Connection"];
    if ( connectionHeader != nil ) {
        shouldClose = [connectionHeader caseInsensitiveCompare:@"close"] == NSOrderedSame;
    } else {
        shouldClose = [self.version isEqualToString:CRHTTP10];
    }

    return shouldClose;
}


@end
