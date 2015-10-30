//
//  FCGIKitRoutingCenter.m
//  FCGIKit
//
//  Created by Cătălin Stan on 5/18/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "FKRoutingCenter.h"
#import "FCGIKit.h"
#import "FKRoute.h"


@interface FKRoutingCenter (Private)

- (void)loadRoutes:(NSArray*)routes;

@end

@implementation FKRoutingCenter (Private)

- (void)loadRoutes:(NSArray*)routesOrNil {
    if ( routesOrNil == nil ) {
        routesOrNil = [[NSBundle mainBundle] objectForInfoDictionaryKey:FKRoutesKey];
    }
	
    NSMutableDictionary* routesDictionary = [[NSMutableDictionary alloc] initWithCapacity:routesOrNil.count];
    [routesOrNil enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        FKRoute* route = [[FKRoute alloc] initWithInfoDictionary:obj];
		NSString* key = route.requestPath.pathComponents.count >= 2 ? route.requestPath.pathComponents[1] : @"";
        routesDictionary[key] = route;
    }];
    routes = routesDictionary;
}

@end

@implementation FKRoutingCenter

static FKRoutingCenter* sharedCenter;

+ (FKRoutingCenter *)sharedCenter
{
    if ( sharedCenter == nil ) {
        sharedCenter = [[FKRoutingCenter alloc] initWithRoutes:nil];
    }
    return sharedCenter;
}

- (instancetype)initWithRoutes:(NSArray *)routesOrNil
{
    self = [self init];
    if (self != nil) {
        [self loadRoutes:routesOrNil];
    }
    return self;
}

- (FKRoute *)routeForRequestURI:(NSString *)requestURI
{
	NSString* key = requestURI.pathComponents.count >= 2 ? requestURI.pathComponents[1] : @"";
    return routes[key];
}

- (NSDictionary *)allRoutes
{
    return routes;
}


@end