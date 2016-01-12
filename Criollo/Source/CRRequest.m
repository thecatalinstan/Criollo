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
        if ([contentType isEqualToString:CRRequestTypeJSON]) {
            NSData* bodyData = self.bodyData;
            result = [self parseJSONBodyData:bodyData error:error];
        } else if ([contentType isEqualToString:CRRequestTypeMultipart]) {
            NSData* bodyData = self.bodyData;
            result = [self parseMultipartBodyData:bodyData error:error];
        } else if ([contentType isEqualToString:CRRequestTypeURLEncoded]) {
            NSData* bodyData = self.bodyData;
            result = [self parseURLEncodedBodyData:bodyData error:error];
        }
//        } else if ([contentType isEqualToString:CRRequestTypeXML]) {
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
    BOOL result = NO;
    *error = [NSError errorWithDomain:CRRequestErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%s not implemented yet.", __PRETTY_FUNCTION__]}];
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
