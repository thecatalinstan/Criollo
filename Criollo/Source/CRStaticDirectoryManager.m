//
//  CRStaticDirectoryManager.m
//  Criollo
//
//  Created by Cătălin Stan on 2/10/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CRStaticDirectoryManager.h"

#import "CRServer.h"
#import "CRServer_Internal.h"
#import "CRRequest.h"
#import "CRResponse.h"
#import "CRStaticFileManager.h"
#import "CRStaticFileManager_Internal.h"
#import "CRRouter_Internal.h"

#import "NSString+Criollo.h"

NS_ASSUME_NONNULL_BEGIN

NS_INLINE NSUInteger HTTPStatusCodeForError(NSError *error);

static NSString * const CRStaticDirectoryManagerErrorDomain = @"CRStaticDirectoryManagerErrorDomain";
#define CRStaticDirectoryManagerDirectoryListingForbiddenError          201
#define CRStaticDirectoryManagerNotImplementedError                     999

static NSUInteger const IndexFileNameLength = 70;
static NSUInteger const IndexFileSizeLength = 20;

static NSString * const IndexHTMLFormat = @"<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\"/><meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\"/><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"/><title>%@</title></head><body><h1>Index of %@</h1><hr/><pre>%@</pre><hr/><small><i>Directory index took %.4fms to generate</i></small></body></html>";
static NSString * const IndexParentDirLinkFormat = @"<a href=\"%@\">../</a>\n";
static NSString * const IndexRowFormat = @"<a href=\"%@%@%@\" title=\"%@\">%@%@</a>%@ %@ %@%@\n";

static NSDateFormatter *dateFormatter;

@interface CRStaticDirectoryManager ()

@property (nonatomic, strong, readonly) NSString *path;
@property (nonatomic, strong, readonly) NSString *prefix;
@property (nonatomic, readonly) CRStaticDirectoryServingOptions options;

@end

NS_ASSUME_NONNULL_END

@implementation CRStaticDirectoryManager

- (instancetype)initWithDirectoryAtPath:(NSString *)path prefix:(NSString *)prefix options:(CRStaticDirectoryServingOptions)options {
    self = [super init];
    if ( self != nil ) {
        _options = options;
        _path = path.stringByStandardizingPath;
        if (_options & CRStaticDirectoryServingOptionsFollowSymlinks) {
            _path = _path.stringByResolvingSymlinksInPath;
        }
        _prefix = prefix.stringByStandardizingPath;
        
        __weak typeof(self) wself = self;
        _routeBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock _Nonnull completion) {
            [wself handleRequest:request response:response completion:completion];
        };
    }
    return self;
}

- (void)handleRequest:(CRRequest *)request response:(CRResponse *)response completion:(CRRouteCompletionBlock)completion {
    // Determine the absolute and relative requested file paths
    NSString *requestedPath = request.env[@"DOCUMENT_URI"];
    NSString *relativePath = [requestedPath pathRelativeToPath:_prefix];
    NSString *absolutePath = [_path stringByAppendingPathComponent:relativePath].stringByStandardizingPath;
    if (_options & CRStaticFileServingOptionsFollowSymlinks) {
        absolutePath = absolutePath.stringByResolvingSymlinksInPath;
    }
    
    NSError *error;
    NSDictionary<NSFileAttributeKey, id> *attributes;
    if (!(attributes = [NSFileManager.defaultManager attributesOfItemAtPath:absolutePath error:&error])) {
        goto error;
    }
    
    if ([attributes.fileType isEqualToString:NSFileTypeDirectory]) {
        if(![self generateIndexForPath:absolutePath requestedPath:requestedPath relativePath:relativePath response:response completion:completion error:&error]) {
            goto error;
        }
    } else {
        // If the file is not a directory, hand it over to a static file manager
        CRStaticFileManager *manager = [[CRStaticFileManager alloc] initWithFileAtPath:absolutePath options:(CRStaticFileServingOptions)_options fileName:nil contentType:nil contentDisposition:CRStaticFileContentDispositionNone attributes:attributes];
        [manager handleRequest:request response:response completion:completion];
    }
    
    return;
    
error:
    [self handleError:error request:request response:response completion:completion];
}

- (BOOL)generateIndexForPath:(NSString *)absolurePath requestedPath:(NSString *)requestedPath relativePath:(NSString *)relativePath response:(CRResponse *)response completion:(CRRouteCompletionBlock)completion error:(NSError *__autoreleasing *)error {
    if (!(_options & CRStaticDirectoryServingOptionsAutoIndex)) {
        if (error) {
            *error = [self errorWithCode:CRStaticDirectoryManagerDirectoryListingForbiddenError description:NSLocalizedString(@"Directory index auto-generation is disabled",) underlyingError:nil];
        }
        return NO;
    }
        
    NSDate *start = NSDate.date;
    
    NSURL *url = [NSURL fileURLWithPath:absolurePath];
    NSArray<NSURLResourceKey> *keys = @[
        NSURLIsDirectoryKey,
        NSURLFileSizeKey,
        NSURLContentModificationDateKey
    ];
    NSDirectoryEnumerationOptions options = _options & CRStaticDirectoryServingOptionsAutoIndexShowHidden ? 0 :  NSDirectoryEnumerationSkipsHiddenFiles;
    
    NSArray<NSURL *> *contents;
    if (!(contents = [NSFileManager.defaultManager contentsOfDirectoryAtURL:url includingPropertiesForKeys:keys options:options error:error])) {
        return NO;
    }
    
    contents = [contents sortedArrayUsingComparator:^NSComparisonResult(NSURL * _Nonnull obj1, NSURL * _Nonnull obj2) {
        return [obj1.lastPathComponent localizedCompare:obj2.lastPathComponent];
    }];
    
    NSMutableString *index = [NSMutableString stringWithCapacity:1024];
    
    // Display ".." link
    if (relativePath.length && ![requestedPath hasSuffix:_prefix] ) {
        [index appendFormat:IndexParentDirLinkFormat, requestedPath.stringByDeletingLastPathComponent];
    }
    
    for (NSURL *item in contents) {
        NSNumber *dir, *size;
        if(![item getResourceValue:&dir forKey:NSURLIsDirectoryKey error:nil]) {
            continue;
        }
        if(![item getResourceValue:&size forKey:NSURLFileSizeKey error:nil]) {
            continue;
        }

        BOOL isDirectory = dir.boolValue;
        NSString *fileSize = size.stringValue ?: @"-";
        
        NSDate *mtime;
        [item getResourceValue:&mtime forKey:NSURLContentModificationDateKey error:nil];
        NSString* fileModificationDate = [dateFormatter stringFromDate:mtime];
        
        NSString* fileName = item.lastPathComponent;
        NSString* fullName = [fileName stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
        NSString* fileNamePadding;
        if ( fileName.length > IndexFileNameLength ) {
            fileName = [fileName substringToIndex:IndexFileNameLength - (isDirectory ? 1 : 0)];
            fileNamePadding = @"";
        } else {
            fileNamePadding = [@"" stringByPaddingToLength:IndexFileNameLength - fileName.length - (isDirectory ? 1 : 0) withString:@" " startingAtIndex:0];
        }
        
        
        
        NSString* fileSizePadding;
        if ( fileSize.length > IndexFileSizeLength ) {
            fileSize =  [fileSize substringToIndex:IndexFileSizeLength];
            fileSizePadding = @"";
        } else {
            fileSizePadding = [@"" stringByPaddingToLength:IndexFileSizeLength - fileSize.length withString:@" " startingAtIndex:0];
        }
        
        [index appendFormat:IndexRowFormat, requestedPath, [requestedPath isEqualToString:CRPathSeparator] ? @"" : CRPathSeparator, fileName, fullName, fileName, isDirectory ? CRPathSeparator : @"", fileNamePadding, fileModificationDate, fileSizePadding, fileSize];
    }
    
    NSString *responseString = [NSString stringWithFormat:IndexHTMLFormat, requestedPath, requestedPath, index, [NSDate.date timeIntervalSinceDate:start] * 1000];
    NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    
    [response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [response setValue:[NSString stringWithFormat:@"%lu", (unsigned long)responseData.length] forHTTPHeaderField:@"Content-Length"];
    [response sendData:responseData];
    
    completion();
    return YES;
}

#pragma mark - Error Response

- (void)handleError:(NSError *)error request:(CRRequest *)request response:(CRResponse *)response completion:(CRRouteCompletionBlock)completion {
    [CRRouter handleErrorResponse:HTTPStatusCodeForError(error) error:error request:request response:response completion:completion];
}

#pragma mark - Helper Methods

- (NSError *)errorWithCode:(NSUInteger)code description:(NSString *)description underlyingError:(NSError * _Nullable)underlyingError {
    NSMutableDictionary<NSErrorUserInfoKey, id> *info = [NSMutableDictionary dictionaryWithCapacity:3];
    info[NSLocalizedDescriptionKey] = description;
    info[NSFilePathErrorKey] = _path;
    info[NSUnderlyingErrorKey] = underlyingError;
    return [NSError errorWithDomain:CRStaticDirectoryManagerErrorDomain code:code userInfo:info];
}

#pragma mark - Convenience Initializers

+ (void)initialize {
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    dateFormatter.timeZone = [NSTimeZone defaultTimeZone];
    dateFormatter.dateFormat = @"dd-MMM-yyyy HH:mm:ss";
}

+ (instancetype)managerWithDirectoryAtPath:(NSString *)path prefix:(NSString *)prefix {
    return [[CRStaticDirectoryManager alloc] initWithDirectoryAtPath:path prefix:prefix options:0];
}

+ (instancetype)managerWithDirectoryAtPath:(NSString *)path prefix:(NSString *)prefix options:(CRStaticDirectoryServingOptions)options {
    return [[CRStaticDirectoryManager alloc] initWithDirectoryAtPath:path prefix:prefix options:options];
}

- (instancetype)init {
    return  [self initWithDirectoryAtPath:NSBundle.mainBundle.bundlePath prefix:CRPathSeparator options:0];
}

- (instancetype)initWithDirectoryAtPath:(NSString *)path prefix:(NSString *)prefix {
    return [self initWithDirectoryAtPath:path prefix:prefix options:0];
}

@end

NSUInteger HTTPStatusCodeForError(NSError *error) {
    NSUInteger statusCode = 500;
    if ([error.domain isEqualToString:NSCocoaErrorDomain]) {
        switch (error.code) {
            case NSFileReadNoSuchFileError:
                statusCode = 404;
                break;
            case NSFileReadNoPermissionError:
                statusCode = 403;
                break;
            default:
                break;
        }
    } else if ([error.domain isEqualToString:CRStaticDirectoryManagerErrorDomain] ) {
        switch (error.code) {
            case CRStaticDirectoryManagerNotImplementedError:
                statusCode = 501;
                break;
            case CRStaticDirectoryManagerDirectoryListingForbiddenError:
                statusCode = 403;
                break;
            default:
                break;
        }
    }
    return statusCode;
}
