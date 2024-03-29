//
//  CRRouteMatchingResult_Internal.h
//
//
//  Created by Cătălin Stan on 24/07/16.
//

#import "CRRouteMatchingResult.h"

@class CRRoute;

NS_ASSUME_NONNULL_BEGIN

@interface CRRouteMatchingResult ()

+ (instancetype)routeMatchingResultWithRoute:(CRRoute *)route matches:(NSArray<NSString *> * _Nullable)matches;

- (instancetype)initWithRoute:(CRRoute *)route matches:(NSArray<NSString *> * _Nullable)matches NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
