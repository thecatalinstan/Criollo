//
//  CRStaticFileManager.m
//
//
//  Created by Cătălin Stan on 10/03/16.
//

#import <Criollo/CRStaticFileManager.h>

#import <Criollo/CRMimeTypeHelper.h>
#import <Criollo/CRRequestRange.h>

#import "CRRequest_Internal.h"
#import "CRResponse_Internal.h"
#import "CRRouter_Internal.h"
#import "CRStaticFileManager_Internal.h"

NS_ASSUME_NONNULL_BEGIN

static NSUInteger const SendFileSizeThreshold = ((unsigned long long)512 * 1024);

static NSUInteger const DispatchIOLoWater = ((unsigned long long)512 * 1024);
static NSUInteger const DispatchIOHiWater = ((unsigned long long)8192 * 1024);

static NSErrorDomain const CRStaticFileManagerErrorDomain = @"CRStaticFileManagerErrorDomain";
static NSUInteger const CRStaticFileManagerFileIsDirectoryError         = 103;
static NSUInteger const CRStaticFileManagerNullFileTypeError            = 201;
static NSUInteger const CRStaticFileManagerRestrictedFileTypeError      = 202;
static NSUInteger const CRStaticFileManagerRangeNotSatisfiableError     = 203;
static NSUInteger const CRStaticFileManagerNotImplementedError          = 999;

NS_INLINE NSUInteger HTTPStatusCodeForError(NSError *error);

@interface CRStaticFileManager ()

@property (nonatomic, readonly) NSString *path;
@property (nonatomic, readonly) CRStaticFileServingOptions options;
@property (nonatomic, readonly) NSString *fileName;
@property (nonatomic, readonly) NSString *contentType;
@property (nonatomic, readonly) CRContentDisposition contentDisposition;
@property (nonatomic, readonly, nullable) NSDictionary<NSFileAttributeKey, id> *attributes;

@end

NS_ASSUME_NONNULL_END

@implementation CRStaticFileManager

- (instancetype)initWithFileAtPath:(NSString *)path
                           options:(CRStaticFileServingOptions)options
                          fileName:(NSString *)fileName
                       contentType:(NSString *)contentType
                contentDisposition:(CRContentDisposition)contentDisposition
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
        if (!_contentDisposition) {
            if ([_contentType hasPrefix:@"application/octet-stream"]) {
                _contentDisposition = CRContentDispositionAttachment;
            } else {
                _contentDisposition = CRContentDispositionInline;
            }
        }
        
         __weak typeof (self) wself = self;
        _routeBlock = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, dispatch_block_t _Nonnull completion) {
            [wself handleRequest:request response:response completion:completion];
        };
    }
    return self;
}

- (void)handleRequest:(CRRequest *)request response:(CRResponse *)response completion:(dispatch_block_t)completion  {
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
    if (_attributes.fileSize <= SendFileSizeThreshold) {
        if(![self sendFileDataRange:requestDataRange partial:partial response:response completion:completion error:&error]) {
            goto error;
        }
    } else {
        if(![self dispatchDataRange:requestDataRange partial:partial request:request response:response completion:completion error:&error]) {
            goto error;
        }
    }
        
    return;
    
error:
    [self handleError:error request:request response:response completion:completion];
}

- (BOOL)sendFileDataRange:(NSRange)dataRange partial:(BOOL)partial response:(CRResponse *)response completion:(dispatch_block_t)completion error:(NSError *__autoreleasing *)error {

    off_t offset = partial ? dataRange.location : 0;
    size_t length = partial ? dataRange.length : (size_t)_attributes.fileSize;
        
    NSData *data;
    size_t read;
    void *buf = NULL;
    
    FILE *handle;
    if (!(handle = fopen(_path.UTF8String, "r"))) {
        goto error;
    }
    
    if(0 != fseeko(handle, offset, SEEK_SET)) {
        goto error;
    }
    
    buf = calloc(length, sizeof(char));
    if(length != (read = fread(buf, sizeof(char), length, handle))) {
        if (ferror(handle)) {
            goto error;
        } else if (feof(handle)) {
            length = read;
            buf = realloc(buf, length);
        }
    }
    
    if(0 != fclose(handle)) {
        goto error;
    }

    data = [NSData dataWithBytesNoCopy:buf length:length freeWhenDone:YES];
    [response setValue:@(data.length).stringValue forHTTPHeaderField:@"Content-Length"];
    [response sendData:data];
    completion();
    
    return YES;
error:
    free(buf);
    if (error != NULL) {
        *error = [self errorWithErrNum:errno];
    }
    
    return NO;
}

- (BOOL)dispatchDataRange:(NSRange)dataRange partial:(BOOL)partial request:(CRRequest *)request response:(CRResponse *)response completion:(dispatch_block_t)completion error:(NSError *__autoreleasing *)error {

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __weak typeof(self) wself = self;
    __block BOOL didStartSendingFile = NO;
    
    __block BOOL result = YES;
    __block NSError *err;
    
    void (^cleanup)(int) = ^(int errnum) {
        if (errnum && !didStartSendingFile) {
            err = [wself errorWithErrNum:errnum];
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
        if (!request.connection || !response.connection) {
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
    
    off_t offset = partial ? dataRange.location : 0;
    size_t length = partial ? dataRange.length : (size_t)_attributes.fileSize;
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

- (void)handleError:(NSError *)error request:(CRRequest *)request response:(CRResponse *)response completion:(dispatch_block_t)completion {
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
    headers[@"Content-Disposition"] = [NSString stringWithFormat:@"%@; filename=\"%@\"", self.contentDisposition, [self.fileName stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
    
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
        // set the the unsatisfyiable conent range header
        headers[@"Content-range"] = [NSString stringWithFormat:@"%@ %@", range.bytesUnit, [requestByteRange contentRangeSpecForFileSize:size satisfiable:NO dataRange:requestDataRange]];
        NSString *description = [NSString stringWithFormat:NSLocalizedString(@"The requested byte-range %@-%@ / %llu could not be satisfied.",), requestByteRange.firstBytePos, requestByteRange.lastBytePos, size];
        err = [self errorWithCode:CRStaticFileManagerRangeNotSatisfiableError description:description underlyingError:nil];
        goto done;
    }
    
    headers[@"Content-Range"] = [NSString stringWithFormat:@"%@ %@", range.bytesUnit, [requestByteRange contentRangeSpecForFileSize:size satisfiable:YES dataRange:requestDataRange]];
    headers[@"Content-Length"] = [requestByteRange contentLengthSpecForFileSize:size satisfiable:YES dataRange:requestDataRange];
    headers[@"Connection"] = @"close";
    
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

- (NSError *)errorWithErrNum:(int)errnum {
    NSMutableDictionary<NSErrorUserInfoKey, id> *info = [NSMutableDictionary dictionaryWithCapacity:1];
    info[NSLocalizedDescriptionKey] = [NSString stringWithCString:strerror(errnum) encoding:NSUTF8StringEncoding];
    return [NSError errorWithDomain:NSPOSIXErrorDomain code:(NSUInteger)errnum userInfo:info];
}

- (NSError *)errorWithCode:(NSUInteger)code description:(NSString *)description underlyingError:(NSError * _Nullable)underlyingError {
    NSMutableDictionary<NSErrorUserInfoKey, id> *info = [NSMutableDictionary dictionaryWithCapacity:3];
    info[NSLocalizedDescriptionKey] = description;
    info[NSFilePathErrorKey] = _path;
    info[NSUnderlyingErrorKey] = underlyingError;
    return [NSError errorWithDomain:CRStaticFileManagerErrorDomain code:code userInfo:info];
}

+ (instancetype)managerWithFileAtPath:(NSString *)path options:(CRStaticFileServingOptions)options {
    return [[CRStaticFileManager alloc] initWithFileAtPath:path options:options fileName:nil contentType:nil contentDisposition:nil attributes:nil];
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
