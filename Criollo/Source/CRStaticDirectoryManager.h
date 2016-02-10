//
//  CRStaticDirectoryManager.h
//  Criollo
//
//  Created by Cătălin Stan on 2/10/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CRTypes.h"

#define CRStaticDirectoryManagerErrorDomain                         @"CRStaticDirectoryManagerErrorDomain"

#define CRStaticDirectoryManagerReleaseFailed                       101
#define CRStaticDirectoryManagerDirectoryListingForbidden           102
#define CRStaticDirectoryManagerRestrictedFileType                  103

@interface CRStaticDirectoryManager : NSObject

@property (nonatomic, nonnull, readonly) NSString * directoryPath;
@property (nonatomic, nonnull, readonly) CRRouteBlock routeBlock;

@property (nonatomic, readonly) BOOL shouldCacheFiles;
@property (nonatomic, readonly) BOOL shouldGenerateDirectoryIndex;
@property (nonatomic, readonly) BOOL shouldShowHiddenFilesInDirectoryIndex;
@property (nonatomic, readonly) BOOL shouldFollowSymLinks;

+ (nonnull instancetype)managerWithDirectory:(NSString * _Nonnull)directoryPath prefix:(NSString * _Nonnull)prefix;
+ (nonnull instancetype)managerWithDirectory:(NSString * _Nonnull)directoryPath prefix:(NSString * _Nonnull)prefix options:(CRStaticDirectoryServingOptions)options;

- (nonnull instancetype)initWithDirectory:(NSString * _Nonnull)directoryPath prefix:(NSString * _Nonnull)prefix;
- (nonnull instancetype)initWithDirectory:(NSString * _Nonnull)directoryPath prefix:(NSString * _Nonnull)prefix options:(CRStaticDirectoryServingOptions)options NS_DESIGNATED_INITIALIZER;

@end
