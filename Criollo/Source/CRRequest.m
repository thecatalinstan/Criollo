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

    NSString* currentMultipartBodyKey;
    NSString* currentMultipartFileKey;
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
        NSArray<NSString *> *queryVars = [_env[@"QUERY_STRING"] componentsSeparatedByString:CRRequestKeySeparator];
        [queryVars enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSArray<NSString *> *queryVarComponents = [[obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsSeparatedByString:CRRequestValueSeparator];
            query[queryVarComponents[0]] = queryVarComponents.count > 1 ? queryVarComponents[1] : @"";
        }];
    }
    _query = query;

    // Parse request cookies
    NSMutableDictionary<NSString *,NSString *> *cookies = [NSMutableDictionary dictionary];
    if ( _env[@"HTTP_COOKIE"] != nil ) {
        NSArray<NSString *> *cookieStrings = [_env[@"HTTP_COOKIE"] componentsSeparatedByString:CRRequestHeaderSeparator];
        [cookieStrings enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSArray<NSString *> *cookieComponents = [[obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsSeparatedByString:CRRequestValueSeparator];
            cookies[cookieComponents[0]] = cookieComponents.count > 1 ? cookieComponents[1] : @"";
        }];
    }
    _cookies = cookies;
}

- (void)setEnv:(NSString *)obj forKey:(NSString *)key {
    [_env setObject:obj forKey:key];
}

- (BOOL)parseJSONBodyData:(NSError *__autoreleasing  _Nullable *)error {
    BOOL result = NO;

    NSError* jsonDecodingError;
    id decodedBody = [NSJSONSerialization JSONObjectWithData:self.bufferedBodyData options:0 error:&jsonDecodingError];

    if ( jsonDecodingError == nil ) {
        _body = decodedBody;
        result = YES;
        self.bufferedBodyData = nil;
    } else {
        *error = [NSError errorWithDomain:CRRequestErrorDomain code:CRRequestErrorMalformedBody userInfo:@{NSLocalizedDescriptionKey:@"Unable to parse JSON request.", NSUnderlyingErrorKey:jsonDecodingError}];
    }

    return result;
}

- (BOOL)parseMultipartBodyDataChunk:(NSData *)data error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    BOOL result = YES;

    NSLog(@"%s %lu bytes", __PRETTY_FUNCTION__, data.length);

    // Search for a boundary
    NSRange searchRange = NSMakeRange(0, data.length);
    NSRange nextBoundaryRange = [data rangeOfData:self.multipartBoundaryPrefixedData options:0 range:searchRange];

    if ( nextBoundaryRange.location != NSNotFound ) {                                   // We have a boundary

        // Check if we have something before the boundary
        if ( nextBoundaryRange.location != 0 ) {                                        // There is an existing chunk

            // Extract the piece
            NSData* preambleData = [NSData dataWithBytesNoCopy:(void *)data.bytes length:nextBoundaryRange.location freeWhenDone:NO];

            // Check if we have something buffered
            if ( self.bufferedBodyData.length > 0 ) {                                   // This is part of a field that

                // Prepend the the buffered data to the one piece
                NSMutableData* bufferedAndPreambleData = [NSMutableData dataWithCapacity:(self.bufferedBodyData.length + nextBoundaryRange.location)];
                [bufferedAndPreambleData appendData:self.bufferedBodyData];
                [bufferedAndPreambleData appendData:preambleData];

                // Flush the buffered data
                self.bufferedBodyData = nil;

                // Call this method again with the combined data
                result = [self parseMultipartBodyDataChunk:bufferedAndPreambleData error:error];
            } else {

                // Append the piece to the target if there is one otherwise discard it
                // (RFC 1341 says to discard anything before the first --boundary (the preamble)
                // http://www.w3.org/Protocols/rfc1341/7_2_Multipart.html

                if (currentMultipartBodyKey != nil && self.body != nil) {
                    result = [self appendBodyData:preambleData forKey:currentMultipartBodyKey];
                } else if ( currentMultipartFileKey == nil && self.files != nil ) {
                    result = [self appendFileData:preambleData forKey:currentMultipartFileKey];
                }

            }

            if ( result ) {
                // Extract the remaining data
                NSData* nextChunkData = [NSData dataWithBytesNoCopy:(void *)data.bytes + nextBoundaryRange.location length:data.length - nextBoundaryRange.location freeWhenDone:NO];

                // Call this method again with the remaining data
                result = [self parseMultipartBodyDataChunk:nextChunkData error:error];
            }

        } else {                                                                        // We are starting with a new field

            NSData* CRLFData = [CRConnection CRLFData];
            NSData* CRLFCRLFData = [CRConnection CRLFCRLFData];

            NSUInteger offset = 0;

            // Read the header (starts after the --boundary and a CRLF and ends with CRLFCRLF)
            NSUInteger headerStartLocation = nextBoundaryRange.location + nextBoundaryRange.length + CRLFData.length;
            NSRange headerSearchRange = NSMakeRange(headerStartLocation, data.length);

            NSRange headerRange = [data rangeOfData:CRLFCRLFData options:0 range:headerSearchRange];

            if ( headerRange.location != NSNotFound ) {                                 // We have a header - all good

                NSData* headerData = [NSData dataWithBytesNoCopy:(void *)data.bytes + headerSearchRange.length + headerRange.location length:headerRange.length freeWhenDone:NO];
                NSLog(@"Header: %@", [[NSString alloc] initWithBytesNoCopy:(void *)headerData.bytes length:headerData.length encoding:NSUTF8StringEncoding freeWhenDone:NO] );

            } else {                                                                    // There is no header something is very wrong

            }

        }


    } else {                                                                            // This is just a chunk of something

        // Append the data to the target if there is one otherwise discard it
        // (RFC 1341 says to discard anything before the first --boundary (the preamble)
        // http://www.w3.org/Protocols/rfc1341/7_2_Multipart.html

        if (currentMultipartBodyKey != nil && self.body != nil) {
            result = [self appendBodyData:data forKey:currentMultipartBodyKey];
        } else if ( currentMultipartFileKey == nil && self.files != nil ) {
            result = [self appendFileData:data forKey:currentMultipartFileKey];
        }

    }


    return result;
}

- (void)bufferBodyData:(NSData*)data {
    if ( self.bufferedBodyData == nil ) {
        self.bufferedBodyData = [NSMutableData dataWithData:data];
    } else {
        [self.bufferedBodyData appendData:data];
    }
}

- (BOOL)appendBodyData:(NSData *)data forKey:(NSString *)key {
    NSLog(@"%s %@ => %lu bytes", __PRETTY_FUNCTION__, key, data.length);

    BOOL result = YES;

    if ( _body == nil ) {
        _body = [NSMutableDictionary dictionary];
    }
    NSString* dataString = [[NSString alloc] initWithBytesNoCopy:(void *)data.bytes length:data.length encoding:NSUTF8StringEncoding freeWhenDone:NO];
    NSMutableDictionary* body = _body;
    if ( body[key] == nil ) {
        body[key] = [NSMutableString stringWithString:dataString];
    } else {
        [((NSMutableString *) body[key]) appendString:dataString];
    }

    return result;
}

- (BOOL)appendFileData:(NSData *)data forKey:(NSString *)key {
    NSLog(@"%s %@ => %lu bytes", __PRETTY_FUNCTION__, key, data.length);

    return YES;
}

- (void)bufferResponseData:(NSData *)data {
    if ( self.bufferedResponseData == nil ) {
        self.bufferedResponseData = [NSMutableData dataWithData:data];
    } else {
        [self.bufferedResponseData appendData:data];
    }
}

- (void)validateMultipartBody:(NSData*)bodyData {
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
}

- (BOOL)parseURLEncodedBodyData:(NSError *__autoreleasing  _Nullable *)error {
    NSMutableDictionary<NSString *,NSString *> *body = [NSMutableDictionary dictionary];

    NSString* bodyString = [[NSString alloc] initWithBytesNoCopy:(void *)self.bufferedBodyData.bytes length:self.bufferedBodyData.length encoding:NSUTF8StringEncoding freeWhenDone:NO];
    NSArray<NSString *> *bodyVars = [bodyString componentsSeparatedByString:CRRequestKeySeparator];
    [bodyVars enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<NSString *> *bodyVarComponents = [[obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsSeparatedByString:CRRequestValueSeparator];
        body[bodyVarComponents[0]] = bodyVarComponents.count > 1 ? bodyVarComponents[1] : @"";
    }];
    _body = body;
    self.bufferedBodyData = nil;
    return YES;
}

- (BOOL)parseBufferedBodyData:(NSError *__autoreleasing  _Nullable *)error {
    _body = [NSData dataWithBytesNoCopy:(void *)self.bufferedBodyData.bytes length:self.bufferedBodyData.length freeWhenDone:NO];
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
