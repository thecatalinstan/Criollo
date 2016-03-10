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

#define CRStaticFileServingReadBuffer                              (8 * 1024 * 1024)
#define CRStaticFileServingReadThreshold                           (8 * 64 * 1024)

#define CRStaticFileManagerErrorDomain                             @"CRStaticFileManagerErrorDomain"

#define CRStaticFileManagerReleaseFailedError                      101
#define CRStaticFileManagerFileReadError                           102
#define CRStaticFileManagerFileIsDirectoryError                    103

#define CRStaticFileManagerRestrictedFileTypeError                 201
#define CRStaticFileManagerRangeNotSatisfiableError                202

#define CRStaticFileManagerNotImplementedError                     999

@interface CRStaticFileManager ()

NS_ASSUME_NONNULL_BEGIN

@property (nonatomic, readonly) CRStaticFileServingOptions options;
@property (nonatomic, readonly, strong) dispatch_queue_t fileReadingQueue;

- (CRRouteBlock)errorHandlerBlockForError:(NSError *)error;
- (CRRouteBlock)servingBlockForFileAtPath:(NSString *)filePath attributes:(NSDictionary *)attributes;

NS_ASSUME_NONNULL_END

@end

@implementation CRStaticFileManager

+ (instancetype)managerWithFileAtPath:(NSString *)filePath {
    return [[CRStaticFileManager alloc] initWithFileAtPath:filePath options:0 attributes:nil];
}

+ (instancetype)managerWithFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options {
    return [[CRStaticFileManager alloc] initWithFileAtPath:filePath options:options attributes:nil];
}

+ (instancetype)managerWithFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options attributes:(NSDictionary *)attributes {
    return [[CRStaticFileManager alloc] initWithFileAtPath:filePath options:options attributes:attributes];
}

- (instancetype)init {
    return  [self initWithFileAtPath:@"" options:0 attributes:nil];
}

- (instancetype)initWithFileAtPath:(NSString *)filePath {
    return [self initWithFileAtPath:filePath options:0 attributes:nil];
}

- (instancetype)initWithFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options {
    return [self initWithFileAtPath:filePath options:options attributes:nil];
}

- (instancetype)initWithFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options attributes:(NSDictionary *)attributes {
    self = [super init];
    if ( self != nil ) {

        // Sanitize path
        _filePath = filePath.stringByStandardizingPath;

        // Initialize convenience properties
        _options = options;
        _shouldCache = _options & CRStaticFileServingOptionsCache;
        _shouldFollowSymLinks = _options & CRStaticFileServingOptionsFollowSymlinks;

        // Expand symlinks if needed
        if ( _shouldFollowSymLinks ) {
            _filePath = [_filePath stringByResolvingSymlinksInPath];
        }

        _fileName = filePath.lastPathComponent;

        // Initialize the attributes
        if ( attributes ) {
            _attributes = attributes;
        } else {
            NSError* attributesError;
            _attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:_filePath error:&attributesError];
            if ( attributesError ) {
                _attributesError = attributesError;
            }
        }

        // Create and configure queues
        NSString* fileReadingQueueLabel = [NSString stringWithFormat:@"%@-%@-fileReadngQueue", NSStringFromClass(self.class), _fileName];
        _fileReadingQueue = dispatch_queue_create(fileReadingQueueLabel.UTF8String, DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_fileReadingQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
    }
    return self;
}

- (CRRouteBlock)errorHandlerBlockForError:(NSError *)error {
    CRRouteBlock block = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSUInteger statusCode = 500;
        if ( [error.domain isEqualToString:NSCocoaErrorDomain] ) {
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

        [CRServer errorHandlingBlockWithStatus:statusCode error:error](request, response, completionHandler);
    };
    return block;
}

- (CRRouteBlock)servingBlockForFileAtPath:(NSString *)filePath attributes:(NSDictionary *)attributes {
    CRRouteBlock block = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {

        // Send an unimplemented error if we are being requested to serve multipart byte-ranges
        if ( request.range.byteRangeSet.count > 1 ) {
            NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
            userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"Multiple range (multipart/byte-range) responses are not implemented.",);
            userInfo[NSURLErrorFailingURLErrorKey] = request.URL;
            userInfo[NSFilePathErrorKey] = filePath;
            NSError* rangeError = [NSError errorWithDomain:CRStaticFileManagerErrorDomain code:CRStaticFileManagerNotImplementedError userInfo:userInfo];
            [self errorHandlerBlockForError:rangeError](request, response, completionHandler);
            return;
        }

        // We are accepting byte ranges
        [response setValue:[CRRequestRange acceptRangesSpec] forHTTPHeaderField:@"Accept-Ranges"];

        CRRequestByteRange* requestByteRange;
        NSRange byteRangeDataRange = NSMakeRange(NSNotFound, 0);

        NSUInteger fileSize = @(attributes.fileSize).integerValue;

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
                [self errorHandlerBlockForError:rangeError](request, response, completionHandler);
                return;
            }

        } else {
            [response setValue:@(fileSize).stringValue forHTTPHeaderField:@"Content-Length"];
        }

        // Get the mime type and set the Content-type header
        NSString* contentType = [[CRMimeTypeHelper sharedHelper] mimeTypeForFileAtPath:filePath];
        [response setValue:contentType forHTTPHeaderField:@"Content-Type"];

        // Read synchroniously if the file size is below threshold
        if ( fileSize <= CRStaticFileServingReadThreshold ) {

            NSError* fileReadError;
            NSData* fileData = [NSData dataWithContentsOfFile:filePath options:(self.shouldCache ? NSDataReadingMappedIfSafe : NSDataReadingUncached) error:&fileReadError];
            if ( fileData == nil && fileReadError != nil ) {
                [self errorHandlerBlockForError:fileReadError](request, response, completionHandler);
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

            dispatch_io_t fileReadChannel = dispatch_io_create_with_path(DISPATCH_IO_RANDOM, filePath.UTF8String, O_RDONLY, 0, self.fileReadingQueue,  ^(int error) {
                if ( error ) {
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
                    [self errorHandlerBlockForError:channelReleaseError](request, response, ^{});
                    return;
                }

                [response finish];
            });

            dispatch_io_set_high_water(fileReadChannel, CRStaticFileServingReadBuffer);
            dispatch_io_set_low_water(fileReadChannel, CRStaticFileServingReadThreshold);

            off_t offset = 0;
            size_t length = fileSize;
            if ( request.range.byteRangeSet.count > 0 ) {
                offset = byteRangeDataRange.location;
                length = byteRangeDataRange.length;
            }

            dispatch_io_read(fileReadChannel, offset, length, self.fileReadingQueue, ^(bool done, dispatch_data_t data, int error) {
                if (request.connection == nil || response.connection == nil) {
                    dispatch_io_close(fileReadChannel, DISPATCH_IO_STOP);
                    return;
                }

                if ( error ) {
                    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
                    userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"There was an error releasing the file read channel.",);
                    userInfo[NSURLErrorFailingURLErrorKey] = request.URL;
                    userInfo[NSFilePathErrorKey] = filePath;
                    NSString* underlyingErrorDescription = [NSString stringWithCString:strerror(error) encoding:NSUTF8StringEncoding];
                    if ( underlyingErrorDescription.length > 0 ) {
                        NSError* underlyingError = [NSError errorWithDomain:NSPOSIXErrorDomain code:@(error).integerValue userInfo:@{NSLocalizedDescriptionKey: underlyingErrorDescription}];
                        userInfo[NSUnderlyingErrorKey] = underlyingError;
                    }
                    NSError* fileReadError = [NSError errorWithDomain:CRStaticFileManagerErrorDomain code:CRStaticFileManagerReleaseFailedError userInfo:userInfo];
                    [self errorHandlerBlockForError:fileReadError](request, response, ^{});
                    return;
                }

                if (data) {
                    [response writeData:(NSData*)data];
                }

                if (done) {
                    dispatch_io_close(fileReadChannel, 0);
                }
            });

            completionHandler();
        }
    };
    return block;
}

- (CRRouteBlock)routeBlock {
    CRRouteBlock block = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        if ( self.attributes == nil || self.attributesError != nil ) {

            [self errorHandlerBlockForError:self.attributesError](request, response, completionHandler);

        } else if ( [self.attributes.fileType isEqualToString:NSFileTypeDirectory] ) {

            // File is directory
            NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
            userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"The requested file is a directory.",);
            userInfo[NSURLErrorFailingURLErrorKey] = request.URL;
            userInfo[NSFilePathErrorKey] = self.filePath;
            NSError* fileIsDirectoryError = [NSError errorWithDomain:CRStaticFileManagerErrorDomain code:CRStaticFileManagerFileIsDirectoryError userInfo:userInfo];
            [self errorHandlerBlockForError:fileIsDirectoryError](request, response, completionHandler);

        } else if ( [self.attributes.fileType isEqualToString:NSFileTypeRegular] ) {

            [self servingBlockForFileAtPath:self.filePath attributes:self.attributes](request, response, completionHandler);

        } else {

            NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
            userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:NSLocalizedString(@"Files of type “%@” are restricted.",), self.attributes.fileType];
            userInfo[NSURLErrorFailingURLErrorKey] = request.URL;
            userInfo[NSFilePathErrorKey] = self.filePath;
            NSError* restrictedFileTypeError = [NSError errorWithDomain:CRStaticFileManagerErrorDomain code:CRStaticFileManagerRestrictedFileTypeError userInfo:userInfo];
            [self errorHandlerBlockForError:restrictedFileTypeError](request, response, completionHandler);

        }
    };
    
    return block;
}

@end
