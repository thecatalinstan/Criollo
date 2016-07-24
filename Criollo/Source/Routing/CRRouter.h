//
//  CRRoutingCenter.h
//  Criollo
//
//  Created by Cătălin Stan on 19/07/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CRTypes.h"

@class CRRoute;

NS_ASSUME_NONNULL_BEGIN

@interface CRRouter : NSObject

+ (CRRouteBlock)errorHandlingBlockWithStatus:(NSUInteger)statusCode error:(NSError * _Nullable)error;

@property (nonatomic, strong) CRRouteBlock notFoundBlock;

- (void)addRoute:(CRRoute *)route;

- (NSArray<CRRoute *> *)routesForPath:(NSString *)path HTTPMethod:(CRHTTPMethod)method;

- (void)executeRoutes:(NSArray<CRRoute *> *)routes forRequest:(CRRequest *)request response:(CRResponse *)response;
- (void)executeRoutes:(NSArray<CRRoute *> *)routes forRequest:(CRRequest *)request response:(CRResponse *)response withNotFoundBlock:(CRRouteBlock _Nullable)notFoundBlock;

- (void)addBlock:(CRRouteBlock)block;
- (void)addBlock:(CRRouteBlock)block forPath:(NSString * _Nullable)path;
- (void)addBlock:(CRRouteBlock)block forPath:(NSString * _Nullable)path HTTPMethod:(CRHTTPMethod)method;
- (void)addBlock:(CRRouteBlock)block forPath:(NSString * _Nullable)path HTTPMethod:(CRHTTPMethod)method recursive:(BOOL)recursive;

- (void)addController:(__unsafe_unretained Class)controllerClass forPath:(NSString *)path;
- (void)addController:(__unsafe_unretained Class)controllerClass forPath:(NSString *)path HTTPMethod:(CRHTTPMethod)method;
- (void)addController:(__unsafe_unretained Class)controllerClass forPath:(NSString *)path HTTPMethod:(CRHTTPMethod)method recursive:(BOOL)recursive;

- (void)addViewController:(__unsafe_unretained Class)viewControllerClass withNibName:(NSString * _Nullable)nibNameOrNil bundle:(NSBundle * _Nullable)nibBundleOrNil forPath:(NSString *)path;
- (void)addViewController:(__unsafe_unretained Class)viewControllerClass withNibName:(NSString * _Nullable)nibNameOrNil bundle:(NSBundle * _Nullable)nibBundleOrNil forPath:(NSString *)path HTTPMethod:(CRHTTPMethod)method;
- (void)addViewController:(__unsafe_unretained Class)viewControllerClass withNibName:(NSString * _Nullable)nibNameOrNil bundle:(NSBundle * _Nullable)nibBundleOrNil forPath:(NSString *)path HTTPMethod:(CRHTTPMethod)method recursive:(BOOL)recursive;

@end

NS_ASSUME_NONNULL_END