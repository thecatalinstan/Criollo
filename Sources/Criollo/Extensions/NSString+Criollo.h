//
//  NSString+Criollo.h
//
//
//  Created by Cătălin Stan on 4/12/14.
//

#import <Foundation/Foundation.h>

@interface NSString (Criollo)

@property (nonatomic, readonly, copy) NSString *stringByDecodingURLEncodedString;
@property (nonatomic, readonly, copy) NSString *URLEncodedString;

@property (nonatomic, readonly, copy) NSString *uppercaseFirstLetterString;
@property (nonatomic, readonly, copy) NSString *stringbyFormattingHTTPHeader;

- (NSString *)pathRelativeToPath:(NSString *)path separator:(NSString *)separator;

@end
