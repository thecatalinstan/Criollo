//
//  CRRoute.m
//  Criollo
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRRoute.h"
#import "CRRoute_Internal.h"
#import "CRTypes.h"
#import "CRServer_Internal.h"
#import "CRRouteController.h"
#import "CRViewController.h"
#import "CRRequest.h"
#import "CRRequest_Internal.h"
#import "CRResponse.h"
#import "CRResponse_Internal.h"
#import "CRStaticDirectoryManager.h"
#import "CRStaticFileManager.h"

@interface CRRoute ()

@end

@implementation CRRoute

- (NSString *)description {
    return [NSString stringWithFormat:@"<CRRoute %@, %@ %@%@>", @(self.hash), NSStringFromCRHTTPMethod(self.method), self.path ? : @"*", self.recursive ? @" recursive" : @""];
}

- (instancetype)init {
    return [self initWithBlock:^(CRRequest *request, CRResponse *response, CRRouteCompletionBlock completionHandler) {} method:CRHTTPMethodAll path:nil recursive:NO];
}

- (instancetype)initWithBlock:(CRRouteBlock)block method:(CRHTTPMethod)method path:(NSString * _Nullable)path recursive:(BOOL)recursive {
    self = [super init];
    if ( self != nil ) {
        self.block = block;
        self.method = method;
        self.path = path;
        self.recursive = recursive;

        if ( path != nil ) {
            __block BOOL isRegex = NO;
            _pathKeys = [NSMutableArray array];
            NSMutableArray<NSString *> * pathRegexComponents = [NSMutableArray array];
            [self.path.pathComponents enumerateObjectsUsingBlock:^(NSString * _Nonnull component, NSUInteger idx, BOOL * _Nonnull stop) {
                if ( [component hasPrefix:@":"] ) {
                    NSString *keyName = [component substringFromIndex:1];
                    if ( keyName.length == 0 ) {
                        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:NSLocalizedString(@"Invalid path variable name at position %lu",), idx]  userInfo:nil];
                    }
                    [((NSMutableArray *)_pathKeys) addObject:keyName];
                    [pathRegexComponents addObject:@"([a-zA-Z0-9\\+%]+)"];
                    isRegex = YES;
                } else if ( [component rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"[]().*|{}\\"]].location != NSNotFound ) {
                    NSString *keyName = @(_pathKeys.count).stringValue;
                    [((NSMutableArray *)_pathKeys) addObject:keyName];
                    [pathRegexComponents addObject:component];
                    isRegex = YES;
                } else {
                    [pathRegexComponents addObject:[component isEqualToString:CRPathSeparator] ? @"" : component];
                }
            }];
            if ( isRegex ) {
                NSError *regexError;
                NSString *pattern = [pathRegexComponents componentsJoinedByString:CRPathSeparator];
                _pathRegex = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&regexError];
                if ( _pathRegex == nil ) {
                    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:NSLocalizedString(@"Invalid path specification. \"%@\"",), _path]  userInfo:@{NSUnderlyingErrorKey: regexError}];
                }
            }
        }
    }
    return self;
}

- (instancetype)initWithControllerClass:(Class)controllerClass method:(CRHTTPMethod)method path:(NSString * _Nullable)path recursive:(BOOL)recursive {
    CRRouteBlock block = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        CRViewController* controller = [[controllerClass alloc] initWithPrefix:path];        
        controller.routeBlock(request, response, completionHandler);
    };
    return [self initWithBlock:block method:method path:path recursive:recursive];
}

- (instancetype)initWithViewControllerClass:(Class)viewControllerClass nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil method:(CRHTTPMethod)method path:(NSString * _Nullable)path recursive:(BOOL)recursive {
    CRRouteBlock block = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        CRViewController* viewController = [[viewControllerClass alloc] initWithNibName:nibNameOrNil bundle:nibBundleOrNil prefix:path];
        viewController.routeBlock(request, response, completionHandler);
    };
    return [self initWithBlock:block method:method path:path recursive:recursive];
}

- (instancetype)initWithStaticDirectoryAtPath:(NSString *)directoryPath options:(CRStaticDirectoryServingOptions)options path:(NSString * _Nullable)path {
    CRRouteBlock block = [CRStaticDirectoryManager managerWithDirectoryAtPath:directoryPath prefix:path options:options].routeBlock;
    return [self initWithBlock:block method:CRHTTPMethodGet path:path recursive:YES];
}

- (instancetype)initWithStaticFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options fileName:(NSString *)fileName contentType:(NSString * _Nullable)contentType contentDisposition:(CRStaticFileContentDisposition)contentDisposition path:(NSString * _Nullable)path {
    CRRouteBlock block = [CRStaticFileManager managerWithFileAtPath:filePath options:options fileName:fileName contentType:contentType contentDisposition:contentDisposition].routeBlock;
    return [self initWithBlock:block method:CRHTTPMethodGet path:path recursive:NO];
}

- (NSArray<NSString *> *)processMatchesInPath:(NSString *)path {
    NSMutableArray<NSString *> * result = [NSMutableArray array];
    NSArray<NSTextCheckingResult *> * matches = [self.pathRegex matchesInString:path options:0 range:NSMakeRange(0, path.length)];
    [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult * _Nonnull match, NSUInteger idx, BOOL * _Nonnull stop) {
        for( NSUInteger i = 1; i < match.numberOfRanges; i++ ) {
            [result addObject:[path substringWithRange:[match rangeAtIndex:i]]];
        }
    }];
    return result;
}

@end