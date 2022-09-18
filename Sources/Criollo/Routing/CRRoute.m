//
//  CRRoute.m
//
//
//  Created by Cătălin Stan on 11/8/15.
//

#import "CRRoute_Internal.h"

#import <Criollo/CRRouteController.h>
#import <Criollo/CRStaticDirectoryManager.h>
#import <Criollo/CRStaticFileManager.h>
#import <Criollo/CRViewController.h>

#import "CRRequest_Internal.h"
#import "CRResponse_Internal.h"
#import "CRServer_Internal.h"

NSString * const CRRoutePathSeparator = @"/";
static NSString * const CRPathAnyPath = @"*";

@implementation CRRoute

- (NSString *)description {
    return [NSString stringWithFormat:@"<CRRoute %@, %@ %@%@>", @(self.hash), self.method, self.path ? : @"*", self.recursive ? @" recursive" : @""];
}

- (instancetype)initWithBlock:(CRRouteBlock)block method:(CRHTTPMethod)method path:(NSString * _Nullable)path recursive:(BOOL)recursive {
    self = [super init];
    if ( self != nil ) {
        _block = block;
        _method = method;
        _path = path;
        _recursive = recursive;

        if ( self.path != nil ) {
            __block BOOL isRegex = NO;
            NSMutableArray<NSString *> *pathRegexComponents = [NSMutableArray array];
            NSMutableArray<NSString *> *pathKeys = [NSMutableArray array];
            [self.path.pathComponents enumerateObjectsUsingBlock:^(NSString * _Nonnull component, NSUInteger idx, BOOL * _Nonnull stop) {
                if ( [component hasPrefix:@":"] ) {
                    NSString *keyName = [component substringFromIndex:1];
                    if ( keyName.length == 0 ) {
                        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:NSLocalizedString(@"Invalid path variable name at position %lu",), (unsigned long)idx]  userInfo:nil];
                    }
                    [pathKeys addObject:keyName];
                    [pathRegexComponents addObject:@"([a-zA-Z0-9\\+\\-_%\\.]+)"];
                    isRegex = YES;
                } else {
                    NSCharacterSet* regexChars = [NSCharacterSet characterSetWithCharactersInString:@"[]()*+|{}\\"];
                    NSRange range = [component rangeOfCharacterFromSet:regexChars];
                    if ( range.location != NSNotFound ) {
                        NSString *keyName = @(pathKeys.count).stringValue;
                        [pathKeys addObject:keyName];
                        if ( [component hasPrefix:@"("] && [component hasSuffix:@")"] ) {
                            [pathRegexComponents addObject:component];
                        } else {
                            [pathRegexComponents addObject:[NSString stringWithFormat:@"(%@)", component]];
                        }
                        isRegex = YES;
                    } else {
                        [pathRegexComponents addObject:[component isEqualToString:CRRoutePathSeparator] ? @"" : component];
                    }
                }
            }];
            _pathKeys = pathKeys;
            
            if ( isRegex ) {
                NSError *regexError;
                NSMutableString *pattern = [NSMutableString stringWithString:@"^" ];
                [pattern appendString:[pathRegexComponents componentsJoinedByString:CRRoutePathSeparator]];
                if ( !self.recursive ) {
                    [pattern appendString:@"$"];
                }
                _pathRegex = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&regexError];
                if ( self.pathRegex == nil ) {
                    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:NSLocalizedString(@"Invalid path specification. \"%@\"",), _path]  userInfo:@{NSUnderlyingErrorKey: regexError}];
                }
            }
        }
    }
    return self;
}

+ (instancetype)routeWithControllerClass:(Class)controllerClass method:(CRHTTPMethod)method path:(NSString * _Nullable)path recursive:(BOOL)recursive {
    CRRouteBlock block = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, dispatch_block_t  _Nonnull completionHandler) {
        @autoreleasepool {
            CRViewController* controller = [[controllerClass alloc] initWithPrefix:path];
            controller.routeBlock(request, response, completionHandler);
        }
    };
    return [[self alloc] initWithBlock:block method:method path:path recursive:recursive];
}

+ (instancetype)routeWithViewControllerClass:(Class)viewControllerClass nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil method:(CRHTTPMethod)method path:(NSString * _Nullable)path recursive:(BOOL)recursive {
    CRRouteBlock block = ^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, dispatch_block_t  _Nonnull completionHandler) {
        @autoreleasepool {
            CRViewController* viewController = [[viewControllerClass alloc] initWithNibName:nibNameOrNil bundle:nibBundleOrNil prefix:path];
            viewController.routeBlock(request, response, completionHandler);
        }
    };
    return [[self alloc] initWithBlock:block method:method path:path recursive:recursive];
}

+ (instancetype)routeWithStaticDirectoryAtPath:(NSString *)directoryPath options:(CRStaticDirectoryServingOptions)options path:(NSString * _Nullable)path {
    CRStaticDirectoryManager *manager = [CRStaticDirectoryManager managerWithDirectoryAtPath:directoryPath prefix:path options:options];
    CRRoute *route = [[self alloc] initWithBlock:manager.routeBlock method:CRHTTPMethodGet path:path recursive:YES];
    route.associatedObject = manager;
    return route;
}

+ (instancetype)routeWithStaticFileAtPath:(NSString *)filePath options:(CRStaticFileServingOptions)options fileName:(NSString *)fileName contentType:(NSString * _Nullable)contentType contentDisposition:(CRContentDisposition)contentDisposition path:(NSString * _Nullable)path {
    CRStaticFileManager *manager = [[CRStaticFileManager alloc] initWithFileAtPath:filePath options:options fileName:fileName contentType:contentType contentDisposition:contentDisposition attributes:nil];
    CRRoute *route = [[self alloc] initWithBlock:manager.routeBlock method:CRHTTPMethodGet path:path recursive:NO];
    route.associatedObject = manager;
    return route;
}

- (NSArray<NSString *> *)processMatchesInPath:(NSString *)path {
    NSMutableArray<NSString *> *result = [NSMutableArray arrayWithCapacity:8];
    NSArray<NSTextCheckingResult *> *matches = [self.pathRegex matchesInString:path options:0 range:NSMakeRange(0, path.length)];
    for (NSTextCheckingResult *match in matches) {
        for(NSUInteger i = 1; i < match.numberOfRanges; i++) {
            [result addObject:[path substringWithRange:[match rangeAtIndex:i]]];
        }
    }
    return result;
}

@end
