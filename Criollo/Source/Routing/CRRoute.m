//
//  CRRoute.m
//  Criollo
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRRoute.h"
#import "CRServer_Internal.h"
#import "CRViewController.h"
#import "CRRequest.h"
#import "CRRequest_Internal.h"
#import "CRResponse.h"
#import "CRResponse_Internal.h"
#import "NSDate+RFC1123.h"

#define CRStaticDirectoryServingReadBuffer          (8 * 1024 * 1024)
#define CRStaticDirectoryServingReadThreshold       (8 * 64 * 1024)

@interface CRRoute ()

@end

@implementation CRRoute

+ (CRRoute *)routeWithBlock:(CRRouteBlock)block {
    return [[CRRoute alloc] initWithBlock:block];
}

+ (CRRoute *)routeWithControllerClass:(Class)controllerClass nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [[CRRoute alloc] initWithControllerClass:controllerClass nibName:nibNameOrNil bundle:nibBundleOrNil];
}

+ (CRRoute *)routeWithStaticDirectory:(NSString *)directoryPath prefix:(NSString * _Nonnull)prefix options:(CRStaticDirectoryServingOptions)options {
    return [[CRRoute alloc] initWithStaticDirectory:directoryPath prefix:prefix options:options];
}

- (instancetype)init {
    return [self initWithBlock:^(CRRequest *request, CRResponse *response, CRRouteCompletionBlock completionHandler) {
    }];
}

- (instancetype)initWithBlock:(CRRouteBlock)block {
    self = [super init];
    if ( self != nil ) {
        _block = block;
    }
    return self;
}

- (instancetype)initWithControllerClass:(Class)controllerClass nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

    CRRouteBlock block = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        CRViewController* controller = [[controllerClass alloc] initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
        controller.routeBlock(request, response, completionHandler);
    };

    return [self initWithBlock:block];
}

- (instancetype)initWithStaticDirectory:(NSString *)directoryPath prefix:(NSString * _Nonnull)prefix options:(CRStaticDirectoryServingOptions)options {

    directoryPath = [directoryPath stringByStandardizingPath];
    prefix = [prefix stringByStandardizingPath];

    BOOL shouldCache = options & CRStaticDirectoryServingOptionsCacheFiles;
    BOOL shouldGenerateIndex = options & CRStaticDirectoryServingOptionsAutoIndex;
    BOOL shouldFollowSymLinks = options & CRStaticDirectoryServingOptionsFollowSymlinks;

    CRRouteBlock block = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {

        NSString* requestedDocumentPath = request.env[@"DOCUMENT_URI"];
        NSString* requestedRelativePath = [[requestedDocumentPath substringFromIndex:prefix.length] stringByStandardizingPath];
        NSString* requestedAbsolutePath = [[directoryPath stringByAppendingPathComponent:requestedRelativePath] stringByStandardizingPath];

        // Expand symlinks if needed
        if ( shouldFollowSymLinks ) {
            requestedAbsolutePath = [requestedAbsolutePath stringByResolvingSymlinksInPath];
        }

        NSError * itemAttributesError;
        NSDictionary * itemAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:requestedAbsolutePath error:&itemAttributesError];

        if ( itemAttributes == nil && itemAttributesError != nil ) {
            NSUInteger statusCode = 500;
            if ( [itemAttributesError.domain isEqualToString:NSCocoaErrorDomain] ) {
                switch ( itemAttributesError.code ) {
                    case NSFileReadNoSuchFileError:
                        statusCode = 404;
                        break;
                    case NSFileReadNoPermissionError:
                        statusCode = 403;
                        break;
                    default:
                        break;
                }
                [CRServer errorHandlingBlockWithStatus:statusCode](request, response, completionHandler);
            } else {
                [response setValue:@"text-plain" forHTTPHeaderField:@"Content-type"];
                [response sendFormat:@"%@", itemAttributesError];
            }

        } else {

            if ( [itemAttributes.fileType isEqualToString:NSFileTypeDirectory] ) {
                if ( shouldGenerateIndex ) {
                    // Make the index
                    NSMutableString* responseString = [NSMutableString string];
                    [responseString appendString:@"<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\"/><meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\"/><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"/>"];
                    [responseString appendFormat:@"<title>%@</title>", requestedDocumentPath];
                    [responseString appendString:@"</head><body>"];
                    [responseString appendFormat:@"<h1>Index of %@</h1>", requestedDocumentPath];
                    [responseString appendString:@"<hr/>"];


                    NSError *directoryListingError;
                    NSArray<NSString *> *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:requestedAbsolutePath error:&directoryListingError];
                    if ( directoryContents == nil && directoryListingError != nil ) {
                        [responseString appendFormat:@"<p>Unable to get the directory contents.</p><pre>%@</pre>", directoryListingError];
                    } else {
                        [responseString appendString:@"<pre>"];
                        if ( requestedRelativePath.length != 0 ) {
                            [responseString appendFormat:@"<a href=\"%@\">../</a>\n", requestedDocumentPath.stringByDeletingLastPathComponent];
                        }

                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        dateFormatter.dateFormat = @"dd-MMM-yyyy HH:mm:ss";

                        [directoryContents enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            NSError* attributesError;
                            NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[requestedAbsolutePath stringByAppendingPathComponent:obj] error:nil];
                            if ( attributes == nil && attributesError != nil ) {
                                return;
                            }

                            BOOL isDirectory = [attributes.fileType isEqualToString:NSFileTypeDirectory];
                            NSString* fileName = obj;
                            if ( fileName.length > 50 ) {
                                fileName = [fileName substringToIndex:50];
                            }
                            NSString* fileNamePadding = [@"" stringByPaddingToLength:50 - fileName.length - (isDirectory ? 1 : 0) withString:@" " startingAtIndex:0];
                            NSString* fileModificationDate = [dateFormatter stringFromDate:attributes.fileModificationDate];
                            NSString* fileSize = @(attributes.fileSize).stringValue;
                            NSString* fileSizePadding = [@"" stringByPaddingToLength:16 - fileSize.length withString:@" " startingAtIndex:0];

                            [responseString appendFormat:@"<a href=\"%@/%@\">%@%@</a>%@ %@ %@%@\n", requestedDocumentPath, obj, fileName, isDirectory ? @"/" : @"", fileNamePadding, fileModificationDate, fileSizePadding, fileSize];
                        }];
                        [responseString appendString:@"</pre>"];
                    }

                    [responseString appendString:@"<hr/></body></html>"];

                    [response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-type"];
                    [response sendString:responseString];
                } else {
                    // Forbidden
                    [CRServer errorHandlingBlockWithStatus:403](request, response, completionHandler);
                }

            } else if ( [itemAttributes.fileType isEqualToString:NSFileTypeRegular] ) {

                // Set the Content-length header
                [response setValue:@(itemAttributes.fileSize).stringValue forHTTPHeaderField:@"Content-length"];

                // Get the mime type and set the Content-type header
                NSString *fileExtension = requestedAbsolutePath.pathExtension;
                NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, NULL);
                NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
                if ( contentType.length == 0 ) {
                    contentType = @"application/octet-stream";
                }
                [response setValue:contentType forHTTPHeaderField:@"Content-type"];

                // Read synchroniously if the file size is below threshold
                if ( itemAttributes.fileSize <= CRStaticDirectoryServingReadThreshold ) {

                    NSError* fileReadError;
                    NSData* fileData = [NSData dataWithContentsOfFile:requestedAbsolutePath options:(shouldCache ? NSDataReadingMappedIfSafe : NSDataReadingUncached) error:&fileReadError];
                    if ( fileData == nil && fileReadError != nil ) {
                        [response setValue:@"text-plain" forHTTPHeaderField:@"Content-type"];
                        [response sendFormat:@"%@", fileReadError];
                    } else {
                        [response sendData:fileData];
                    }

                } else {

                    dispatch_queue_t fileReadQueue = dispatch_queue_create(requestedAbsolutePath.UTF8String, DISPATCH_QUEUE_SERIAL);
                    dispatch_set_target_queue(fileReadQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));

                    dispatch_io_t fileReadChannel = dispatch_io_create_with_path(DISPATCH_IO_STREAM, requestedAbsolutePath.UTF8String, O_RDONLY, 0, fileReadQueue,  ^(int error) {
                        if ( !error ) {
                            [response finish];
                        } else {
                            [response setValue:@"text-plain" forHTTPHeaderField:@"Content-type"];
                            [response sendFormat:@"Error: %s", strerror(error)];
                        }
                    });

                    dispatch_io_set_high_water(fileReadChannel, CRStaticDirectoryServingReadBuffer);
                    dispatch_io_set_low_water(fileReadChannel, CRStaticDirectoryServingReadThreshold);

                    dispatch_io_read(fileReadChannel, 0, SIZE_MAX, fileReadQueue, ^(bool done, dispatch_data_t data, int error) {

                        if (error) {
                            dispatch_io_close(fileReadChannel, 0);
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

            } else {
                // Forbidden
                [CRServer errorHandlingBlockWithStatus:403](request, response, completionHandler);
            }

        }

    };
    
    return [self initWithBlock:block];
}

@end