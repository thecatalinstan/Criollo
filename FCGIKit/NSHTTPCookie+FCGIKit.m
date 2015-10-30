//
//  NSHTTPCookie+FCGIKit.m
//  FCGIKit
//
//  Created by Cătălin Stan on 5/17/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "NSHTTPCookie+FCGIKit.h"
#import "NSDate+RFC1123.h"

@implementation NSHTTPCookie (FCGIKit)

- (NSString *)HTTPHeaderField
{
    if ( self.name == nil ) {
        return nil;
    }
    
    NSMutableArray* fields = [NSMutableArray array];
    [fields addObject:[NSString stringWithFormat:@"%@=%@", self.name, self.value]];
    if( ! self.isSessionOnly ) {
        [fields addObject:[NSString stringWithFormat:@"%@=%@", @"expires", self.expiresDate.rfc1123String]];
    }
    [fields addObject:[NSString stringWithFormat:@"%@=%@", @"path", self.path]];
    [fields addObject:[NSString stringWithFormat:@"%@=%@", @"domain", self.domain]];

    if ( self.isSecure ) {
        [fields addObject:@"secure"];
    }
    if ( self.isHTTPOnly ) {
        [fields addObject:@"httponly"];
    }
    
    return [fields componentsJoinedByString:@"; "];
}

+ (NSDictionary *)responseHeaderFieldsWithCookies:(NSArray *)cookies
{
    if ( cookies.count == 0 ) {
        return nil;
    }
    NSString* key = @"Set-Cookie";
    NSMutableArray* headerFields = [NSMutableArray arrayWithCapacity:cookies.count];
    [cookies enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString* headerField = [obj HTTPHeaderField];
        if ( headerField != nil ) {
            [headerFields addObject:headerField];
        }
    }];
    return @{ key: [headerFields componentsJoinedByString:@", "] };
}

@end
