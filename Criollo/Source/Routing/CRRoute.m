//
//  CRRoute.m
//  Criollo
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRRoute.h"
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

+ (CRRoute *)routeWithStaticFolder:(NSString *)folderPath prefix:(NSString * _Nonnull)prefix options:(CRStaticFolderServingOptions)options {
    return [[CRRoute alloc] initWithStaticFolder:folderPath prefix:prefix options:options];
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

- (instancetype)initWithStaticFolder:(NSString *)folderPath prefix:(NSString * _Nonnull)prefix options:(CRStaticFolderServingOptions)options {

    folderPath = [folderPath stringByExpandingTildeInPath];
    if ( [folderPath hasSuffix:CRPathSeparator] ) {
        folderPath = [folderPath substringToIndex:folderPath.length - CRPathSeparator.length];
    }

    if ( [prefix hasSuffix:CRPathSeparator] ) {
        prefix = [prefix substringToIndex:prefix.length - CRPathSeparator.length];
    }

    BOOL shouldCache = @(options & CRStaticFolderServingOptionsCacheFiles).boolValue;
    BOOL shouldGenerateIndex = @(options & CRStaticFolderServingOptionsAutoIndex).boolValue;

    CRRouteBlock block = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSLog(@"%s", __PRETTY_FUNCTION__);

        NSString* requestedRelativePath = [request.env[@"DOCUMENT_URI"] substringFromIndex:prefix.length];
        NSString* requestedAbsolutePath = [folderPath stringByAppendingPathComponent:requestedRelativePath];

        NSLog(@" * Absolute Path: %@", requestedAbsolutePath);
        NSLog(@" * Should Cache: %hhd", shouldCache);
        NSLog(@" * Should Generate Index: %hhd", shouldGenerateIndex);

        [response sendString:requestedAbsolutePath];
    };
    
    return [self initWithBlock:block];
}

@end