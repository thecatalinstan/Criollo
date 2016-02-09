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

        NSLog(@"%s", __PRETTY_FUNCTION__);

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

//            NSLog(@"Error: %@\n", itemAttributesError);

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
            } else {
            }
            [CRServer errorHandlingBlockWithStatus:statusCode](request, response, completionHandler);

        } else {

            if ( [itemAttributes.fileType isEqualToString:NSFileTypeDirectory] ) {
                if ( shouldGenerateIndex ) {
                    // Make the index

                } else {
                    // Forbidden
                    [CRServer errorHandlingBlockWithStatus:403](request, response, completionHandler);
                }
            } else if ( [itemAttributes.fileType isEqualToString:NSFileTypeRegular] ) {

                [response sendFormat:@"%@", itemAttributes];

            } else {
                // Forbidden
                [CRServer errorHandlingBlockWithStatus:403](request, response, completionHandler);
            }

        }

    };
    
    return [self initWithBlock:block];
}

@end