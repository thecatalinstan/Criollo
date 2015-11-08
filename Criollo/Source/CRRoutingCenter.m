//
//  CRRoutingCenter.m
//  Criollo
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRRoutingCenter.h"
#import "CRRoute.h"

@interface CRRoutingCenter ()

@property (nonatomic, strong) NSMutableDictionary<NSString*, NSMutableArray<CRRoute*>*>* routes;

@end

@implementation CRRoutingCenter

+ (CRRoutingCenter *)defaultCenter {
    static CRRoutingCenter* _defaultCenter;
    static dispatch_once_t defaultCenterOnceToken;
    dispatch_once(&defaultCenterOnceToken, ^{
        _defaultCenter = [[CRRoutingCenter alloc] init];
    });
    return _defaultCenter;
}

- (instancetype)init {
    self = [super init];
    if ( self != nil ) {
        _routes = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addRouteWithHandlerBlock:(CRRouteHandlerBlock)handlerBlock forPath:(NSString*)path HTTPMethod:(NSString*)HTTPMethod {
    NSArray<NSString*>* methods;

    if ( HTTPMethod == nil ) {
        methods = @[@"GET", @"POST", @"PUT", @"DELETE"];
    } else {
        methods = @[HTTPMethod];
    }

    if ( path == nil ) {
        path = @"";
    }

    if ( ![path hasSuffix:@"/"] ) {
        path = [path stringByAppendingString:@"/"];
    }

    CRRoute* route = [CRRoute routeWithHandlerBlock:handlerBlock];

    [methods enumerateObjectsUsingBlock:^(NSString * _Nonnull method, NSUInteger idx, BOOL * _Nonnull stop) {

        NSString* routePath = [method stringByAppendingString:path];

        if ( ![self.routes[routePath] isKindOfClass:[NSMutableArray class]] ) {
            NSMutableArray<CRRoute*>* parentRoutes = [NSMutableArray array];

            // Add all parent routes
            __block NSString* parentPath = [method stringByAppendingString:@"/"];
            [routePath.pathComponents enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ( self.routes[parentPath] != nil ) {
                    [parentRoutes addObjectsFromArray:self.routes[parentPath]];
                }
                parentPath = [parentPath stringByAppendingFormat:@"%@/", obj];
            }];

            self.routes[routePath] = parentRoutes;
        }

        // Add the route to all other descendant routes
        NSArray<NSString*>* descendantRoutesKeys = [self.routes.allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString*  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [evaluatedObject hasPrefix:routePath];
        }]];

        [descendantRoutesKeys enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.routes[obj] addObject:route];
        }];

    }];

}

- (NSArray<CRRoute*>*)routesForPath:(NSString*)path {
    return [self routesForPath:path HTTPMethod:nil];
}

- (NSArray<CRRoute*>*)routesForPath:(NSString*)path HTTPMethod:(NSString*)HTTPMethod {
    if ( path == nil ) {
        path = @"";
    }
    if ( ![path hasSuffix:@"/"] ) {
        path = [path stringByAppendingString:@"/"];
    }

    NSString* routePath = [HTTPMethod stringByAppendingString:path];
    return self.routes[routePath];
}


@end
