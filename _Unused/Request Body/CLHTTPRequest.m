//
//  CLHTTPRequest.m
//  Criollo
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "CLHTTPRequest.h"
#import "FCGIRequest.h"
#import "NSString+Criollo.h"

@interface CLHTTPRequest (Private)

- (NSDictionary*)parseQueryString:(NSString*)queryString;
- (NSArray*)parseMultipartFormData:(NSData*)data boundary:(NSString*)boundary;
- (NSDictionary*)parseMultipartFormDataPart:(NSData*)data;
- (NSDictionary*)parseHeaderValue:(NSString*)value;

@end

@implementation CLHTTPRequest (Private)

- (NSDictionary*)parseQueryString:(NSString*)queryString
{
    NSArray* tokens = [queryString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&"]];
    
    NSMutableDictionary* result = [NSMutableDictionary dictionaryWithCapacity:tokens.count];
    [tokens enumerateObjectsUsingBlock:^(id token, NSUInteger idx, BOOL *stop) {
        NSArray* pair = [token componentsSeparatedByString:@"="];
        NSString* key = pair[0];
        NSString* value = pair.count == 2 ? pair[1] : @"";
        result[key.stringByDecodingURLEncodedString] = value.stringByDecodingURLEncodedString;
    }];
    
    return result.copy;
}

- (NSArray*)parseMultipartFormData:(NSData*)data boundary:(NSString*)boundary
{
    if ( boundary == nil ) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Boundary cannot be nil." userInfo:nil];
        return nil;
    }

    NSMutableDictionary* post = [[NSMutableDictionary alloc] init];
    NSMutableDictionary* files = [[NSMutableDictionary alloc] init];
    
    boundary = [NSString stringWithFormat:@"--%@", boundary];
    NSData* boundaryData = [boundary dataUsingEncoding:NSASCIIStringEncoding];
    
    NSRange partRange = NSMakeRange(boundaryData.length + 2, 0);
    NSRange searchRange = NSMakeRange(boundaryData.length, data.length - boundaryData.length);
    NSRange resultRange;
    
    do {
        resultRange = [data rangeOfData:boundaryData options:0 range:searchRange];
        if ( resultRange.location != NSNotFound ) {
            partRange.length = resultRange.location - partRange.location - 2;
            
            NSDictionary* part = [self parseMultipartFormDataPart:[data subdataWithRange:partRange]];
            if ( part != nil ) {
                NSString* key = part.allKeys[0];
                id value = part[key];
                if ( [value isKindOfClass:[NSString class]] ) {
                    post[key] = value;
                } else {
                    files[key] = value;
                }
            }
            partRange.location = resultRange.location + resultRange.length + 2;
        }
        
        searchRange.location = resultRange.location + resultRange.length;
        searchRange.length = data.length - resultRange.location - resultRange.length;
        
    } while (resultRange.location != NSNotFound);
    
    
    return @[post.copy, files.copy];
}

- (NSDictionary*)parseMultipartFormDataPart:(NSData*)data
{
    NSData* headersSeparator = [@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
    
    NSRange separatorRange = [data rangeOfData:headersSeparator options:0 range:NSMakeRange(0, data.length)];
    if ( separatorRange.location == NSNotFound ) {
        return nil;
    }

    __block NSMutableDictionary* headers = [NSMutableDictionary dictionary];
    NSArray* headerLines = [[[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, separatorRange.location)] encoding:NSUTF8StringEncoding] componentsSeparatedByString:@"\r\n"];
    [headerLines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray* parts = [obj componentsSeparatedByString:@": "];
        headers[parts[0]] = [self parseHeaderValue:parts[1]];
    }];
    
    NSData* bodyData = [data subdataWithRange:NSMakeRange(separatorRange.location + separatorRange.length, data.length - separatorRange.location - separatorRange.length)];
    NSString* key = headers[@"Content-Disposition"][@"name"];
    if ( headers[@"Content-Disposition"][@"filename"] == nil || [headers[@"Content-Disposition"][@"filename"] isEqualToString:@""] ) {
        NSString* value = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
        return @{ key: value};
    } else {
        NSString* tmpFilename = [[CLApp temporaryDirectoryLocation] stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
        [bodyData writeToFile:tmpFilename atomically:NO];
        NSDictionary* value = @{ CLFileNameKey: headers[@"Content-Disposition"][@"filename"],
                                 CLFileTmpNameKey: tmpFilename,
                                 CLFileContentTypeKey: headers[@"Content-Type"][@"_"],
                                 CLFileSizeKey: @(bodyData.length)};
        return @{ key: value };
    }
}


- (NSDictionary*)parseHeaderValue:(NSString*)value
{
    __block NSMutableDictionary* paramsDictionary = [NSMutableDictionary dictionary];
    NSArray* parts = [value componentsSeparatedByString:@";"];
    [parts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray* partKV = [obj componentsSeparatedByString:@"="];
        if ( partKV.count == 1 ) {
            paramsDictionary[@"_"] = partKV[0];
        } else {
            paramsDictionary[[partKV[0] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]]] = [partKV[1] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \""]];
        }
    }];
    return [paramsDictionary copy];
}

@end

@implementation CLHTTPRequest

@synthesize FCGIRequest = _FCGIRequest;

- (instancetype)initWithFCGIRequest:(FCGIRequest *)anFCGIRequest
{
//    NSLog(@"%s%@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    
    self = [self init];
    if ( self != nil ) {

        _FCGIRequest = anFCGIRequest;
        
        body = _FCGIRequest.stdinData;
        
        _url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@%@", @"http", _FCGIRequest.parameters[@"HTTP_HOST"], _FCGIRequest.parameters[@"REQUEST_URI"]]];
                
        // SERVER
        _parameters = [NSDictionary dictionaryWithDictionary:_FCGIRequest.parameters];
        
        // GET
        if ( [_parameters.allKeys containsObject:@"QUERY_STRING"] ) {
            _get = [self parseQueryString:_parameters[@"QUERY_STRING"]];
        } else {
            _get = @{};
        }
        
        // POST
        NSDictionary* contentType = [self parseHeaderValue:_parameters[@"CONTENT_TYPE"]];
        if ( [_parameters[@"REQUEST_METHOD"] isEqualToString:@"POST"] && [contentType[@"_"] isEqualToString:@"application/x-www-form-urlencoded"] ) {
            _post = [self parseQueryString:[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding]];
            _files = @{};
        } else if([_parameters[@"REQUEST_METHOD"] isEqualToString:@"POST"] && [contentType[@"_"] isEqualToString:@"multipart/form-data"]) {
            if ( body.length == 0 || contentType[@"boundary"] == nil ) {
                _post = @{};
                _files = @{};
            } else {
                NSArray* postInfo = [self parseMultipartFormData:body boundary:contentType[@"boundary"]];
                _post = postInfo[0];
                _files = postInfo[1];
            }
        } else {
            _post = @{};
            _files = @{};
        }
        
        // COOKIE
        _cookie = [self parseHeaderValue:_parameters[@"HTTP_COOKIE"]];
    }
    return self;
}

+ (instancetype)requestWithFCGIRequest:(FCGIRequest *)anFCGIRequest
{
    return [[CLHTTPRequest alloc] initWithFCGIRequest:anFCGIRequest];
}

@end
