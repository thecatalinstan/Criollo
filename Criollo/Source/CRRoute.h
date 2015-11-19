//
//  CRRoute.h
//  Criollo
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

@class CRRequest, CRResponse;

typedef void(^CRRouteCompletionBlock)(void);
typedef void(^CRRouteBlock)(CRRequest* _Nonnull request, CRResponse* _Nonnull response, CRRouteCompletionBlock _Nonnull completionHandler);

@interface CRRoute : NSObject

@property (nonatomic, strong, nonnull) CRRouteBlock block;

+ (CRRoute* _Nonnull)routeWithBlock:(CRRouteBlock _Nonnull)block;

- (instancetype _Nonnull)initWithBlock:(CRRouteBlock _Nonnull)block NS_DESIGNATED_INITIALIZER;

@end
