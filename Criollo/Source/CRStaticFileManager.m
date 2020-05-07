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

NS_ASSUME_NONNULL_BEGIN

static NSUInteger const CRStaticFileServingReadBuffer = 8e+6;
static NSUInteger const CRStaticFileServingReadThreshold = 8 * 64 * 1024;

static NSErrorDomain const CRStaticFileManagerErrorDomain = @"CRStaticFileManagerErrorDomain";

static NSUInteger const CRStaticFileManagerReleaseFailedError           = 101;
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

@interface CRStaticFileManager ()

+ (CRRouteBlock)servingBlockForFileAtPath:(NSString *)filePath fileName:(NSString * _Nullable)fileName contentType:(NSString * _Nullable)contentType contentDisposition:(CRStaticFileContentDisposition)contentDisposition fileSize:(NSUInteger)fileSize shouldCache:(BOOL)shouldCache fileReadingQueue:(dispatch_queue_t)fileReadingQueue;
- (CRRouteBlock)errorHandlerBlockForError:(NSError *)error;

NS_ASSUME_NONNULL_END

@end

@implementation CRStaticFileManager

- (instancetype)initWithFileAtPath:(NSString *)filePath
                           options:(CRStaticFileServingOptions)options
                          fileName:(NSString *)fileName
                       contentType:(NSString *)contentType
                contentDisposition:(CRStaticFileContentDisposition)contentDisposition
                        attributes:(NSDictionary *)attributes {
    
    self = [super init];
    if ( self != nil ) {
        filePath = filePath.stringByStandardizingPath;
        if (options & CRStaticFileServingOptionsFollowSymlinks) {
            filePath = filePath.stringByResolvingSymlinksInPath;
        }
        fileName = fileName ?: filePath.lastPathComponent;
        contentType = contentType ?: [CRMimeTypeHelper.sharedHelper mimeTypeForFileAtPath:filePath];
        if (contentDisposition == CRStaticFileContentDispositionNone) {
            if ([contentType isEqualToString:@"application/octet-stream"]) {
                contentDisposition = CRStaticFileContentDispositionAttachment;
            } else {
                contentDisposition = CRStaticFileContentDispositionInline;
            }
        }
    
        NSError *error;
        if ((attributes = attributes ?: [NSFileManager.defaultManager attributesOfItemAtPath:filePath error:&error]) ) {
            NSUInteger code = 0;
            NSString *fileType, *description;
            if(!(fileType = attributes.fileType)) {
                code = CRStaticFileManagerNullFileTypeError;
                description = @"Unable to determine the requested file's type.";
            } else if ([fileType isEqualToString:NSFileTypeDirectory]) {
                code = CRStaticFileManagerFileIsDirectoryError;
                description = @"The requested file is a directory.";
            } else if (![fileType isEqualToString:NSFileTypeRegular]) {
                code = CRStaticFileManagerRestrictedFileTypeError;
                description = [NSString stringWithFormat:@"Files of type “%@” are restricted.", fileType];
            }
            error = [self errorWithCode:code description:description path:filePath];
        }
        
        if (error) {
            _routeBlock = [self errorHandlerBlockForError:error];
        } else {
            _routeBlock = [self servingBlockForFileAtPath:filePath
                                                 fileName:fileName
                                              contentType:contentType
                                       contentDisposition:contentDisposition
                                                 fileSize:(NSUInteger)attributes.fileSize
                                              shouldCache:(options & CRStaticFileServingOptionsCache)];
            
        }
    }
    return self;
}

- (CRRouteBlock)errorHandlerBlockForError:(NSError *)error {
    NSUInteger statusCode = 500;
    if ([error.domain isEqualToString:NSCocoaErrorDomain]) {
        switch ( error.code ) {
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
        switch ( error.code ) {
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
    return [CRRouter errorHandlingBlockWithStatus:statusCode error:error];
}

+ (CRRouteBlock)servingBlockForFileAtPath:(NSString *)filePath fileName:(NSString * _Nullable)fileName contentType:(NSString * _Nullable)contentType contentDisposition:(CRStaticFileContentDisposition)contentDisposition fileSize:(NSUInteger)fileSize shouldCache:(BOOL)shouldCache fileReadingQueue:(nonnull dispatch_queue_t)fileReadingQueue {
    return ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        @autoreleasepool {
            // Send an unimplemented error if we are being requested to serve multipart byte-ranges
            if ( request.range.byteRangeSet.count > 1 ) {
                NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
                userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"Multiple range (multipart/byte-range) responses are not implemented.",);
                userInfo[NSURLErrorFailingURLErrorKey] = request.URL;
                userInfo[NSFilePathErrorKey] = filePath;
                NSError* rangeError = [NSError errorWithDomain:CRStaticFileManagerErrorDomain code:CRStaticFileManagerNotImplementedError userInfo:userInfo];
                [CRStaticFileManager errorHandlerBlockForError:rangeError](request, response, completionHandler);
                return;
            }

            // We are accepting byte ranges
            [response setValue:[CRRequestRange acceptRangesSpec] forHTTPHeaderField:@"Accept-Ranges"];

            CRRequestByteRange* requestByteRange;
            NSRange byteRangeDataRange = NSMakeRange(NSNotFound, 0);

            // Set the Content-length and Content-range headers
            if ( request.range.byteRangeSet.count > 0 ) {

                requestByteRange = request.range.byteRangeSet[0];
                byteRangeDataRange = [requestByteRange dataRangeForFileSize:fileSize];

                NSString* contentRangeSpec = [requestByteRange contentRangeSpecForFileSize:fileSize];
                contentRangeSpec = [NSString stringWithFormat:@"%@ %@", request.range.bytesUnit, contentRangeSpec];
                [response setValue:contentRangeSpec forHTTPHeaderField:@"Content-Range"];

                if ( [request.range isSatisfiableForFileSize:fileSize ] ) {                                // Set partial content response header
                    if ( byteRangeDataRange.location == 0 && byteRangeDataRange.length == fileSize ) {
                        [response setStatusCode:200 description:nil];
                    } else {
                        [response setStatusCode:206 description:nil];
                    }
                    NSString* conentLengthSpec = [requestByteRange contentLengthSpecForFileSize:fileSize];
                    [response setValue:conentLengthSpec forHTTPHeaderField:@"Content-Length"];
                } else {
                    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
                    userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:NSLocalizedString(@"The requested byte-range %@-%@ / %lu could not be satisfied.",), requestByteRange.firstBytePos, requestByteRange.lastBytePos, fileSize];
                    userInfo[NSURLErrorFailingURLErrorKey] = request.URL;
                    userInfo[NSFilePathErrorKey] = filePath;
                    NSError* rangeError = [NSError errorWithDomain:CRStaticFileManagerErrorDomain code:CRStaticFileManagerRangeNotSatisfiableError userInfo:userInfo];
                    [CRStaticFileManager errorHandlerBlockForError:rangeError](request, response, completionHandler);
                    return;
                }

            } else {
                [response setValue:@(fileSize).stringValue forHTTPHeaderField:@"Content-Length"];
            }

            // Set Content-Type and Content-Disposition
            [response setValue:contentType forHTTPHeaderField:@"Content-Type"];
            NSString* contentDispositionSpec = [NSString stringWithFormat:@"%@; filename=\"%@\"", NSStringFromCRStaticFileContentDisposition(contentDisposition), [fileName stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
            [response setValue:contentDispositionSpec forHTTPHeaderField:@"Content-Disposition"];

            // Read synchroniously if the file size is below threshold
            if ( fileSize <= CRStaticFileServingReadThreshold ) {

                NSError* fileReadError;
                NSData* fileData = [NSData dataWithContentsOfFile:filePath options:(shouldCache ? NSDataReadingMappedIfSafe : NSDataReadingUncached) error:&fileReadError];
                if ( fileData == nil && fileReadError != nil ) {
                    [CRStaticFileManager errorHandlerBlockForError:fileReadError](request, response, completionHandler);
                } else {
                    if ( request.range.byteRangeSet.count == 0 ) {
                        [response sendData:fileData];
                    } else {
                        NSData* requestedRangeData = [NSData dataWithBytesNoCopy:(void *)fileData.bytes + byteRangeDataRange.location length:byteRangeDataRange.length freeWhenDone:NO];
                        [response sendData:requestedRangeData];
                    }
                    completionHandler();
                }
            } else {
                __block BOOL didStartSendingFile = NO;
                dispatch_io_t fileReadChannel = dispatch_io_create_with_path(DISPATCH_IO_RANDOM, filePath.UTF8String, O_RDONLY, 0, fileReadingQueue,  ^(int error) {
                    @autoreleasepool {
                        if (error && !didStartSendingFile) {
                            NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
                            userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"There was an error releasing the file read channel.",);
                            userInfo[NSURLErrorFailingURLErrorKey] = request.URL;
                            userInfo[NSFilePathErrorKey] = filePath;
                            NSString* underlyingErrorDescription = [NSString stringWithCString:strerror(error) encoding:NSUTF8StringEncoding];
                            if ( underlyingErrorDescription.length > 0 ) {
                                NSError* underlyingError = [NSError errorWithDomain:NSPOSIXErrorDomain code:@(error).integerValue userInfo:@{NSLocalizedDescriptionKey: underlyingErrorDescription}];
                                userInfo[NSUnderlyingErrorKey] = underlyingError;
                            }
                            NSError* channelReleaseError = [NSError errorWithDomain:CRStaticFileManagerErrorDomain code:CRStaticFileManagerFileReadError userInfo:userInfo];
                            [CRStaticFileManager errorHandlerBlockForError:channelReleaseError](request, response, completionHandler);
                            return;
                        }
                        
                        completionHandler();
                        [response finish];
                    }
                });

                dispatch_io_set_high_water(fileReadChannel, CRStaticFileServingReadBuffer);
                dispatch_io_set_low_water(fileReadChannel, CRStaticFileServingReadThreshold);

                off_t offset = 0;
                size_t length = fileSize;
                if ( request.range.byteRangeSet.count > 0 ) {
                    offset = byteRangeDataRange.location;
                    length = byteRangeDataRange.length;
                }

                dispatch_io_read(fileReadChannel, offset, length, fileReadingQueue, ^(bool done, dispatch_data_t data, int error) {
                    @autoreleasepool {
                        if (request.connection == nil || response.connection == nil) {
                            dispatch_io_close(fileReadChannel, DISPATCH_IO_STOP);
                            return;
                        }

                        if (error) {
                            dispatch_io_close(fileReadChannel, DISPATCH_IO_STOP);
                            return;
                        }

                        if (data) {
                            didStartSendingFile = YES;
                            [response writeData:(NSData*)data];
                        }

                        if (done) {
                            dispatch_io_close(fileReadChannel, 0);
                        }
                    }
                });
            }
        }
    };
}

- (NSError *)errorWithCode:(NSUInteger)code description:(NSString *)description path:(NSString *)path {
    return [NSError errorWithDomain:CRStaticFileManagerErrorDomain code:code userInfo:@{
        NSLocalizedDescriptionKey: description,
        NSFilePathErrorKey: path
    }];
}

#pragma mark - Convenience Class Initializers

+ (instancetype)managerWithFileAtPath:(NSString *)filePath {
    return [[CRStaticFileManager alloc] initWithFileAtPath:filePath options:0 fileName:nil contentType:nil contentDisposition:CRStaticFileContentDispositionNone attributes:nil];
}

+ (instancetype)managerWithFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options {
    return [[CRStaticFileManager alloc] initWithFileAtPath:filePath options:options fileName:nil contentType:nil contentDisposition:CRStaticFileContentDispositionNone attributes:nil];
}

+ (instancetype)managerWithFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options fileName:(NSString * _Nullable)fileName {
    return [[CRStaticFileManager alloc] initWithFileAtPath:filePath options:options fileName:fileName contentType:nil contentDisposition:CRStaticFileContentDispositionNone attributes:nil];
}

+ (instancetype)managerWithFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options fileName:(NSString * _Nullable)fileName contentType:(NSString * _Nullable)contentType {
    return [[CRStaticFileManager alloc] initWithFileAtPath:filePath options:options fileName:fileName contentType:contentType contentDisposition:CRStaticFileContentDispositionNone attributes:nil];
}

+ (instancetype)managerWithFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options fileName:(NSString * _Nullable)fileName contentType:(NSString * _Nullable)contentType contentDisposition:(CRStaticFileContentDisposition)contentDisposition {
    return [[CRStaticFileManager alloc] initWithFileAtPath:filePath options:options fileName:fileName contentType:contentType contentDisposition:contentDisposition attributes:nil];
}

+ (instancetype)managerWithFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options fileName:(NSString * _Nullable)fileName contentType:(NSString * _Nullable)contentType contentDisposition:(CRStaticFileContentDisposition)contentDisposition attributes:(NSDictionary * _Nullable)attributes {
    return [[CRStaticFileManager alloc] initWithFileAtPath:filePath options:options fileName:fileName contentType:contentType contentDisposition:contentDisposition attributes:attributes];
}

#pragma mark - Convenience Initializers

- (instancetype)init {
    return  [self initWithFileAtPath:@"" options:0 fileName:nil contentType:nil contentDisposition:CRStaticFileContentDispositionNone attributes:nil];
}

- (instancetype)initWithFileAtPath:(NSString *)filePath {
    return [self initWithFileAtPath:filePath options:0 fileName:nil contentType:nil contentDisposition:CRStaticFileContentDispositionNone attributes:nil];
}

- (instancetype)initWithFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options {
    return [self initWithFileAtPath:filePath options:options fileName:nil contentType:nil contentDisposition:CRStaticFileContentDispositionNone attributes:nil];
}

- (instancetype)initWithFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options fileName:(NSString * _Nullable)fileName {
    return [self initWithFileAtPath:filePath options:options fileName:fileName contentType:nil contentDisposition:CRStaticFileContentDispositionNone attributes:nil];
}

- (instancetype)initWithFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options fileName:(NSString * _Nullable)fileName contentType:(NSString * _Nullable)contentType {
    return [self initWithFileAtPath:filePath options:options fileName:fileName contentType:contentType contentDisposition:CRStaticFileContentDispositionNone attributes:nil];
}

- (instancetype)initWithFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options fileName:(NSString * _Nullable)fileName contentType:(NSString * _Nullable)contentType contentDisposition:(CRStaticFileContentDisposition)contentDisposition {
    return [self initWithFileAtPath:filePath options:options fileName:fileName contentType:contentType contentDisposition:contentDisposition attributes:nil];
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
