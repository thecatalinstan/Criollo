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

+ (nonnull CRRoute *)routeWithBlock:(nonnull CRRouteBlock)block;
+ (nonnull CRRoute *)routeWithControllerClass:(nonnull __unsafe_unretained Class)controllerClass nibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil;

- (nonnull instancetype)initWithBlock:(nonnull CRRouteBlock)block NS_DESIGNATED_INITIALIZER;
- (nonnull instancetype)initWithControllerClass:(nonnull __unsafe_unretained Class)controllerClass nibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil;

@end
