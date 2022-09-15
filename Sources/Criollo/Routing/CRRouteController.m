//
//  CRRouteController.m
//
//
//  Created by Cătălin Stan on 19/07/16.
//

#import <Criollo/CRRouteController.h>

#import <Criollo/CRRequest.h>
#import <Criollo/CRResponse.h>

#import "CRRequest_Internal.h"
#import "CRResponse_Internal.h"
#import "CRRoute.h"
#import "CRRouteMatchingResult.h"
#import "CRRouter_Internal.h"
#import "NSString+Criollo.h"

NS_ASSUME_NONNULL_BEGIN

@interface CRRouteController ()

@end

NS_ASSUME_NONNULL_END

@implementation CRRouteController

- (instancetype)init {
    return [self initWithPrefix:CRRoutePathSeparator];
}

- (instancetype)initWithPrefix:(NSString *)prefix {
    self = [super init];
    if ( self != nil ) {
        _prefix = prefix;

        CRRouteController * __weak controller = self;
        _routeBlock = ^(CRRequest *request, CRResponse *response, CRRouteCompletionBlock completionHandler) {
            @autoreleasepool {
                NSString* requestedPath = request.env[@"DOCUMENT_URI"];
                NSString* requestedRelativePath = [requestedPath pathRelativeToPath:controller.prefix separator:CRRoutePathSeparator];
                NSArray<CRRouteMatchingResult *>* routes = [controller routesForPath:requestedRelativePath method:request.method];
                [controller executeRoutes:routes request:request response:response withCompletion:completionHandler];
            }
        };
    }
    return self;
}
@end
