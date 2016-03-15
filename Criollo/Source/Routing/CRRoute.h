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

NS_ASSUME_NONNULL_BEGIN

@interface CRRoute : NSObject

@property (nonatomic, strong) CRRouteBlock block;

+ (CRRoute *)routeWithBlock:(CRRouteBlock)block;
+ (CRRoute *)routeWithControllerClass:(__unsafe_unretained Class )controllerClass nibName:(NSString * _Nullable)nibNameOrNil bundle:(NSBundle * _Nullable)nibBundleOrNil;
+ (CRRoute *)routeWithStaticDirectoryAtPath:(NSString *)directoryPath prefix:(NSString *)prefix options:(CRStaticDirectoryServingOptions)options;
+ (CRRoute *)routeWithStaticFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options fileName:(NSString * _Nullable)fileName contentType:(NSString * _Nullable)contentType contentDisposition:(CRStaticFileContentDisposition)contentDisposition;

- (instancetype)initWithBlock:(CRRouteBlock)block NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithControllerClass:(__unsafe_unretained Class )controllerClass nibName:(NSString * _Nullable)nibNameOrNil bundle:(NSBundle * _Nullable)nibBundleOrNil;
- (instancetype)initWithStaticDirectoryAtPath:(NSString *)directoryPath prefix:(NSString *)prefix options:(CRStaticDirectoryServingOptions)options;
- (instancetype)initWithStaticFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options fileName:(NSString * _Nullable)fileName contentType:(NSString * _Nullable)contentType contentDisposition:(CRStaticFileContentDisposition)contentDisposition;

NS_ASSUME_NONNULL_END

@end
