//
//  CLRoutingCenter.h
//  Criollo
//
//  Created by Cătălin Stan on 5/18/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLRoute;

/**
An `CLRoutingCenter` object (or simply, routing center) provides a mechanism
for specifying which controllers and views should be called for a particular
request path. An `CLRoutingCenter` object is essentially a routing table.

Objects can request a specific route from the routing center using the 
`routeForRequestURI:` method or get `allRoutes`.

Each running Criollo application has a shared center. You typically don’t create
your own. The `CLApplicaion` shared instance tipically handles the resolution 
of routes so you should not have to call any of these methods yourself.

Routes are specified in the bundles `Info.plist` file using the `CLRoutingKey`.
 */
@interface CLRoutingCenter : NSObject {
    NSDictionary* routes;
}

/**
 @name Getting the routing center
 */

/**
 Returns the shared routing center

 @return The curremt process' shared routing center which is used to resoulve routes
 */
+ (CLRoutingCenter*)sharedCenter;

/**
 @name Creating a routing center
 */

/**
 Creates a routing center using the specified routing table

 @param routesOrNil The array containing the route definition dictionaries
 @return An instance of `CLRoutingCenter`
 */
- (instancetype)initWithRoutes:(NSArray*)routesOrNil;

/**
 @name Accessing route objects
 */

/**
 Get a specific route object from the available routes

 @param requestURI The URI for which to find the route object
 @return An instantiated
 */
- (CLRoute *)routeForRequestURI:(NSString*)requestURI;

/**
 Returns a dictionary that contains all the route valid CLRoute
 objects that the application supports.
 
 The keys are the route stubs as you would find them in the
 `CLRoutePath` key of a route dictionaries and the values are 
 CLRoute objects. The routes here have already been checked for
 availability and have already been validated. All the nibs
 have been cached.

 @return A fully populated dictionary of routes
 */
@property (nonatomic, readonly, copy) NSDictionary *allRoutes;

@end
