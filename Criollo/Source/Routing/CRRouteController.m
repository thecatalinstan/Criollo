//
//  CRRouteController.m
//  Criollo
//
//  Created by Cătălin Stan on 19/07/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CRRouteController.h"
#import "CRRequest.h"
#import "CRRequest_Internal.h"
#import "CRResponse.h"
#import "CRResponse_Internal.h"
#import "CRRouteMatchingResult.h"

#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

@interface CRRouteController ()

@end

NS_ASSUME_NONNULL_END

@implementation CRRouteController

- (instancetype)init {
    return [self initWithPrefix:@"/"];
}

- (instancetype)initWithPrefix:(NSString *)prefix {
    self = [super init];
    if ( self != nil ) {
        _prefix = prefix;
    }
    return self;
}

- (NSString *)relativePathForRequestedPath:(NSString *)requestedPath {
    NSUInteger relativePathStart = [requestedPath rangeOfString:self.prefix options:NSBackwardsSearch].location;
    if ( relativePathStart == NSNotFound ) {
        relativePathStart = 0;
    }
    @try {
        return [[requestedPath substringFromIndex:relativePathStart + self.prefix.length] stringByStandardizingPath];
    } @catch (NSException *exception) {
        return @"/";
    }
}

- (CRRouteBlock)routeBlock {
    return ^(CRRequest *request, CRResponse *response, CRRouteCompletionBlock completionHandler) {        
        NSString* requestedRelativePath = [self relativePathForRequestedPath:request.env[@"DOCUMENT_URI"]];
        NSArray<CRRouteMatchingResult *>* routes = [self routesForPath:requestedRelativePath HTTPMethod:request.method];
        [self executeRoutes:routes forRequest:request response:response];
        completionHandler();
    };
}

@end
