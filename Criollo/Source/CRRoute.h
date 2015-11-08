//
//  CRRoute.h
//  Criollo
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRRoutingCenter.h"

@interface CRRoute : NSObject

@property (nonatomic, strong) CRRouteHandlerBlock handlerBlock;

+ (CRRoute*)routeWithHandlerBlock:(CRRouteHandlerBlock)handlerBlock;

- (instancetype)initWithHandlerBlock:(CRRouteHandlerBlock)handlerBlock NS_DESIGNATED_INITIALIZER;

@end
