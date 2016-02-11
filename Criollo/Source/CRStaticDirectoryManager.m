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
#import "CRMimeTypeHelper.h"

#define CRStaticDirectoryServingReadBuffer          (8 * 1024 * 1024)
#define CRStaticDirectoryServingReadThreshold       (8 * 64 * 1024)

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
        dateFormatter.calendar = [NSCalendar calendarWithIdentifier:NSGregorianCalendar];
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
        } else {
        }

//        [CRServer errorHandlingBlockWithStatus:statusCode](request, response, completionHandler);

        [response setStatusCode:statusCode description:nil];
        [response setValue:@"text-plain" forHTTPHeaderField:@"Content-type"];
        [response sendFormat:@"%@ %lu\n%@\n\n%@\n\n%@", error.domain, error.code, error.localizedDescription, error.userInfo, [NSThread callStackSymbols]];
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

//        [responseString appendFormat:@"%@", directoryContents];

        [directoryContents enumerateObjectsUsingBlock:^(NSURL * _Nonnull URL, NSUInteger idx, BOOL * _Nonnull stop) {
            NSError* attributesError;
            NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:URL.path error:&attributesError];
            if ( attributes == nil && attributesError != nil ) {
                NSLog(@"%@", attributesError);
                return;
            }

            BOOL isDirectory = [attributes.fileType isEqualToString:NSFileTypeDirectory];
            NSString* fileName = URL.lastPathComponent;
            if ( fileName.length > 50 ) {
                fileName = [fileName substringToIndex:50];
            }
            NSString* fileNamePadding = [@"" stringByPaddingToLength:50 - fileName.length - (isDirectory ? 1 : 0) withString:@" " startingAtIndex:0];
            NSString* fileModificationDate = [[CRStaticDirectoryManager dateFormatter] stringFromDate:attributes.fileModificationDate];
            NSString* fileSize = @(attributes.fileSize).stringValue;
            NSString* fileSizePadding = [@"" stringByPaddingToLength:16 - fileSize.length withString:@" " startingAtIndex:0];

            [responseString appendFormat:@"<a href=\"%@/%@\">%@%@</a>%@ %@ %@%@\n", requestedPath, URL.lastPathComponent, fileName, isDirectory ? @"/" : @"", fileNamePadding, fileModificationDate, fileSizePadding, fileSize];
        }];
        [responseString appendString:@"</pre>"];

        [responseString appendString:@"<hr/></body></html>"];

        [response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        [response sendString:responseString];
    };
    return block;
}

- (CRRouteBlock)servingBlockForFileAtPath:(NSString *)filePath attributes:(NSDictionary *)attributes {
    CRRouteBlock block = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        // Set the Content-length header
        [response setValue:@(attributes.fileSize).stringValue forHTTPHeaderField:@"Content-length"];

        // Get the mime type and set the Content-type header
        NSString* contentType = [[CRMimeTypeHelper sharedHelper] mimeTypeForFileAtPath:filePath];
        [response setValue:contentType forHTTPHeaderField:@"Content-type"];

        // Read synchroniously if the file size is below threshold
        if ( attributes.fileSize <= CRStaticDirectoryServingReadThreshold ) {

            NSError* fileReadError;
            NSData* fileData = [NSData dataWithContentsOfFile:filePath options:(self.shouldCacheFiles ? NSDataReadingMappedIfSafe : NSDataReadingUncached) error:&fileReadError];
            if ( fileData == nil && fileReadError != nil ) {
                [self errorHandlerBlockForError:fileReadError](request, response, completionHandler);
            } else {
                [response sendData:fileData];
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
                    NSError* channelReleaseError = [NSError errorWithDomain:CRStaticDirectoryManagerErrorDomain code:CRStaticDirectoryManagerReleaseFailed userInfo:userInfo];
                    [self errorHandlerBlockForError:channelReleaseError](request, response, completionHandler);
                }
            });

            dispatch_io_set_high_water(fileReadChannel, CRStaticDirectoryServingReadBuffer);
            dispatch_io_set_low_water(fileReadChannel, CRStaticDirectoryServingReadThreshold);

            dispatch_io_read(fileReadChannel, 0, SIZE_MAX, self.fileReadingQueue, ^(bool done, dispatch_data_t data, int error) {
                if (error) {
                    dispatch_io_close(fileReadChannel, DISPATCH_IO_STOP);
                    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
                    userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"There was an error releasing the file read channel",);
                    userInfo[NSURLErrorFailingURLErrorKey] = request.URL;
                    userInfo[NSFilePathErrorKey] = filePath;
                    NSString* underlyingErrorDescription = [NSString stringWithCString:strerror(error) encoding:NSUTF8StringEncoding];
                    if ( underlyingErrorDescription.length > 0 ) {
                        NSError* underlyingError = [NSError errorWithDomain:NSPOSIXErrorDomain code:@(error).integerValue userInfo:@{NSLocalizedDescriptionKey: underlyingErrorDescription}];
                        userInfo[NSUnderlyingErrorKey] = underlyingError;
                    }
                    NSError* channelReleaseError = [NSError errorWithDomain:CRStaticDirectoryManagerErrorDomain code:CRStaticDirectoryManagerReleaseFailed userInfo:userInfo];
                    [self errorHandlerBlockForError:channelReleaseError](request, response, completionHandler);
                    return;
                }

                if (data) {
                    [response writeData:(NSData*)data];
                }

                if (done) {
                    dispatch_io_close(fileReadChannel, 0);
                }
            });
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
                    NSError* directoryListingError = [NSError errorWithDomain:CRStaticDirectoryManagerErrorDomain code:CRStaticDirectoryManagerDirectoryListingForbidden userInfo:userInfo];
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
                NSError* restrictedFileTypeError = [NSError errorWithDomain:CRStaticDirectoryManagerErrorDomain code:CRStaticDirectoryManagerRestrictedFileType userInfo:userInfo];
                [self errorHandlerBlockForError:restrictedFileTypeError](request, response, completionHandler);
            }
        }
    };

    return block;
}

@end