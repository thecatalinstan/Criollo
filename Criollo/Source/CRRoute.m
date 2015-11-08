//
//  CRRoute.m
//  Criollo
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRRoute.h"

@interface CRRoute ()

@end

@implementation CRRoute

+ (CRRoute *)routeWithHandlerBlock:(CRRouteHandlerBlock)handlerBlock {
    return [[CRRoute alloc] initWithHandlerBlock:handlerBlock];
}

- (instancetype)init {
    return [self initWithHandlerBlock:nil];
}

- (instancetype)initWithHandlerBlock:(CRRouteHandlerBlock)handlerBlock {
    self = [super init];
    if ( self != nil ) {
        _handlerBlock = handlerBlock;
    }
    return self;
}

@end
