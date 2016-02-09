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
+ (CRRoute * _Nonnull)routeWithStaticFolder:(NSString * _Nonnull)folderPath prefix:(NSString * _Nonnull)prefix options:(CRStaticFolderServingOptions)options;

- (instancetype _Nonnull)initWithBlock:(CRRouteBlock _Nonnull)block NS_DESIGNATED_INITIALIZER;
- (instancetype _Nonnull)initWithControllerClass:(__unsafe_unretained Class  _Nonnull)controllerClass nibName:(NSString * _Nullable)nibNameOrNil bundle:(NSBundle * _Nullable)nibBundleOrNil;
- (instancetype _Nonnull)initWithStaticFolder:(NSString * _Nonnull)folderPath prefix:(NSString * _Nonnull)prefix options:(CRStaticFolderServingOptions)options;

@end
