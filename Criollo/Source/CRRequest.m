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
#import "CRConnection.h"
#import "CRConnection_Internal.h"
#import "CRServer.h"
#import "CRServer_Internal.h"

@implementation CRRequest {
    NSMutableDictionary* _env;

    __block NSString * _multipartBoundary;
    __block dispatch_once_t _multipartBoundaryOnceToken;

    __block NSString * _multipartBoundaryPrefixedString;
    __block dispatch_once_t _multipartBoundaryPrefixedStringOnceToken;

    __block NSData * _multipartBoundaryPrefixedData;
    __block dispatch_once_t _multipartBoundaryPrefixedDataOnceToken;

    NSUInteger bodyParsingOffset;
    BOOL isReceivingFile;
}

- (instancetype)init {
    return [self initWithMethod:nil URL:nil version:nil connection:nil env:nil];
}

- (instancetype)initWithMethod:(NSString *)method URL:(NSURL *)URL version:(NSString *)version {
    return [self initWithMethod:method URL:URL version:version connection:nil env:nil];
}

- (instancetype)initWithMethod:(NSString *)method URL:(NSURL *)URL version:(NSString *)version connection:(nullable CRConnection *)connection {
    return [self initWithMethod:method URL:URL version:version connection:connection env:nil];
}
- (instancetype)initWithMethod:(NSString *)method URL:(NSURL *)URL version:(NSString *)version connection:(CRConnection *)connection env:(NSDictionary *)env {
    self = [super init];
    if ( self != nil ) {
        self.message = CFBridgingRelease( CFHTTPMessageCreateRequest(NULL, (__bridge CFStringRef)method, (__bridge CFURLRef)URL, (__bridge CFStringRef)version) );
        if ( env == nil ) {
            _env = [NSMutableDictionary dictionary];
        } else {
            [self setEnv:env];
        }
        self.connection = connection;
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

- (BOOL)parseJSONBodyData:(NSError *__autoreleasing  _Nullable *)error {
    BOOL result = NO;

    NSError* jsonDecodingError;
    id decodedBody = [NSJSONSerialization JSONObjectWithData:self.bufferedRequestBodyData options:0 error:&jsonDecodingError];

    if ( jsonDecodingError == nil ) {
        _body = decodedBody;
        result = YES;
        self.bufferedRequestBodyData = nil;
    } else {
        *error = [NSError errorWithDomain:CRRequestErrorDomain code:CRRequestErrorMalformedBody userInfo:@{NSLocalizedDescriptionKey:@"Unable to parse JSON request.", NSUnderlyingErrorKey:jsonDecodingError}];
    }

    return result;
}

- (BOOL)parseMultipartBodyDataChunk:(NSData *)data error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    BOOL result = YES;
    NSLog(@"%s %lu bytes", __PRETTY_FUNCTION__, data.length);

    if ( !isReceivingFile ) {

        // Check if there is anything left in the buffer
        if ( self.bufferedResponseData.length == 0 ) {
            bodyParsingOffset = self.multipartBoundaryPrefixedData.length;
            NSRange searchRange = NSMakeRange(offset, bodyData.length - offset);
            NSRange nextBoundaryRange = [bodyData rangeOfData:boundaryData options:0 range:searchRange];

            if ( nextBoundaryRange.location == NSNotFound ) {
                // This is just a
            } else {
                NSData* multipartPartData = [NSData dataWithBytesNoCopy:(void *)bodyData.bytes + offset length:nextBoundaryRange.location - offset freeWhenDone:NO];
                parseMultipartPartData(multipartPartData);
            }

        }

        if ( self.bufferedRequestBodyData == nil ) {
            self.bufferedRequestBodyData = [NSMutableData dataWithData:data];
        } else {
            [self.bufferedResponseData appendData:data];
        }
    }
//    void(^parseMultipartPartData)(NSData * _Nonnull) = ^(NSData * multipartPartData) {
//        NSLog(@" ** %s %lu", __PRETTY_FUNCTION__, multipartPartData.length);
//    };

//    if ( self.bufferedRequestBodyData == nil ) {
//        self.bufferedRequestBodyData
//    }
//
//    do {
//        offset += boundaryData.length;
//        NSRange searchRange = NSMakeRange(offset, bodyData.length - offset);
//        NSRange nextBoundaryRange = [bodyData rangeOfData:boundaryData options:0 range:searchRange];
//
//        if ( nextBoundaryRange.location == NSNotFound ) {
//            break;
//        }
//
//        NSData* multipartPartData = [NSData dataWithBytesNoCopy:(void *)bodyData.bytes + offset length:nextBoundaryRange.location - offset freeWhenDone:NO];
//        parseMultipartPartData(multipartPartData);
//
//        offset = nextBoundaryRange.location;
//    } while (offset < bodyData.length );

//    // Validate the input
//    NSData* prefixData = [NSData dataWithBytesNoCopy:(void *)bodyData.bytes length:boundaryData.length freeWhenDone:NO];
//    if ( [prefixData isEqualToData:boundaryData] ) {
//        NSData* suffixData = [NSData dataWithBytesNoCopy:(void *)bodyData.bytes + bodyData.length - boundaryPrefixData.length - 2 length:boundaryPrefixData.length freeWhenDone:NO];
//        if ( [suffixData isEqualToData:boundaryPrefixData] ) {
//            NSData* lastBoundaryData = [NSData dataWithBytesNoCopy:(void *)bodyData.bytes + bodyData.length - boundaryPrefixData.length - boundaryData.length - 2 length:boundaryData.length freeWhenDone:NO];
//            if ( [lastBoundaryData isEqualToData:boundaryData] ) {
//            } else {
//                result = NO;
//                *error = [NSError errorWithDomain:CRRequestErrorDomain code:CRRequestErrorMalformedBody userInfo:@{NSLocalizedDescriptionKey:@"Malformed multipart request.", NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"The body does not end with %@%@", boundaryString, boundaryPrefixString]}];
//            }
//        } else {
//            result = NO;
//            *error = [NSError errorWithDomain:CRRequestErrorDomain code:CRRequestErrorMalformedBody userInfo:@{NSLocalizedDescriptionKey:@"Malformed multipart request.", NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"The body does not end with \"%@\"", boundaryPrefixString]}];
//        }
//    } else {
//        result = NO;
//        *error = [NSError errorWithDomain:CRRequestErrorDomain code:CRRequestErrorMalformedBody userInfo:@{NSLocalizedDescriptionKey:@"Malformed multipart request.", NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"The body does not start with the boundary. (%@)", boundaryString]}];
//    }

    return result;
}

- (BOOL)parseURLEncodedBodyData:(NSError *__autoreleasing  _Nullable *)error {
    NSMutableDictionary<NSString *,NSString *> *body = [NSMutableDictionary dictionary];

    NSString* bodyString = [[NSString alloc] initWithBytesNoCopy:(void *)self.bufferedRequestBodyData.bytes length:self.bufferedRequestBodyData.length encoding:NSUTF8StringEncoding freeWhenDone:NO];
    NSArray<NSString *> *bodyVars = [bodyString componentsSeparatedByString:CRRequestKeySeparator];
    [bodyVars enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<NSString *> *bodyVarComponents = [[obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsSeparatedByString:CRRequestValueSeparator];
        body[bodyVarComponents[0]] = bodyVarComponents.count > 1 ? bodyVarComponents[1] : @"";
    }];
    _body = body;
    self.bufferedRequestBodyData = nil;
    return YES;
}

- (BOOL)parseBufferedBodyData:(NSError *__autoreleasing  _Nullable *)error {
    _body = [NSData dataWithBytesNoCopy:(void *)self.bufferedRequestBodyData.bytes length:self.bufferedRequestBodyData.length freeWhenDone:NO];
    return YES;
}

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

- (NSString *)multipartBoundary {
    NSString* contentType = _env[@"HTTP_CONTENT_TYPE"];
    if ([contentType hasPrefix:CRRequestTypeMultipart]) {
        dispatch_once(&_multipartBoundaryOnceToken, ^{
            NSArray<NSString*>* headerComponents = [contentType componentsSeparatedByString:CRRequestHeaderSeparator];
            [headerComponents enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj = [obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if ( ![obj hasPrefix:CRRequestBoundaryParameter] ) {
                    return;
                }
                _multipartBoundary = [[obj componentsSeparatedByString:CRRequestValueSeparator][1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }];
        });
    }
    return _multipartBoundary;
}

- (NSData *)multipartBoundaryPrefixData {
    static NSData * _multipartBoundaryPrefixData;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _multipartBoundaryPrefixData = [NSData dataWithBytesNoCopy:(void * )CRRequestBoundaryPrefix.UTF8String length:CRRequestBoundaryPrefix.length freeWhenDone:NO];
    });
    return _multipartBoundaryPrefixData;
}

- (NSString *)multipartBoundaryPrefixedString {
    if ( self.multipartBoundary.length > 0 ) {
        dispatch_once(&_multipartBoundaryPrefixedStringOnceToken, ^{
            _multipartBoundaryPrefixedString = [NSString stringWithFormat:@"\r\n%@%@", CRRequestBoundaryPrefix, self.multipartBoundary];
        });
    }
    return _multipartBoundaryPrefixedString;
}

- (NSData *)multipartBoundaryPrefixedData {
    if ( self.multipartBoundaryPrefixedString.length > 0 ) {
        dispatch_once(&_multipartBoundaryPrefixedDataOnceToken, ^{
            _multipartBoundaryPrefixedData = [NSData dataWithBytesNoCopy:(void *)self.multipartBoundaryPrefixedString.UTF8String length:self.multipartBoundaryPrefixedString.length freeWhenDone:NO];
        });
    }
    return _multipartBoundaryPrefixedData;
}

@end
