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
#import "CRStaticDirectoryManager.h"

@interface CRRoute ()

@end

@implementation CRRoute

+ (CRRoute *)routeWithBlock:(CRRouteBlock)block {
    return [[CRRoute alloc] initWithBlock:block];
}

+ (CRRoute *)routeWithControllerClass:(Class)controllerClass nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [[CRRoute alloc] initWithControllerClass:controllerClass nibName:nibNameOrNil bundle:nibBundleOrNil];
}

+ (CRRoute *)routeWithStaticDirectoryAtPath:(NSString *)directoryPath prefix:(NSString * _Nonnull)prefix options:(CRStaticDirectoryServingOptions)options {
    return [[CRRoute alloc] initWithStaticDirectoryAtPath:directoryPath prefix:prefix options:options];
}

+ (CRRoute *)routeWithStaticFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options {
    return [[CRRoute alloc] initWithStaticFileAtPath:filePath options:options];
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

- (instancetype)initWithControllerClass:(Class)controllerClass nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    CRRouteBlock block = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        CRViewController* controller = [[controllerClass alloc] initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
        controller.routeBlock(request, response, completionHandler);
    };
    return [self initWithBlock:block];
}

- (instancetype)initWithStaticDirectoryAtPath:(NSString *)directoryPath prefix:(NSString *)prefix options:(CRStaticDirectoryServingOptions)options {
    CRRouteBlock block = [[CRStaticDirectoryManager alloc] initWithDirectoryAtPath:directoryPath prefix:prefix options:options].routeBlock;
    return [self initWithBlock:block];
}

- (instancetype)initWithStaticFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options {
    CRRouteBlock block = ^(CRRequest * request, CRResponse * response, CRRouteCompletionBlock completionHandler) {
        [response sendFormat:@"%s", __PRETTY_FUNCTION__];
        completionHandler();
    };
    return [self initWithBlock:block];
}

@end