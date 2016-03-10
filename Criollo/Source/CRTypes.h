//
//  CRTypes.h
//  Criollo
//
//  Created by Cătălin Stan on 11/20/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#ifndef CRTypes_h
#define CRTypes_h

@class CRRequest, CRResponse;

typedef void(^CRRouteCompletionBlock)(void);
typedef void(^CRRouteBlock)(CRRequest* _Nonnull request, CRResponse* _Nonnull response, CRRouteCompletionBlock _Nonnull completionHandler);

typedef NS_OPTIONS(NSUInteger, CRStaticDirectoryServingOptions) {
    CRStaticDirectoryServingOptionsCacheFiles               = 1 <<   0,
    CRStaticDirectoryServingOptionsAutoIndex                = 1 <<   1,
    CRStaticDirectoryServingOptionsAutoIndexShowHidden      = 1 <<   2,
    CRStaticDirectoryServingOptionsFollowSymlinks           = 1 <<   3,
};

typedef NS_OPTIONS(NSUInteger, CRStaticFileServingOptions) {
    CRStaticFileServingOptionsCache             = 1 <<   0,
    CRStaticFileServingOptionsFollowSymlinks    = 1 <<   3,
};


#endif /* CRTypes_h */
