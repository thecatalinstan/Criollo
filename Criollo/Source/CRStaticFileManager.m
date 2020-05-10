//
//  CRStaticFileManager.m
//  Criollo
//
//  Created by Cătălin Stan on 10/03/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CRStaticFileManager.h"
#import "CRStaticFileManager_Internal.h"
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

static NSUInteger const SendFileSizeThreshold = ((unsigned long long)8 * 64 * 1024);

static NSUInteger const DispatchIOLoWater = ((unsigned long long)2 * 1024 * 1024);
static NSUInteger const DispatchIOHiWater = ((unsigned long long)8 * 1024 * 1024);

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

@property (nonatomic, strong, readonly) NSString *path;
@property (nonatomic, readonly) CRStaticFileServingOptions options;
@property (nonatomic, strong, readonly) NSString *fileName;
@property (nonatomic, strong, readonly) NSString *contentType;
@property (nonatomic, readonly) CRStaticFileContentDisposition contentDisposition;
@property (nonatomic, strong, readonly, nullable) NSDictionary<NSFileAttributeKey, id> *attributes;

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
        _options = options;
        _path = path.stringByStandardizingPath;
        if (_options & CRStaticFileServingOptionsFollowSymlinks) {
            _path = _path.stringByResolvingSymlinksInPath;
        }
        _fileName = _fileName ?: _path.lastPathComponent;
        _contentType = contentType ?: [CRMimeTypeHelper.sharedHelper mimeTypeForFileAtPath:_path];
        if (_contentDisposition == CRStaticFileContentDispositionNone) {
            if ([_contentType hasPrefix:@"application/octet-stream"]) {
                _contentDisposition = CRStaticFileContentDispositionAttachment;
            } else {
                _contentDisposition = CRStaticFileContentDispositionInline;
            }
        }
        
         __weak typeof (self) wself = self;
        _routeBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock _Nonnull completion) {
            [wself handleRequest:request response:response completion:completion];
        };
    }
    return self;
}

- (void)handleRequest:(CRRequest *)request response:(CRResponse *)response completion:(CRRouteCompletionBlock)completion  {
    NSRange requestDataRange;
    BOOL partial;
    NSDictionary<NSString *, NSString *> *headers;
    
    NSError *error;
    if (!_attributes && !(_attributes = [NSFileManager.defaultManager attributesOfItemAtPath:_path error:&error])) {
        goto error;
    }
    
    if (![self canHandleFileType:_attributes.fileType error:&error]) {
        goto error;
    }
    
    // Configure the response headers before we actually start serving the file
    headers = [self responseHeadersForRange:request.range dataRange:&requestDataRange partial:&partial error:&error];
    [response setAllHTTPHeaderFields:headers];
    if (error) {
        goto error;
    }
    
    // Set the partial response status code
    if (partial) {
        [response setStatusCode:206 description:nil];
    }
        
    // Read synchronously if the file size is below threshold
    if ( _attributes.fileSize <= SendFileSizeThreshold ) {
        if(![self sendFileDataRange:requestDataRange response:response completion:completion error:&error]) {
            goto error;
        }
    } else {
        if(![self dispatchDataRange:requestDataRange request:request response:response completion:completion error:&error]) {
            goto error;
        }
    }
        
    return;
    
error:
    [self handleError:error request:request response:response completion:completion];
}

- (BOOL)sendFileDataRange:(NSRange)dataRange response:(CRResponse *)response completion:(CRRouteCompletionBlock)completion error:(NSError *__autoreleasing *)error {
    NSData *data;
    if (!(data = [NSData dataWithContentsOfFile:_path options:((_options & CRStaticFileServingOptionsCache) ? NSDataReadingMappedIfSafe : NSDataReadingUncached) error:error])) {
        return NO;
    }
    
    if (dataRange.location != NSNotFound) {
        data = [NSData dataWithBytesNoCopy:(void *)data.bytes + dataRange.location length:dataRange.length freeWhenDone:NO];
    }
    
    [response sendData:data];
    completion();
    
    return YES;
}

- (BOOL)dispatchDataRange:(NSRange)dataRange request:(CRRequest *)request response:(CRResponse *)response completion:(CRRouteCompletionBlock)completion error:(NSError *__autoreleasing *)error {

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
            err = [wself errorWithCode:CRStaticFileManagerFileReadError description:NSLocalizedString(@"File read channel released with error.",) underlyingError:underlyingError];
            result = NO;
        }
         
        dispatch_semaphore_signal(semaphore);
    };
    
    dispatch_queue_t queue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(queue, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0));
    
    dispatch_io_t channel = dispatch_io_create_with_path(DISPATCH_IO_RANDOM, _path.UTF8String, O_RDONLY, 0, queue, cleanup);
    dispatch_io_set_low_water(channel, DispatchIOLoWater);
    dispatch_io_set_high_water(channel, DispatchIOHiWater);
        
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
    size_t length = range ? dataRange.length : _attributes.fileSize;
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

- (void)handleError:(NSError *)error request:(CRRequest *)request response:(CRResponse *)response completion:(CRRouteCompletionBlock)completion {
    [CRRouter handleErrorResponse:HTTPStatusCodeForError(error) error:error request:request response:response completion:completion];
}

- (BOOL)canHandleFileType:(NSString *)fileType error:(NSError *__autoreleasing *)error {
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
        *error = [self errorWithCode:code description:description underlyingError:nil];
    }
    
    return code == 0;
}

- (NSDictionary<NSString *, NSString *> *)responseHeadersForRange:(CRRequestRange *)range dataRange:(NSRange *)dataRange partial:(BOOL *)partial error:(NSError *__autoreleasing *)error {
    CRRequestByteRange *requestByteRange;
    NSArray<CRRequestByteRange *> *requestByteRangeSet = range.byteRangeSet;
    NSRange requestDataRange = NSMakeRange(NSNotFound, 0);
    unsigned long long size = _attributes.fileSize;
    
    NSError *err;
    NSMutableDictionary<NSString *, NSString *> *headers = [NSMutableDictionary dictionaryWithCapacity:5];
    
    headers[@"Content-Type"] = _contentType;
    headers[@"Content-Disposition"] = [NSString stringWithFormat:@"%@; filename=\"%@\"", NSStringFromCRStaticFileContentDisposition(_contentDisposition), [_fileName stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
    
    // In any case, let the client know that we can handle byte ranges
    headers[@"Accept-Ranges"] = CRRequestRange.acceptRangesSpec;
    
            
    // We do not (yet) support multipart byte-ranges so bailout early with a
    // "not implemented" errpr
    if (requestByteRangeSet.count > 1) {
        err = [self errorWithCode:CRStaticFileManagerNotImplementedError description:@"Multiple range (multipart/byte-range) responses are not implemented." underlyingError:nil];
        goto done;
    }

    // If we do not have a "Range" request, just set the content-length    
    if (!(requestByteRange = requestByteRangeSet.firstObject)) {
        headers[@"Content-Length"] = [NSString stringWithFormat:@"%llu", size];
        headers[@"Connection"] = @"close";
        goto done;
    }
        
    // If we cannot satisfy the byte range, return an error
    if (![requestByteRange isSatisfiableForFileSize:size dataRange:&requestDataRange]) {
        NSString *description = [NSString stringWithFormat:NSLocalizedString(@"The requested byte-range %@-%@ / %lu could not be satisfied.",), requestByteRange.firstBytePos, requestByteRange.lastBytePos, size];
        err = [self errorWithCode:CRStaticFileManagerRangeNotSatisfiableError description:description underlyingError:nil];
        goto done;
    }
    
    headers[@"Content-Range"] = [NSString stringWithFormat:@"%@ %@", range.bytesUnit, [requestByteRange contentRangeSpecForFileSize:size satisfiable:YES dataRange:requestDataRange]];
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

- (NSError *)errorWithCode:(NSUInteger)code description:(NSString *)description underlyingError:(NSError * _Nullable)underlyingError {
    NSMutableDictionary<NSErrorUserInfoKey, id> *info = [NSMutableDictionary dictionaryWithCapacity:3];
    info[NSLocalizedDescriptionKey] = description;
    info[NSFilePathErrorKey] = _path;
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
