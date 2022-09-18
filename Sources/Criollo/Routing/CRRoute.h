//
//  CRRoute.h
//
//
//  Created by Cătălin Stan on 11/8/15.
//

#import <Criollo/CRContentDisposition.h>
#import <Criollo/CRHTTPMethod.h>
#import <Criollo/CRRouteBlock.h>
#import <Criollo/CRStaticDirectoryServingOptions.h>
#import <Criollo/CRStaticFileServingOptions.h>
#import <Foundation/Foundation.h>

@class CRRequest, CRResponse;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const CRRoutePathSeparator;

@interface CRRoute : NSObject

@property (nonatomic, readonly) CRHTTPMethod method;
@property (nonatomic, readonly) NSString *path;
@property (nonatomic, readonly) BOOL recursive;
@property (nonatomic, readonly, copy) CRRouteBlock block;

- (instancetype)initWithBlock:(CRRouteBlock)block
                       method:(CRHTTPMethod)method
                         path:(NSString * _Nullable)path
                    recursive:(BOOL)recursive
NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)routeWithControllerClass:(__unsafe_unretained Class)controllerClass
                                  method:(CRHTTPMethod)method
                                    path:(NSString * _Nullable)path
                               recursive:(BOOL)recursive;

+ (instancetype)routeWithViewControllerClass:(__unsafe_unretained __kindof Class)viewControllerClass
                                     nibName:(NSString * _Nullable)nibNameOrNil
                                      bundle:(NSBundle * _Nullable)nibBundleOrNil
                                      method:(CRHTTPMethod)method
                                        path:(NSString * _Nullable)path
                                   recursive:(BOOL)recursive;

+ (instancetype)routeWithStaticDirectoryAtPath:(NSString *)directoryPath
                                       options:(CRStaticDirectoryServingOptions)options
                                          path:(NSString * _Nullable)path;

+ (instancetype)routeWithStaticFileAtPath:(NSString *)filePath
                                  options:(CRStaticFileServingOptions)options
                                 fileName:(NSString * _Nullable)fileName
                              contentType:(NSString * _Nullable)contentType
                       contentDisposition:(CRContentDisposition)contentDisposition
                                     path:(NSString * _Nullable)path;

@end

NS_ASSUME_NONNULL_END
