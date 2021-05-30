//
//  NSString+Criollo.m
//  Criollo
//
//  Created by Cătălin Stan on 4/12/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Criollo/CRTypes.h>

#import "NSString+Criollo.h"

@implementation NSString (Criollo)

- (NSString *)stringByDecodingURLEncodedString {
	NSString* returnString = self.stringByRemovingPercentEncoding;
    returnString = [returnString stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    return returnString;
}

- (NSString *)URLEncodedString {
    NSString* allowedCharacters = @"!*'();:&=$,/?%#[]";
    NSString* returnString = [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:allowedCharacters]];
    returnString = [returnString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    return returnString;
}

- (NSString *)uppercaseFirstLetterString {
    return [[self substringToIndex:1].uppercaseString stringByAppendingString:[self substringFromIndex:1].lowercaseString];
}

- (NSString *)stringbyFormattingHTTPHeader {
    NSMutableArray* words = [[self componentsSeparatedByString:@"-"] mutableCopy];
    [words enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [words setObject:[obj uppercaseFirstLetterString] atIndexedSubscript:idx];
    }];
    return [words componentsJoinedByString:@"-"];
}

- (NSString *)pathRelativeToPath:(NSString *)path {
    
    if ( [path isEqualToString:CRPathSeparator] ) {
        return self;
    }

    NSUInteger relativePathStart = [self rangeOfString:path options:NSBackwardsSearch].location;
    if ( relativePathStart == NSNotFound ) {
        relativePathStart = 0;
    }

    NSString * relativePath;
    @try {
        relativePath = [[self substringFromIndex:relativePathStart + path.length] stringByStandardizingPath];
    } @catch (NSException *exception) {
        relativePath = @"";
    }

    if ( ![relativePath hasPrefix:CRPathSeparator] ) {
        relativePath = [CRPathSeparator stringByAppendingString:relativePath ? : @""];
    }

    return relativePath;
}

@end
