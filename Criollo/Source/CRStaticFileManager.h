//
//  CRStaticFileManager.h
//  Criollo
//
//  Created by Cătălin Stan on 10/03/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CRTypes.h"

@interface CRStaticFileManager : NSObject

NS_ASSUME_NONNULL_BEGIN

@property (nonatomic, readonly) NSString * filePath;
@property (nonatomic, readonly) NSDictionary * attributes;
@property (nonatomic, readonly, strong, nullable) NSError* attributesError;
@property (nonatomic, readonly) CRRouteBlock routeBlock;

@property (nonatomic, readonly) BOOL shouldCache;
@property (nonatomic, readonly) BOOL shouldFollowSymLinks;

@property (nonatomic, strong) NSString* fileName;
@property (nonatomic, strong) NSString* contentType;
@property (nonatomic, strong) NSString* contentDisposition;

+ (instancetype)managerWithFileAtPath:(NSString *)filePath;
+ (instancetype)managerWithFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options;
+ (instancetype)managerWithFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options attributes:(NSDictionary * _Nullable)attributes;

- (instancetype)initWithFileAtPath:(NSString *)filePath;
- (instancetype)initWithFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options;
- (instancetype)initWithFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options attributes:(NSDictionary * _Nullable)attributes NS_DESIGNATED_INITIALIZER;

NS_ASSUME_NONNULL_END

@end
