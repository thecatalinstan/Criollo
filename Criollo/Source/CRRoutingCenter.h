//
//  CRRoutingCenter.h
//  Criollo
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

@class CRRequest, CRResponse, CRRoute;

typedef void(^CRRouteHandlerBlock)(CRRequest* request, CRResponse* response, void(^completionHandler)(void));

@interface CRRoutingCenter : NSObject

+ (CRRoutingCenter*)defaultCenter;

- (instancetype)init;

- (void)addRouteWithHandlerBlock:(CRRouteHandlerBlock)handlerBlock forPath:(NSString*)path HTTPMethod:(NSString*)HTTPMethod;

- (NSArray*)routesForPath:(NSString*)path;
- (NSArray*)routesForPath:(NSString*)path HTTPMethod:(NSString*)HTTPMethod;

@end
