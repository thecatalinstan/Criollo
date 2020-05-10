//
//  CRStaticFileManager.m
//  Criollo
//
//  Created by Cătălin Stan on 10/03/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CRStaticFileManager.h"
#import "CRServer.h"
#import "CRServer_Internal.h"
#import "CRRequest.h"
#import "CRRequest_Internal.h"
#import "CRResponse.h"
#import "CRResponse_Internal.h"
#import "CRConnection.h"
#import "CRConnection_Internal.h"
#import "CRMimeTypeHelper.h"
#import "CRRequestRange.h"
#import "CRRouter_Internal.h"

NS_ASSUME_NONNULL_BEGIN

static NSUInteger const DispatchReadBufferSize = ((unsigned long long)8 * 1024 * 1024);
static NSUInteger const SendFileSizeThreshold = ((unsigned long long)8 * 64 * 1024);

static NSErrorDomain const CRStaticFileManagerErrorDomain = @"CRStaticFileManagerErrorDomain";

static NSUInteger const CRStaticFileManagerFileReadError                = 102;
static NSUInteger const CRStaticFileManagerFileIsDirectoryError         = 103;

static NSUInteger const CRStaticFileManagerNullFileTypeError            = 201;
static NSUInteger const CRStaticFileManagerRestrictedFileTypeError      = 202;
static NSUInteger const CRStaticFileManagerRangeNotSatisfiableError     = 203;

static NSUInteger const CRStaticFileManagerNotImplementedError          = 999;

static NSString * CRStaticFileContentDispositionNoneValue = @"none";
static NSString * CRStaticFileContentDispositionInlineValue = @"inline";
static NSString * CRStaticFileContentDispositionAttachmentValue = @"attachment";

NS_INLINE NSString * NSStringFromCRStaticFileContentDisposition(CRStaticFileContentDisposition contentDisposition);
NS_INLINE CRStaticFileContentDisposition CRStaticFileContentDispositionMake(NSString * contentDispositionName);

NS_INLINE NSUInteger HTTPStatusCodeForError(NSError *error);

@interface CRStaticFileManager ()

@end

NS_ASSUME_NONNULL_END

@implementation CRStaticFileManager

- (instancetype)initWithFileAtPath:(NSString *)path
                           options:(CRStaticFileServingOptions)options
                          fileName:(NSString *)fileName
                       contentType:(NSString *)contentType
                contentDisposition:(CRStaticFileContentDisposition)contentDisposition
                        attributes:(NSDictionary<NSFileAttributeKey, id> *)attributes {
    
    self = [super init];
    if ( self != nil ) {
        path = path.stringByStandardizingPath;
        if (options & CRStaticFileServingOptionsFollowSymlinks) {
            path = path.stringByResolvingSymlinksInPath;
        }
        fileName = fileName ?: path.lastPathComponent;
        contentType = contentType ?: [CRMimeTypeHelper.sharedHelper mimeTypeForFileAtPath:path];
        if (contentDisposition == CRStaticFileContentDispositionNone) {
            if ([contentType hasPrefix:@"application/octet-stream"]) {
                contentDisposition = CRStaticFileContentDispositionAttachment;
            } else {
                contentDisposition = CRStaticFileContentDispositionInline;
            }
        }
        
         __weak typeof (self) wself = self;
        _routeBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock _Nonnull completion) {
            
            NSError *error;
            NSDictionary<NSFileAttributeKey, id> *attr = attributes;
            if (!attr && !(attr = [NSFileManager.defaultManager attributesOfItemAtPath:path error:&error])) {
                goto error;
            }
            
            if (![wself canHandleFileType:attr.fileType path:path error:&error]) {
                goto error;
            }
                    
            if (![wself serveFileAtPath:path fileName:fileName contentType:contentType contentDisposition:contentDisposition size:attr.fileSize cached:(options & CRStaticFileServingOptionsCache) request:request response:response completion:completion error:&error]) {
                goto error;
            }
            
            return;
            
        error:
            [wself handleErrorResponse:error request:request response:response completion:completion];
        };
    }
    return self;
}

- (void)handleErrorResponse:(NSError *)error request:(CRRequest *)request response:(CRResponse *)response completion:(CRRouteCompletionBlock)completion {
    [CRRouter handleErrorResponse:HTTPStatusCodeForError(error) error:error request:request response:response completion:completion];
}

- (BOOL)serveFileAtPath:(NSString *)path
               fileName:(NSString *)fileName
            contentType:(NSString *)contentType
     contentDisposition:(CRStaticFileContentDisposition)contentDisposition
                   size:(unsigned long long)size
                 cached:(BOOL)cached
                request:(CRRequest *)request
               response:(CRResponse *)response
             completion:(CRRouteCompletionBlock)completion
                  error:(NSError *__autoreleasing *)error {
    
    NSError *err;
    NSRange requestDataRange;
    BOOL partial;
    
    // Configure the response headers before we actually start serving the file
    CRRequestRange *requestRange = request.range;
    NSDictionary<NSString *, NSString *> *headers = [self responseHeadersForByteRangeSet:requestRange.byteRangeSet path:path fileName:fileName contentType:contentType contentDisposition:contentDisposition size:size bytesUnit:requestRange.bytesUnit dataRange:&requestDataRange partial:&partial error:&err];
    [response setAllHTTPHeaderFields:headers];
    if (err) {
        goto error;
    }
    
    // Set the partial response status code
    if (partial) {
        [response setStatusCode:206 description:nil];
    }
        
    // Read synchronously if the file size is below threshold
    if ( size <= SendFileSizeThreshold ) {
        if(![self sendFileAtPath:path dataRange:requestDataRange cached:cached response:response  completion:completion error:&err]) {
            goto error;
        }
    } else {
        if(![self dispatchFileAtPath:path size:size dataRange:requestDataRange request:request response:response completion:completion error:&err]) {
            goto error;
        }
    }
    
    return YES;
    
error:
    if(error != NULL) {
        *error = err;
    }
    return NO;
}

- (BOOL)sendFileAtPath:(NSString *)path
             dataRange:(NSRange)dataRange
                cached:(BOOL)cached
              response:(CRResponse *)response
            completion:(CRRouteCompletionBlock)completion
                 error:(NSError *__autoreleasing *)error {
    NSData *data;
    if (!(data = [NSData dataWithContentsOfFile:path options:(cached ? NSDataReadingMappedIfSafe : NSDataReadingUncached) error:error])) {
        return NO;
    }
    
    if (dataRange.location != NSNotFound) {
        data = [NSData dataWithBytesNoCopy:(void *)data.bytes + dataRange.location length:dataRange.length freeWhenDone:NO];
    }
    
    [response sendData:data];
    completion();
    
    return YES;
}

- (BOOL)dispatchFileAtPath:(NSString *)path
                      size:(unsigned long long)size
                 dataRange:(NSRange)dataRange
                   request:(CRRequest *)request
                  response:(CRResponse *)response
                completion:(CRRouteCompletionBlock)completion
                     error:(NSError *__autoreleasing *)error {

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __weak typeof(self) wself = self;
    __block BOOL didStartSendingFile = NO;
    
    __block BOOL result = YES;
    __block NSError *err;
    void (^cleanup)(int) = ^(int errnum) {
        if (errnum && !didStartSendingFile) {
            NSMutableDictionary<NSErrorUserInfoKey, id> *info = [NSMutableDictionary dictionaryWithCapacity:1];
            info[NSLocalizedDescriptionKey] = [NSString stringWithCString:strerror(errnum) encoding:NSUTF8StringEncoding];
            NSError *underlyingError = [NSError errorWithDomain:NSPOSIXErrorDomain code:(NSUInteger)errnum userInfo:info];
            err = [wself errorWithCode:CRStaticFileManagerFileReadError description:NSLocalizedString(@"File read channel released with error.",) path:path underlyingError:underlyingError];
            result = NO;
        }
         
        dispatch_semaphore_signal(semaphore);
    };
    
    dispatch_queue_t queue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(queue, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0));
    
    dispatch_io_t channel = dispatch_io_create_with_path(DISPATCH_IO_RANDOM, path.UTF8String, O_RDONLY, 0, queue, cleanup);
    dispatch_io_set_low_water(channel, SendFileSizeThreshold);
    dispatch_io_set_high_water(channel, DispatchReadBufferSize);
        
    dispatch_io_handler_t read = ^(bool done, dispatch_data_t data, int errnum) {
        if (request.connection == nil || response.connection == nil) {
            dispatch_io_close(channel, DISPATCH_IO_STOP);
            return;
        }
        
        if (errnum) {
            // we handle the error in the cleanup block
            dispatch_io_close(channel, DISPATCH_IO_STOP);
            return;
        }
        
        if (data) {
            didStartSendingFile = YES;
            [response writeData:(NSData *)data];
        }
        
        if (done) {
            dispatch_io_close(channel, 0);
        }
    };
    
    BOOL range = dataRange.location != NSNotFound;
    off_t offset = range ? dataRange.location : 0;
    size_t length = range ? dataRange.length : size;
    dispatch_io_read(channel, offset, length, queue, read);
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    if (error != NULL) {
        *error = err;
    }
    
    if (!err) {
        [response finish];
        completion();
    }
    
    return result;
}


- (BOOL)canHandleFileType:(NSString *)fileType path:(NSString *)path error:(NSError *__autoreleasing *)error {
    NSInteger code = 0;
    NSString *description;
    if(!fileType) {
        code = CRStaticFileManagerNullFileTypeError;
        description = @"Unable to determine the requested file's type.";
    } else if ([fileType isEqualToString:NSFileTypeDirectory]) {
        code = CRStaticFileManagerFileIsDirectoryError;
        description = @"The requested file is a directory.";
    } else if (![fileType isEqualToString:NSFileTypeRegular]) {
        code = CRStaticFileManagerRestrictedFileTypeError;
        description = [NSString stringWithFormat:@"Files of type “%@” are restricted.", fileType];
    }
    
    if(code != 0 && error != NULL) {
        *error = [self errorWithCode:code description:description path:path underlyingError:nil];
    }
    
    return code == 0;
}

/// Determines the appropriate values for the HTTP headers relevant for the response:
/// @c Content-length, @c Content-range, @c Accept-Ranges, @c Content-Type and
/// @c Content-Disposition
- (NSDictionary<NSString *, NSString *> *)responseHeadersForByteRangeSet:(NSArray<CRRequestByteRange *> *)requestByteRangeSet
                                                                path:(NSString *)path
                                                                fileName:(NSString *)fileName
                                                             contentType:(NSString *)contentType
                                                      contentDisposition:(CRStaticFileContentDisposition)contentDisposition
                                                                size:(unsigned long long)size
                                                               bytesUnit:(NSString *)bytesUnit
                                                               dataRange:(NSRange *)dataRange
                                                                 partial:(BOOL *)partial
                                                                   error:(NSError *__autoreleasing *)error {
    NSError *err;
    NSMutableDictionary<NSString *, NSString *> *headers = [NSMutableDictionary dictionaryWithCapacity:3];
    
    headers[@"Content-Type"] = contentType;
    headers[@"Content-Disposition"] = [NSString stringWithFormat:@"%@; filename=\"%@\"", NSStringFromCRStaticFileContentDisposition(contentDisposition), [fileName stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
    
    // In any case, let the client know that we can handle byte ranges
    headers[@"Accept-Ranges"] = CRRequestRange.acceptRangesSpec;
    
    NSRange requestDataRange = NSMakeRange(NSNotFound, 0);
    CRRequestByteRange *requestByteRange;
        
    // We do not (yet) support multipart byte-ranges so bailout early with a
    // "not implemented" errpr
    if (requestByteRangeSet.count > 1) {
        err = [self errorWithCode:CRStaticFileManagerNotImplementedError description:@"Multiple range (multipart/byte-range) responses are not implemented." path:path underlyingError:nil];
        goto done;
    }

    // If we do not have a "Range" request, just set the content-length
    if (!(requestByteRange = requestByteRangeSet.firstObject)) {
        headers[@"Content-Length"] = @(size).stringValue;
        headers[@"Connection"] = @"close";
        goto done;
    }
        
    // If we cannot satisfy the byte range, return an error
    if (![requestByteRange isSatisfiableForFileSize:size dataRange:&requestDataRange]) {
        NSString *description = [NSString stringWithFormat:NSLocalizedString(@"The requested byte-range %@-%@ / %lu could not be satisfied.",), requestByteRange.firstBytePos, requestByteRange.lastBytePos, size];
        err = [self errorWithCode:CRStaticFileManagerRangeNotSatisfiableError description:description path:path underlyingError:nil];
        goto done;
    }
    
    headers[@"Content-Range"] = [NSString stringWithFormat:@"%@ %@", bytesUnit, [requestByteRange contentRangeSpecForFileSize:size satisfiable:YES dataRange:requestDataRange]];
    headers[@"Content-Length"] = [requestByteRange contentLengthSpecForFileSize:size satisfiable:YES dataRange:requestDataRange];
    
done:
    if (dataRange != NULL) {
        *dataRange = requestDataRange;
    }

    if (partial != NULL) {
        *partial = requestDataRange.location != NSNotFound || (requestDataRange.location == 0 && requestDataRange.length == size);
    }
    
    if (error != NULL) {
        *error = err;
    }
    
    return headers;
}

- (NSError *)errorWithCode:(NSUInteger)code description:(NSString *)description path:(NSString *)path underlyingError:(NSError * _Nullable)underlyingError {
    NSMutableDictionary<NSErrorUserInfoKey, id> *info = [NSMutableDictionary dictionaryWithCapacity:3];
    info[NSLocalizedDescriptionKey] = description;
    info[NSFilePathErrorKey] = path;
    info[NSUnderlyingErrorKey] = underlyingError;
    return [NSError errorWithDomain:CRStaticFileManagerErrorDomain code:code userInfo:info];
}

#pragma mark - Convenience Class Initializers

+ (instancetype)managerWithFileAtPath:(NSString *)path {
    return [[CRStaticFileManager alloc] initWithFileAtPath:path options:0 fileName:nil contentType:nil contentDisposition:CRStaticFileContentDispositionNone attributes:nil];
}

+ (instancetype)managerWithFileAtPath:(NSString *)path options:(CRStaticFileServingOptions)options {
    return [[CRStaticFileManager alloc] initWithFileAtPath:path options:options fileName:nil contentType:nil contentDisposition:CRStaticFileContentDispositionNone attributes:nil];
}

+ (instancetype)managerWithFileAtPath:(NSString *)path options:(CRStaticFileServingOptions)options fileName:(NSString * _Nullable)fileName {
    return [[CRStaticFileManager alloc] initWithFileAtPath:path options:options fileName:fileName contentType:nil contentDisposition:CRStaticFileContentDispositionNone attributes:nil];
}

+ (instancetype)managerWithFileAtPath:(NSString *)path options:(CRStaticFileServingOptions)options fileName:(NSString * _Nullable)fileName contentType:(NSString * _Nullable)contentType {
    return [[CRStaticFileManager alloc] initWithFileAtPath:path options:options fileName:fileName contentType:contentType contentDisposition:CRStaticFileContentDispositionNone attributes:nil];
}

+ (instancetype)managerWithFileAtPath:(NSString *)path options:(CRStaticFileServingOptions)options fileName:(NSString * _Nullable)fileName contentType:(NSString * _Nullable)contentType contentDisposition:(CRStaticFileContentDisposition)contentDisposition {
    return [[CRStaticFileManager alloc] initWithFileAtPath:path options:options fileName:fileName contentType:contentType contentDisposition:contentDisposition attributes:nil];
}

+ (instancetype)managerWithFileAtPath:(NSString *)path options:(CRStaticFileServingOptions)options fileName:(NSString * _Nullable)fileName contentType:(NSString * _Nullable)contentType contentDisposition:(CRStaticFileContentDisposition)contentDisposition attributes:(NSDictionary<NSFileAttributeKey, id> * _Nullable)attributes {
    return [[CRStaticFileManager alloc] initWithFileAtPath:path options:options fileName:fileName contentType:contentType contentDisposition:contentDisposition attributes:attributes];
}

#pragma mark - Convenience Initializers

- (instancetype)init {
    return  [self initWithFileAtPath:@"" options:0 fileName:nil contentType:nil contentDisposition:CRStaticFileContentDispositionNone attributes:nil];
}

- (instancetype)initWithFileAtPath:(NSString *)path {
    return [self initWithFileAtPath:path options:0 fileName:nil contentType:nil contentDisposition:CRStaticFileContentDispositionNone attributes:nil];
}

- (instancetype)initWithFileAtPath:(NSString *)path options:(CRStaticFileServingOptions)options {
    return [self initWithFileAtPath:path options:options fileName:nil contentType:nil contentDisposition:CRStaticFileContentDispositionNone attributes:nil];
}

- (instancetype)initWithFileAtPath:(NSString *)path options:(CRStaticFileServingOptions)options fileName:(NSString * _Nullable)fileName {
    return [self initWithFileAtPath:path options:options fileName:fileName contentType:nil contentDisposition:CRStaticFileContentDispositionNone attributes:nil];
}

- (instancetype)initWithFileAtPath:(NSString *)path options:(CRStaticFileServingOptions)options fileName:(NSString * _Nullable)fileName contentType:(NSString * _Nullable)contentType {
    return [self initWithFileAtPath:path options:options fileName:fileName contentType:contentType contentDisposition:CRStaticFileContentDispositionNone attributes:nil];
}

- (instancetype)initWithFileAtPath:(NSString *)path options:(CRStaticFileServingOptions)options fileName:(NSString * _Nullable)fileName contentType:(NSString * _Nullable)contentType contentDisposition:(CRStaticFileContentDisposition)contentDisposition {
    return [self initWithFileAtPath:path options:options fileName:fileName contentType:contentType contentDisposition:contentDisposition attributes:nil];
}

@end

NSString * NSStringFromCRStaticFileContentDisposition(CRStaticFileContentDisposition contentDisposition) {
    switch (contentDisposition) {
        case CRStaticFileContentDispositionNone:
            return CRStaticFileContentDispositionNoneValue;
        case CRStaticFileContentDispositionInline:
            return CRStaticFileContentDispositionInlineValue;
        case CRStaticFileContentDispositionAttachment:
            return CRStaticFileContentDispositionAttachmentValue;
    }
}

__attribute__((unused)) CRStaticFileContentDisposition CRStaticFileContentDispositionMake(NSString * contentDispositionName) {
    CRStaticFileContentDisposition contentDisposition;
    if ( [contentDispositionName isEqualToString:CRStaticFileContentDispositionInlineValue] ) {
        contentDisposition = CRStaticFileContentDispositionInline;
    } else if ( [contentDispositionName isEqualToString:CRStaticFileContentDispositionAttachmentValue] ) {
        contentDisposition = CRStaticFileContentDispositionAttachment;
    } else {
        contentDisposition = CRStaticFileContentDispositionNone;
    }
    return contentDisposition;
}

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
    } else if ([error.domain isEqualToString:CRStaticFileManagerErrorDomain] ) {
        switch (error.code) {
            case CRStaticFileManagerNotImplementedError:
                statusCode = 501;
                break;
            case CRStaticFileManagerRangeNotSatisfiableError:
                statusCode = 416;
                break;
            default:
                break;
        }
    }
    return statusCode;
}
