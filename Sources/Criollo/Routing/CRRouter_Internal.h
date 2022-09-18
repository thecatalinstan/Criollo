//
//  CRRouter_Internal.h
//
//
//  Created by Cătălin Stan on 25/07/16.
//

#import <Criollo/CRRouter.h>

@class CRRouteMatchingResult, CRRoute;

NS_ASSUME_NONNULL_BEGIN

@interface CRRouter ()

- (void)addRoute:(CRRoute *)route;
- (NSArray<CRRouteMatchingResult *> *)routesForPath:(NSString *)path method:(CRHTTPMethod)method;

- (void)executeRoutes:(NSArray<CRRouteMatchingResult *> *)routes request:(CRRequest *)request response:(CRResponse *)response withCompletion:(dispatch_block_t)completionBlock;
- (void)executeRoutes:(NSArray<CRRouteMatchingResult *> *)routes request:(CRRequest *)request response:(CRResponse *)response withCompletion:(dispatch_block_t)completionBlock notFoundBlock:(CRRouteBlock _Nullable)notFoundBlock;

+ (void)handleErrorResponse:(NSUInteger)statusCode error:(NSError *)error request:(CRRequest *)request response:(CRResponse *)response completion:(dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
