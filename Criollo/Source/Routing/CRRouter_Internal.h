//
//  CRRouter_Internal.h
//  Criollo
//
//  Created by Cătălin Stan on 25/07/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CRRouter.h"

NS_ASSUME_NONNULL_BEGIN

@interface CRRouter ()

- (void)addRoute:(CRRoute *)route;
- (NSArray<CRRouteMatchingResult *> *)routesForPath:(NSString *)path HTTPMethod:(CRHTTPMethod)method;

- (void)executeRoutes:(NSArray<CRRouteMatchingResult *> *)routes forRequest:(CRRequest *)request response:(CRResponse *)response;
- (void)executeRoutes:(NSArray<CRRouteMatchingResult *> *)routes forRequest:(CRRequest *)request response:(CRResponse *)response withNotFoundBlock:(CRRouteBlock _Nullable)notFoundBlock;

@end

NS_ASSUME_NONNULL_END
