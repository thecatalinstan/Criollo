//
//  CRStaticDirectoryManager.h
//  Criollo
//
//  Created by Cătălin Stan on 2/10/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CRTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface CRStaticDirectoryManager : NSObject

@property (nonatomic, readonly, copy) CRRouteBlock routeBlock;

+ (instancetype)managerWithDirectoryAtPath:(NSString *)path prefix:(NSString *)prefix;
+ (instancetype)managerWithDirectoryAtPath:(NSString *)path prefix:(NSString *)prefix options:(CRStaticDirectoryServingOptions)options;

- (instancetype)initWithDirectoryAtPath:(NSString *)path prefix:(NSString *)prefix;
- (instancetype)initWithDirectoryAtPath:(NSString *)path prefix:(NSString *)prefix options:(CRStaticDirectoryServingOptions)options NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
