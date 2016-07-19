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

NS_ASSUME_NONNULL_BEGIN

@interface CRRouteController ()

@property (nonatomic, strong, readonly) NSString *prefix;

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
        [self didLoad];
    }
    return self;
}

- (void)didLoad {
}

- (CRRouteBlock)routeBlock {
    return ^(CRRequest *request, CRResponse *response, CRRouteCompletionBlock completionHandler) {
        NSString* requestedDocumentPath = request.env[@"DOCUMENT_URI"];
        NSLog(@" * requestedDocumentPath = %@", requestedDocumentPath);
        NSString* requestedRelativePath = [[requestedDocumentPath substringFromIndex:self.prefix.length] stringByStandardizingPath];
        NSLog(@" * requestedRelativePath = %@", requestedRelativePath);

        NSArray<CRRoute*>* routes = [self routesForPath:requestedRelativePath HTTPMethod:request.method];
        [self executeRoutes:routes forRequest:request response:response];

        completionHandler();
    };
}

@end
