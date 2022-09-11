//
//  CRRouter_Internal.h
//  Criollo
//
//  Created by Cătălin Stan on 25/07/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import <Criollo/CRRouter.h>

NS_ASSUME_NONNULL_BEGIN

@interface CRRouter ()

- (void)addRoute:(CRRoute *)route;
- (NSArray<CRRouteMatchingResult *> *)routesForPath:(NSString *)path method:(CRHTTPMethod)method;

- (void)executeRoutes:(NSArray<CRRouteMatchingResult *> *)routes request:(CRRequest *)request response:(CRResponse *)response withCompletion:(CRRouteCompletionBlock)completionBlock;
- (void)executeRoutes:(NSArray<CRRouteMatchingResult *> *)routes request:(CRRequest *)request response:(CRResponse *)response withCompletion:(CRRouteCompletionBlock)completionBlock notFoundBlock:(CRRouteBlock _Nullable)notFoundBlock;

+ (void)handleErrorResponse:(NSUInteger)statusCode error:(NSError *)error request:(CRRequest *)request response:(CRResponse *)response completion:(CRRouteCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
