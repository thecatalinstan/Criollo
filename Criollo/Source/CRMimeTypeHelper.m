//
//  CRMimeTypeHelper.m
//  Criollo
//
//  Created by Cătălin Stan on 2/11/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CRMimeTypeHelper.h"

@interface CRMimeTypeHelper () {

}

@property (nonatomic, strong, nonnull, readonly) NSMutableDictionary<NSString *, NSString *> *mimeTypes;

@end

@implementation CRMimeTypeHelper

+ (instancetype)sharedHelper {
    static CRMimeTypeHelper *sharedHelper;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHelper = [[CRMimeTypeHelper alloc] init];
    });
    return sharedHelper;
}

- (instancetype)init {
    self = [super init];
    if ( self != nil ) {
        _mimeTypes = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)mimeTypeForFileAtPath:(NSString *)path {
    NSString *fileExtension = path.pathExtension;
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if ( contentType.length == 0 ) {
        if ( UTTypeConformsTo((__bridge CFStringRef _Nonnull)(UTI), kUTTypeText) ) {
            contentType = @"text/plain; charset=utf-8";
        } else if ( UTTypeConformsTo((__bridge CFStringRef _Nonnull)(UTI), kUTTypeSourceCode) ) {
            contentType = @"text/plain; charset=utf-8";
        } else if ( UTTypeConformsTo((__bridge CFStringRef _Nonnull)(UTI), kUTTypeXMLPropertyList) ) {
            contentType = @"application/xml; charset=utf-8";
        } else {
            contentType = @"application/octet-stream; charset=binary";
        }
    }
    if ( UTTypeConformsTo((__bridge CFStringRef _Nonnull)(UTI), kUTTypeText) ) {
        contentType = [contentType stringByAppendingString:@"; charset=utf-8"];
    }
    return contentType;
}


@end
