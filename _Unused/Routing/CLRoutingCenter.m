//
//  CLRoutingCenter.m
//  Criollo
//
//  Created by Cătălin Stan on 5/18/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "CLRoutingCenter.h"
#import "Criollo.h"
#import "CLRoute.h"


@interface CLRoutingCenter (Private)

- (void)loadRoutes:(NSArray*)routes;

@end

@implementation CLRoutingCenter (Private)

- (void)loadRoutes:(NSArray*)routesOrNil {
    if ( routesOrNil == nil ) {
        routesOrNil = [[NSBundle mainBundle] objectForInfoDictionaryKey:CLRoutesKey];
    }
	
    NSMutableDictionary* routesDictionary = [[NSMutableDictionary alloc] initWithCapacity:routesOrNil.count];
    [routesOrNil enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CLRoute* route = [[CLRoute alloc] initWithInfoDictionary:obj];
		NSString* key = route.requestPath.pathComponents.count >= 2 ? route.requestPath.pathComponents[1] : @"";
        routesDictionary[key] = route;
    }];
    routes = routesDictionary.copy;
}

@end

@implementation CLRoutingCenter

static CLRoutingCenter* sharedCenter;

+ (CLRoutingCenter *)sharedCenter
{
    if ( sharedCenter == nil ) {
        sharedCenter = [[CLRoutingCenter alloc] initWithRoutes:nil];
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

- (CLRoute *)routeForRequestURI:(NSString *)requestURI
{
	NSString* key = requestURI.pathComponents.count >= 2 ? requestURI.pathComponents[1] : @"";
    return routes[key];
}

- (NSDictionary *)allRoutes
{
    return routes.copy;
}


@end