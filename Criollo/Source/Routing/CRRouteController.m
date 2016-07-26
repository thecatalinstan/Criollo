//
//  CRRouteController.m
//  Criollo
//
//  Created by Cătălin Stan on 19/07/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CRRouteController.h"
#import "CRRouter_Internal.h"
#import "CRRoute.h"
#import "CRRequest.h"
#import "CRRequest_Internal.h"
#import "CRResponse.h"
#import "CRResponse_Internal.h"
#import "CRRouteMatchingResult.h"
#import "NSString+Criollo.h"

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

- (CRRouteBlock)routeBlock {
    return ^(CRRequest *request, CRResponse *response, CRRouteCompletionBlock completionHandler) {
        NSString* requestedPath = request.env[@"DOCUMENT_URI"];
        NSString* requestedRelativePath = [requestedPath pathRelativeToPath:self.prefix];
        NSArray<CRRouteMatchingResult *>* routes = [self routesForPath:requestedRelativePath method:request.method];
        [self executeRoutes:routes forRequest:request response:response];
        completionHandler();
    };
}

@end
