//
//  CRRoutingCenter.h
//  Criollo
//
//  Created by Cătălin Stan on 19/07/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CRTypes.h"

#define CRPathVarsKey       @"vars"

@class CRRoute, CRRouteMatchingResult;

NS_ASSUME_NONNULL_BEGIN

@interface CRRouter : NSObject

+ (CRRouteBlock)errorHandlingBlockWithStatus:(NSUInteger)statusCode error:(NSError * _Nullable)error;

@property (nonatomic, strong) CRRouteBlock notFoundBlock;

- (void)add:(CRRouteBlock)block;
- (void)add:(NSString * _Nullable)path block:(CRRouteBlock)block;
- (void)add:(NSString * _Nullable)path block:(CRRouteBlock)block recursive:(BOOL)recursive method:(CRHTTPMethod)method;

- (void)get:(NSString * _Nullable)path block:(CRRouteBlock)block;
- (void)post:(NSString * _Nullable)path block:(CRRouteBlock)block;
- (void)put:(NSString * _Nullable)path block:(CRRouteBlock)block;
- (void)delete:(NSString * _Nullable)path block:(CRRouteBlock)block;
- (void)head:(NSString * _Nullable)path block:(CRRouteBlock)block;
- (void)options:(NSString * _Nullable)path block:(CRRouteBlock)block;

- (void)add:(NSString *)path controller:(__unsafe_unretained Class)controllerClass;
- (void)add:(NSString *)path controller:(__unsafe_unretained Class)controllerClass recursive:(BOOL)recursive method:(CRHTTPMethod)method;

- (void)add:(NSString *)path viewController:(__unsafe_unretained Class)viewControllerClass withNibName:(NSString * _Nullable)nibNameOrNil bundle:(NSBundle * _Nullable)nibBundleOrNil;
- (void)add:(NSString *)path viewController:(__unsafe_unretained Class)viewControllerClass withNibName:(NSString * _Nullable)nibNameOrNil bundle:(NSBundle * _Nullable)nibBundleOrNil recursive:(BOOL)recursive method:(CRHTTPMethod)method;

- (void)mount:(NSString *)path directoryAtPath:(NSString *)directoryPath;
- (void)mount:(NSString *)path directoryAtPath:(NSString *)directoryPath options:(CRStaticDirectoryServingOptions)options;

- (void)mount:(NSString *)path fileAtPath:(NSString *)filePath;
- (void)mount:(NSString *)path fileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options fileName:(NSString * _Nullable)fileName contentType:(NSString * _Nullable)contentType contentDisposition:(CRStaticFileContentDisposition)contentDisposition;

@end

NS_ASSUME_NONNULL_END