//
//  CRRoute.m
//  Criollo
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRRoute.h"
#import "CRServer_Internal.h"
#import "CRRouteController.h"
#import "CRViewController.h"
#import "CRRequest.h"
#import "CRRequest_Internal.h"
#import "CRResponse.h"
#import "CRResponse_Internal.h"
#import "CRStaticDirectoryManager.h"
#import "CRStaticFileManager.h"

@interface CRRoute ()

@end

@implementation CRRoute

+ (CRRoute *)routeWithBlock:(CRRouteBlock)block {
    return [[CRRoute alloc] initWithBlock:block];
}

+ (CRRoute *)routeWithControllerClass:(Class)controllerClass {
    return [[CRRoute alloc] initWithControllerClass:controllerClass];
}

+ (CRRoute *)routeWithViewControllerClass:(Class)controllerClass nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [[CRRoute alloc] initWithViewControllerClass:controllerClass nibName:nibNameOrNil bundle:nibBundleOrNil];
}

+ (CRRoute *)routeWithStaticDirectoryAtPath:(NSString *)directoryPath prefix:(NSString *)prefix options:(CRStaticDirectoryServingOptions)options {
    return [[CRRoute alloc] initWithStaticDirectoryAtPath:directoryPath prefix:prefix options:options];
}

+ (CRRoute *)routeWithStaticFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options fileName:(NSString *)fileName contentType:(NSString *)contentType contentDisposition:(CRStaticFileContentDisposition)contentDisposition {
    return [[CRRoute alloc] initWithStaticFileAtPath:filePath options:options fileName:fileName contentType:contentType contentDisposition:CRStaticFileContentDispositionNone];
}

- (instancetype)init {
    return [self initWithBlock:^(CRRequest *request, CRResponse *response, CRRouteCompletionBlock completionHandler) {}];
}

- (instancetype)initWithBlock:(CRRouteBlock)block {
    self = [super init];
    if ( self != nil ) {
        _block = block;
    }
    return self;
}

- (instancetype)initWithControllerClass:(Class)controllerClass {
    CRRouteBlock block = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        CRViewController* controller = [[controllerClass alloc] init];
        controller.routeBlock(request, response, completionHandler);
    };
    return [self initWithBlock:block];
}

- (instancetype)initWithViewControllerClass:(Class)viewControllerClass nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    CRRouteBlock block = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        CRViewController* viewController = [[viewControllerClass alloc] initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
        viewController.routeBlock(request, response, completionHandler);
    };
    return [self initWithBlock:block];
}

- (instancetype)initWithStaticDirectoryAtPath:(NSString *)directoryPath prefix:(NSString *)prefix options:(CRStaticDirectoryServingOptions)options {
    CRRouteBlock block = [CRStaticDirectoryManager managerWithDirectoryAtPath:directoryPath prefix:prefix options:options].routeBlock;
    return [self initWithBlock:block];
}

- (instancetype)initWithStaticFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options fileName:(NSString *)fileName contentType:(NSString * _Nullable)contentType contentDisposition:(CRStaticFileContentDisposition)contentDisposition {
    CRRouteBlock block = [CRStaticFileManager managerWithFileAtPath:filePath options:options fileName:fileName contentType:contentType contentDisposition:contentDisposition].routeBlock;
    return [self initWithBlock:block];
}

@end