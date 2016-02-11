//
//  CRRoute.h
//  Criollo
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRTypes.h"

#define CRPathSeparator                     @"/"
#define CRPathAnyPath                       @"*"

@class CRRequest, CRResponse;

@interface CRRoute : NSObject

@property (nonatomic, strong, nonnull) CRRouteBlock block;

+ (CRRoute * _Nonnull)routeWithBlock:(CRRouteBlock _Nonnull)block;
+ (CRRoute * _Nonnull)routeWithControllerClass:(__unsafe_unretained Class  _Nonnull)controllerClass nibName:(NSString * _Nullable)nibNameOrNil bundle:(NSBundle * _Nullable)nibBundleOrNil;
+ (CRRoute * _Nonnull)routeWithStaticDirectoryAtPath:(NSString * _Nonnull)directoryPath prefix:(NSString * _Nonnull)prefix options:(CRStaticDirectoryServingOptions)options;

- (nonnull instancetype)initWithBlock:(CRRouteBlock _Nonnull)block NS_DESIGNATED_INITIALIZER;
- (nonnull instancetype)initWithControllerClass:(__unsafe_unretained Class  _Nonnull)controllerClass nibName:(NSString * _Nullable)nibNameOrNil bundle:(NSBundle * _Nullable)nibBundleOrNil;
- (nonnull instancetype)initWithStaticDirectoryAtPath:(NSString * _Nonnull)directoryPath prefix:(NSString * _Nonnull)prefix options:(CRStaticDirectoryServingOptions)options;

@end
