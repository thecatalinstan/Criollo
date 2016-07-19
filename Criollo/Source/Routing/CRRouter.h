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

- (NSArray<CRRoute *> *)routesForPath:(NSString *)path HTTPMethod:(CRHTTPMethod)method;
- (void)addRoute:(CRRoute *)route forPath:(NSString *)path HTTPMethod:(CRHTTPMethod)method recursive:(BOOL)recursive;

- (void)addBlock:(CRRouteBlock)block;
- (void)addBlock:(CRRouteBlock)block forPath:(NSString * _Nullable)path;
- (void)addBlock:(CRRouteBlock)block forPath:(NSString * _Nullable)path HTTPMethod:(CRHTTPMethod)method;
- (void)addBlock:(CRRouteBlock)block forPath:(NSString * _Nullable)path HTTPMethod:(CRHTTPMethod)method recursive:(BOOL)recursive;

- (void)addController:(__unsafe_unretained Class)controllerClass withNibName:(NSString * _Nullable)nibNameOrNil bundle:(NSBundle * _Nullable)nibBundleOrNil forPath:(NSString *)path;
- (void)addController:(__unsafe_unretained Class)controllerClass withNibName:(NSString * _Nullable)nibNameOrNil bundle:(NSBundle * _Nullable)nibBundleOrNil forPath:(NSString *)path HTTPMethod:(CRHTTPMethod)method;
- (void)addController:(__unsafe_unretained Class)controllerClass withNibName:(NSString * _Nullable)nibNameOrNil bundle:(NSBundle * _Nullable)nibBundleOrNil forPath:(NSString *)path HTTPMethod:(CRHTTPMethod)method recursive:(BOOL)recursive;

@end

NS_ASSUME_NONNULL_END