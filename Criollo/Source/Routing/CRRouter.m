//
//  CRRoutingCenter.m
//  Criollo
//
//  Created by Cătălin Stan on 19/07/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CRRouter.h"
#import "CRRoute.h"
#import "CRMessage.h"
#import "CRMessage_Internal.h"
#import "CRRequest.h"
#import "CRRequest_Internal.h"
#import "CRResponse.h"
#import "CRResponse_Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface CRRouter ()

@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*, NSMutableArray<CRRoute *> *> * routes;
@property (nonatomic, strong, readonly) NSMutableArray<NSString *> * recursiveMatchRoutePathPrefixes;

@end

NS_ASSUME_NONNULL_END

@implementation CRRouter

- (instancetype)init {
    self = [super init];
    if ( self != nil ) {
        _routes = [NSMutableDictionary dictionary];
        _recursiveMatchRoutePathPrefixes = [NSMutableArray array];
    }
    return self;
}

- (void)addBlock:(CRRouteBlock)block {
    [self addBlock:block forPath:nil HTTPMethod:CRHTTPMethodAll recursive:NO];
}

- (void)addBlock:(CRRouteBlock)block forPath:(NSString*)path {
    [self addBlock:block forPath:path HTTPMethod:CRHTTPMethodAll recursive:NO];
}

- (void)addBlock:(CRRouteBlock)block forPath:(NSString *)path HTTPMethod:(CRHTTPMethod)method {
    [self addBlock:block forPath:path HTTPMethod:method recursive:NO];
}

- (void)addBlock:(CRRouteBlock)block forPath:(NSString *)path HTTPMethod:(CRHTTPMethod)method recursive:(BOOL)recursive {
    CRRoute* route = [CRRoute routeWithBlock:block];
    [self addRoute:route forPath:path HTTPMethod:method recursive:recursive];
}

- (void)addController:(__unsafe_unretained Class)controllerClass withNibName:(NSString *)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil forPath:(NSString *)path {
    [self addController:controllerClass withNibName:nibNameOrNil bundle:nibBundleOrNil forPath:path HTTPMethod:CRHTTPMethodAll recursive:NO];
}

- (void)addController:(__unsafe_unretained Class)controllerClass withNibName:(NSString *)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil forPath:(NSString *)path HTTPMethod:(CRHTTPMethod)method {
    [self addController:controllerClass withNibName:nibNameOrNil bundle:nibBundleOrNil forPath:path HTTPMethod:method recursive:NO];
}

- (void)addController:(__unsafe_unretained Class)controllerClass withNibName:(NSString *)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil forPath:(NSString *)path HTTPMethod:(CRHTTPMethod)method recursive:(BOOL)recursive {
    CRRoute* route = [CRRoute routeWithControllerClass:controllerClass nibName:nibNameOrNil bundle:nibBundleOrNil];
    [self addRoute:route forPath:path HTTPMethod:method recursive:recursive];
}

- (void)addRoute:(CRRoute*)route forPath:(NSString *)path HTTPMethod:(CRHTTPMethod)method recursive:(BOOL)recursive {
    NSArray<NSString*>* methods;

    if ( method == CRHTTPMethodAll ) {
        methods = [CRMessage acceptedHTTPMethods];
    } else {
        methods = @[NSStringFromCRHTTPMethod(method), NSStringFromCRHTTPMethod(CRHTTPMethodHead)];
    }

    if ( path == nil ) {
        path = CRPathAnyPath;
        recursive = NO;
    }

    if ( ![path isEqualToString:CRPathAnyPath] && ![path hasSuffix:CRPathSeparator] ) {
        path = [path stringByAppendingString:CRPathSeparator];
    }

    [methods enumerateObjectsUsingBlock:^(NSString * _Nonnull method, NSUInteger idx, BOOL * _Nonnull stop) {

        NSString* routePath = [method stringByAppendingString:path];

        if ( ![self.routes[routePath] isKindOfClass:[NSMutableArray class]] ) {
            NSMutableArray<CRRoute*>* parentRoutes = [NSMutableArray array];

            // Add the "*" routes
            NSString* anyPathRoutePath = [method stringByAppendingString:CRPathAnyPath];
            if ( self.routes[anyPathRoutePath] != nil ) {
                [parentRoutes addObjectsFromArray:self.routes[anyPathRoutePath]];
            }

            self.routes[routePath] = parentRoutes;
        }

        [self.routes[routePath] addObject:route];

        // If the route should be executed on all paths, add it accordingly
        if ( [path isEqualToString:CRPathAnyPath] ) {
            [self.routes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<CRRoute *> * _Nonnull obj, BOOL * _Nonnull stop) {
                if ( ![obj.lastObject isEqual:route] ) {
                    [obj addObject:route];
                }
            }];
        }

        // If the route is recursive add it to the array
        if ( recursive ) {
            [self.recursiveMatchRoutePathPrefixes addObject:routePath];
        }
    }];
}

- (NSArray<CRRoute*>*)routesForPath:(NSString*)path HTTPMethod:(CRHTTPMethod)method {
    if ( path == nil ) {
        path = @"";
    }

    if ( ![path hasSuffix:CRPathSeparator] ) {
        path = [path stringByAppendingString:CRPathSeparator];
    }
    path = [NSStringFromCRHTTPMethod(method) stringByAppendingString:path];

    __block BOOL shouldRecursivelyMatchRoutePathPrefix = NO;
    [self.recursiveMatchRoutePathPrefixes enumerateObjectsUsingBlock:^(NSString * _Nonnull recursiveMatchRoutePathPrefix, NSUInteger idx, BOOL * _Nonnull stop) {
        if ( [path hasPrefix:recursiveMatchRoutePathPrefix] ) {
            shouldRecursivelyMatchRoutePathPrefix = YES;
            *stop = YES;
        }
    }];

    NSArray<CRRoute*>* routes;
    while ( routes.count == 0 ) {
        routes = self.routes[path];
        if ( !shouldRecursivelyMatchRoutePathPrefix) {
            break;
        }
        path = [[path stringByDeletingLastPathComponent] stringByAppendingString:CRPathSeparator];
    }
    
    return routes;
}


@end
