//
//  CRRoute.h
//  Criollo
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRTypes.h"

@class CRRequest, CRResponse;

@interface CRRoute : NSObject

@property (nonatomic, strong, nonnull) CRRouteBlock block;

+ (CRRoute* _Nonnull)routeWithBlock:(CRRouteBlock _Nonnull)block;

- (instancetype _Nonnull)initWithBlock:(CRRouteBlock _Nonnull)block NS_DESIGNATED_INITIALIZER;

@end
