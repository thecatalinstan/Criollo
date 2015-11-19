//
//  CRRoute.h
//  Criollo
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

@class CRRequest, CRResponse;

typedef void(^CRRouteBlock)(CRRequest* request, CRResponse* response, void(^completionHandler)(void));

@interface CRRoute : NSObject

@property (nonatomic, strong) CRRouteBlock block;

+ (CRRoute*)routeWithBlock:(CRRouteBlock)block;

- (instancetype)initWithBlock:(CRRouteBlock)block NS_DESIGNATED_INITIALIZER;

@end
