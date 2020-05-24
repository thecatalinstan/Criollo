//
//  CRStaticFileManager.h
//  Criollo
//
//  Created by Cătălin Stan on 10/03/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CRTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface CRStaticFileManager : NSObject

@property (nonatomic, readonly, copy) CRRouteBlock routeBlock;

#pragma mark - Convenience Class Initializers

+ (instancetype)managerWithFileAtPath:(NSString *)path;

+ (instancetype)managerWithFileAtPath:(NSString *)path
                              options:(CRStaticFileServingOptions)options;

+ (instancetype)managerWithFileAtPath:(NSString *)path
                              options:(CRStaticFileServingOptions)options
                             fileName:(NSString * _Nullable)fileName;

+ (instancetype)managerWithFileAtPath:(NSString *)path
                              options:(CRStaticFileServingOptions)options
                             fileName:(NSString * _Nullable)fileName
                          contentType:(NSString * _Nullable)contentType;

+ (instancetype)managerWithFileAtPath:(NSString *)path
                              options:(CRStaticFileServingOptions)options
                             fileName:(NSString * _Nullable)fileName
                          contentType:(NSString * _Nullable)contentType
                   contentDisposition:(CRStaticFileContentDisposition)contentDisposition;

+ (instancetype)managerWithFileAtPath:(NSString *)path
                              options:(CRStaticFileServingOptions)options
                             fileName:(NSString * _Nullable)fileName
                          contentType:(NSString * _Nullable)contentType
                   contentDisposition:(CRStaticFileContentDisposition)contentDisposition
                           attributes:(NSDictionary<NSFileAttributeKey, id> * _Nullable)attributes;

#pragma mark - Convenience Initializers

- (instancetype)initWithFileAtPath:(NSString *)path;

- (instancetype)initWithFileAtPath:(NSString *)path
                           options:(CRStaticFileServingOptions)options;

- (instancetype)initWithFileAtPath:(NSString *)path
                           options:(CRStaticFileServingOptions)options
                          fileName:(NSString * _Nullable)fileName;

- (instancetype)initWithFileAtPath:(NSString *)path
                           options:(CRStaticFileServingOptions)options
                          fileName:(NSString * _Nullable)fileName
                       contentType:(NSString * _Nullable)contentType;

- (instancetype)initWithFileAtPath:(NSString *)path
                           options:(CRStaticFileServingOptions)options
                          fileName:(NSString * _Nullable)fileName
                       contentType:(NSString * _Nullable)contentType
                contentDisposition:(CRStaticFileContentDisposition)contentDisposition;

- (instancetype)initWithFileAtPath:(NSString *)path
                           options:(CRStaticFileServingOptions)options
                          fileName:(NSString * _Nullable)fileName
                       contentType:(NSString * _Nullable)contentType
                contentDisposition:(CRStaticFileContentDisposition)contentDisposition
                        attributes:(NSDictionary<NSFileAttributeKey, id> * _Nullable)attributes NS_DESIGNATED_INITIALIZER;

NS_ASSUME_NONNULL_END

@end
