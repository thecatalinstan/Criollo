//
//  CRStaticDirectoryManager.m
//  Criollo
//
//  Created by Cătălin Stan on 2/10/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CRStaticDirectoryManager.h"

@interface CRStaticDirectoryManager ()

@property (nonatomic, nonnull, readonly) NSString * prefix;
@property (nonatomic, readonly) CRStaticDirectoryServingOptions options;

@end

@implementation CRStaticDirectoryManager

+ (instancetype)managerWithDirectory:(NSString *)directoryPath prefix:(NSString *)prefix {
    return [[CRStaticDirectoryManager alloc] initWithDirectory:directoryPath prefix:prefix options:0];
}

+ (instancetype)managerWithDirectory:(NSString *)directoryPath prefix:(NSString *)prefix options:(CRStaticDirectoryServingOptions)options {
    return [[CRStaticDirectoryManager alloc] initWithDirectory:directoryPath prefix:prefix options:options];
}

- (instancetype)init {
    return  [self initWithDirectory:[NSBundle mainBundle].bundlePath prefix:@"/" options:0];
}

- (instancetype)initWithDirectory:(NSString *)directoryPath prefix:(NSString *)prefix {
    return [self initWithDirectory:directoryPath prefix:prefix options:0];
}

- (instancetype)initWithDirectory:(NSString *)directoryPath prefix:(NSString *)prefix options:(CRStaticDirectoryServingOptions)options {
    self = [super init];
    if ( self != nil ) {
        _directoryPath = directoryPath;
        _prefix = prefix;
        _options = options;
    }
    return self;
}

@end