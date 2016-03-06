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
#import "CRRequest_Internal.h"
#import "CRResponse.h"
#import "CRResponse_Internal.h"
#import "CRConnection.h"
#import "CRConnection_Internal.h"
#import "CRMimeTypeHelper.h"
#import "CRRequestRange.h"

#define CRStaticDirectoryServingReadBuffer                              (8 * 1024 * 1024)
#define CRStaticDirectoryServingReadThreshold                           (8 * 64 * 1024)

#define CRStaticDirectoryIndexFileNameLength                            70
#define CRStaticDirectoryIndexFileSizeLength                            20

#define CRStaticDirectoryManagerErrorDomain                             @"CRStaticDirectoryManagerErrorDomain"

#define CRStaticDirectoryManagerReleaseFailedError                      101
#define CRStaticDirectoryManagerDirectoryListingForbiddenError          102
#define CRStaticDirectoryManagerRestrictedFileTypeError                 103

#define CRStaticDirectoryManagerRangeNotSatisfiableError                201

#define CRStaticDirectoryManagerNotImplementedError                     999

@interface CRStaticDirectoryManager ()

@property (nonatomic, nonnull, readonly) NSString * prefix;
@property (nonatomic, readonly) CRStaticDirectoryServingOptions options;

@property (nonatomic, readonly, strong, nonnull) dispatch_queue_t fileReadingQueue;

- (nonnull CRRouteBlock)errorHandlerBlockForError:(NSError * _Nonnull)error;
- (nonnull CRRouteBlock)servingBlockForFileAtPath:(NSString * _Nonnull)filePath attributes:(NSDictionary * _Nonnull)attributes;
- (nonnull CRRouteBlock)indexBlockForDirectoryAtPath:(NSString * _Nonnull)directoryPath requestedPath:(NSString * _Nonnull)requestedPath displayParentLink:(BOOL)flag;

+ (nonnull NSDateFormatter *)dateFormatter;

@end

@implementation CRStaticDirectoryManager

+ (instancetype)managerWithDirectoryAtPath:(NSString *)directoryPath prefix:(NSString *)prefix {
    return [[CRStaticDirectoryManager alloc] initWithDirectoryAtPath:directoryPath prefix:prefix options:0];
}

+ (instancetype)managerWithDirectoryAtPath:(NSString *)directoryPath prefix:(NSString *)prefix options:(CRStaticDirectoryServingOptions)options {
    return [[CRStaticDirectoryManager alloc] initWithDirectoryAtPath:directoryPath prefix:prefix options:options];
}

- (instancetype)init {
    return  [self initWithDirectoryAtPath:[NSBundle mainBundle].bundlePath prefix:@"/" options:0];
}

- (instancetype)initWithDirectoryAtPath:(NSString *)directoryPath prefix:(NSString *)prefix {
    return [self initWithDirectoryAtPath:directoryPath prefix:prefix options:0];
}

- (instancetype)initWithDirectoryAtPath:(NSString *)directoryPath prefix:(NSString *)prefix options:(CRStaticDirectoryServingOptions)options {
    self = [super init];
    if ( self != nil ) {

        // Sanitize paths
        _directoryPath = directoryPath.stringByStandardizingPath;
        _prefix = prefix.stringByStandardizingPath;

        // Initialize convenience properties
        _options = options;
        _shouldCacheFiles = _options & CRStaticDirectoryServingOptionsCacheFiles;
        _shouldGenerateDirectoryIndex = _options & CRStaticDirectoryServingOptionsAutoIndex;
        _shouldShowHiddenFilesInDirectoryIndex = _options & CRStaticDirectoryServingOptionsAutoIndexShowHidden;
        _shouldFollowSymLinks = _options & CRStaticDirectoryServingOptionsFollowSymlinks;

        // Create and configure queues
        NSString* fileReadingQueueLabel = [NSString stringWithFormat:@"%@-%@-fileReadngQueue", NSStringFromClass(self.class), self.prefix];
        _fileReadingQueue = dispatch_queue_create(fileReadingQueueLabel.UTF8String, DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_fileReadingQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
    }
    return self;
}

+ (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        dateFormatter.timeZone = [NSTimeZone defaultTimeZone];
        dateFormatter.dateFormat = @"dd-MMM-yyyy HH:mm:ss";
    });
    return dateFormatter;
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
        } else if ([error.domain isEqualToString:CRStaticDirectoryManagerErrorDomain] ) {
            switch ( error.code ) {
                case CRStaticDirectoryManagerNotImplementedError:
                    statusCode = 501;
                    break;
                case CRStaticDirectoryManagerRangeNotSatisfiableError:
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

- (CRRouteBlock)indexBlockForDirectoryAtPath:(NSString *)directoryPath requestedPath:(NSString *)requestedPath displayParentLink:(BOOL)flag {
    CRRouteBlock block = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {

        NSMutableString* responseString = [NSMutableString string];
        [responseString appendString:@"<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\"/><meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\"/><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"/>"];
        [responseString appendFormat:@"<title>%@</title>", requestedPath];
        [responseString appendString:@"</head><body>"];
        [responseString appendFormat:@"<h1>Index of %@</h1>", requestedPath];
        [responseString appendString:@"<hr/>"];

        NSError *directoryListingError;
        NSArray<NSURL *> *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:directoryPath] includingPropertiesForKeys:nil options:(self.shouldShowHiddenFilesInDirectoryIndex ? 0 : NSDirectoryEnumerationSkipsHiddenFiles) error:&directoryListingError];
        if ( directoryContents == nil && directoryListingError != nil ) {
            [self errorHandlerBlockForError:directoryListingError](request, response, completionHandler);
            return;
        }

        [responseString appendString:@"<pre>"];

        if ( flag ) {
            [responseString appendFormat:@"<a href=\"%@\">../</a>\n", requestedPath.stringByDeletingLastPathComponent];
        }

        [directoryContents enumerateObjectsUsingBlock:^(NSURL * _Nonnull URL, NSUInteger idx, BOOL * _Nonnull stop) {
            NSError* attributesError;
            NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:URL.path error:&attributesError];
            if ( attributes == nil && attributesError != nil ) {
                NSLog(@"%@", attributesError);
                return;
            }

            BOOL isDirectory = [attributes.fileType isEqualToString:NSFileTypeDirectory];
            NSString* fullName = [URL.lastPathComponent stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
            NSString* fileName = URL.lastPathComponent;
            NSString* fileNamePadding;
            if ( fileName.length > CRStaticDirectoryIndexFileNameLength ) {
                fileName = [fileName substringToIndex:CRStaticDirectoryIndexFileNameLength - (isDirectory ? 1 : 0)];
                fileNamePadding = @"";
            } else {
                fileNamePadding = [@"" stringByPaddingToLength:CRStaticDirectoryIndexFileNameLength - fileName.length - (isDirectory ? 1 : 0) withString:@" " startingAtIndex:0];
            }

            NSString* fileModificationDate = [[CRStaticDirectoryManager dateFormatter] stringFromDate:attributes.fileModificationDate];
            NSString* fileSize = @(attributes.fileSize).stringValue;
            NSString* fileSizePadding;
            if ( fileSize.length > CRStaticDirectoryIndexFileSizeLength ) {
                fileSize =  [fileSize substringToIndex:CRStaticDirectoryIndexFileSizeLength];
                fileSizePadding = @"";
            } else {
                fileSizePadding = [@"" stringByPaddingToLength:CRStaticDirectoryIndexFileSizeLength - fileSize.length withString:@" " startingAtIndex:0];
            }

            [responseString appendFormat:@"<a href=\"%@/%@\" title=\"%@\">%@%@</a>%@ %@ %@%@\n", requestedPath, URL.lastPathComponent, fullName, fileName, isDirectory ? @"/" : @"", fileNamePadding, fileModificationDate, fileSizePadding, fileSize];
        }];
        [responseString appendString:@"</pre>"];

        [responseString appendString:@"<hr/></body></html>"];

        [response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        [response setValue:@(responseString.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [response sendString:responseString];
        completionHandler();
    };
    return block;
}

- (CRRouteBlock)servingBlockForFileAtPath:(NSString *)filePath attributes:(NSDictionary *)attributes {
    CRRouteBlock block = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {

        // Send an unimplemented error if we are being requested to serve multipart byte-ranges
        if ( request.range.byteRangeSet.count > 1 ) {
            NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
            userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"multipart/byte-range requests are not implemented",);
            userInfo[NSURLErrorFailingURLErrorKey] = request.URL;
            userInfo[NSFilePathErrorKey] = filePath;
            NSError* rangeError = [NSError errorWithDomain:CRStaticDirectoryManagerErrorDomain code:CRStaticDirectoryManagerNotImplementedError userInfo:userInfo];
            [self errorHandlerBlockForError:rangeError](request, response, completionHandler);
            return;
        }

        // Set the Content-length and Content-range headers
        if ( request.range.byteRangeSet.count > 0 ) {

            NSString* contentRangeSpec = [request.range.byteRangeSet[0] contentRangeSpecForFileSize:attributes.fileSize];
            [response setValue:contentRangeSpec forHTTPHeaderField:@"Content-Range"];

            if ( [request.range isSatisfiableForFileSize:attributes.fileSize ] ) {
                // Set partial content response header
                [response setStatusCode:206 description:nil];
                NSString* conentLengthSpec = [request.range.byteRangeSet[0] contentLengthSpecForFileSize:attributes.fileSize];
                [response setValue:conentLengthSpec forHTTPHeaderField:@"Content-Length"];
            } else {
                NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
                userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:NSLocalizedString(@"The requested byte-range %@-%@ / %lu could not be satisfied",), request.range.byteRangeSet[0].firstBytePos, request.range.byteRangeSet[0].lastBytePos, attributes.fileSize];
                userInfo[NSURLErrorFailingURLErrorKey] = request.URL;
                userInfo[NSFilePathErrorKey] = filePath;
                NSError* rangeError = [NSError errorWithDomain:CRStaticDirectoryManagerErrorDomain code:CRStaticDirectoryManagerRangeNotSatisfiableError userInfo:userInfo];
                [self errorHandlerBlockForError:rangeError](request, response, completionHandler);
                return;
            }

        } else {
            [response setValue:@(attributes.fileSize).stringValue forHTTPHeaderField:@"Content-Length"];
        }

        // Get the mime type and set the Content-type header
        NSString* contentType = [[CRMimeTypeHelper sharedHelper] mimeTypeForFileAtPath:filePath];
        [response setValue:contentType forHTTPHeaderField:@"Content-type"];

        [response writeString:@""];

        // Read synchroniously if the file size is below threshold
        if ( attributes.fileSize <= CRStaticDirectoryServingReadThreshold ) {

            NSError* fileReadError;
            NSData* fileData = [NSData dataWithContentsOfFile:filePath options:(self.shouldCacheFiles ? NSDataReadingMappedIfSafe : NSDataReadingUncached) error:&fileReadError];
            if ( fileData == nil && fileReadError != nil ) {
                [self errorHandlerBlockForError:fileReadError](request, response, completionHandler);
            } else {
                if ( request.range.byteRangeSet.count == 0 ) {
                    [response sendData:fileData];
                } else {
                    NSRange byteRangeDataRange = [request.range.byteRangeSet[0] dataRangeForFileSize:attributes.fileSize];
                    NSData* requestedRangeData = [NSData dataWithBytesNoCopy:(void *)fileData.bytes + byteRangeDataRange.location length:byteRangeDataRange.length freeWhenDone:NO];
                    [response sendData:requestedRangeData];
                }
                completionHandler();
            }

        } else {

            dispatch_io_t fileReadChannel = dispatch_io_create_with_path(DISPATCH_IO_STREAM, filePath.UTF8String, O_RDONLY, 0, self.fileReadingQueue,  ^(int error) {
                if ( !error ) {
                    [response finish];
                } else {
                    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
                    userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"There was an error releasing the file read channel",);
                    userInfo[NSURLErrorFailingURLErrorKey] = request.URL;
                    userInfo[NSFilePathErrorKey] = filePath;
                    NSString* underlyingErrorDescription = [NSString stringWithCString:strerror(error) encoding:NSUTF8StringEncoding];
                    if ( underlyingErrorDescription.length > 0 ) {
                        NSError* underlyingError = [NSError errorWithDomain:NSPOSIXErrorDomain code:@(error).integerValue userInfo:@{NSLocalizedDescriptionKey: underlyingErrorDescription}];
                        userInfo[NSUnderlyingErrorKey] = underlyingError;
                    }
                    NSError* channelReleaseError = [NSError errorWithDomain:CRStaticDirectoryManagerErrorDomain code:CRStaticDirectoryManagerReleaseFailedError userInfo:userInfo];
                    [self errorHandlerBlockForError:channelReleaseError](request, response, ^{});
                }
            });

            dispatch_io_set_high_water(fileReadChannel, CRStaticDirectoryServingReadBuffer);
            dispatch_io_set_low_water(fileReadChannel, CRStaticDirectoryServingReadThreshold);

            dispatch_io_read(fileReadChannel, 0, SIZE_MAX, self.fileReadingQueue, ^(bool done, dispatch_data_t data, int error) {
                if (error || request.connection == nil || response.connection == nil) {
                    dispatch_io_close(fileReadChannel, DISPATCH_IO_STOP);
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

        NSString* requestedDocumentPath = request.env[@"DOCUMENT_URI"];
        NSString* requestedRelativePath = [[requestedDocumentPath substringFromIndex:self.prefix.length] stringByStandardizingPath];
        NSString* requestedAbsolutePath = [[self.directoryPath stringByAppendingPathComponent:requestedRelativePath] stringByStandardizingPath];

        // Expand symlinks if needed
        if ( self.shouldFollowSymLinks ) {
            requestedAbsolutePath = [requestedAbsolutePath stringByResolvingSymlinksInPath];
        }

        // stat() the file
        NSError * itemAttributesError;
        NSDictionary * itemAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:requestedAbsolutePath error:&itemAttributesError];
        if ( itemAttributes == nil && itemAttributesError != nil ) {
            // Unable to stat() the file
            [self errorHandlerBlockForError:itemAttributesError](request, response, completionHandler);
        } else {
            if ( [itemAttributes.fileType isEqualToString:NSFileTypeDirectory] ) {                                  // Directories
                if ( self.shouldGenerateDirectoryIndex ) {
                    // Make the index
                    [self indexBlockForDirectoryAtPath:requestedAbsolutePath requestedPath:requestedDocumentPath displayParentLink:requestedRelativePath.length != 0](request, response, completionHandler);
                } else {
                    // Forbidden
                    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
                    userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"Directory index auto-generation is disabled",);
                    userInfo[NSURLErrorFailingURLErrorKey] = request.URL;
                    userInfo[NSFilePathErrorKey] = requestedAbsolutePath;                    
                    NSError* directoryListingError = [NSError errorWithDomain:CRStaticDirectoryManagerErrorDomain code:CRStaticDirectoryManagerDirectoryListingForbiddenError userInfo:userInfo];
                    [self errorHandlerBlockForError:directoryListingError](request, response, completionHandler);
                }
            } else if ( [itemAttributes.fileType isEqualToString:NSFileTypeRegular] ) {                             // Regular files
                // Serve the file
                [self servingBlockForFileAtPath:requestedAbsolutePath attributes:itemAttributes](request, response, completionHandler);
            } else {                                                                                                // Other types (socks, devices, etc)
                // Forbidden
                NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
                userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:NSLocalizedString(@"Files of type “%@” are restricted.",), itemAttributes.fileType];
                userInfo[NSURLErrorFailingURLErrorKey] = request.URL;
                userInfo[NSFilePathErrorKey] = requestedAbsolutePath;
                NSError* restrictedFileTypeError = [NSError errorWithDomain:CRStaticDirectoryManagerErrorDomain code:CRStaticDirectoryManagerRestrictedFileTypeError userInfo:userInfo];
                [self errorHandlerBlockForError:restrictedFileTypeError](request, response, completionHandler);
            }
        }
    };

    return block;
}

@end