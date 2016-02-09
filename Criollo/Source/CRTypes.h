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
    CRStaticDirectoryServingOptionsCacheFiles         = 1 <<   0,
    CRStaticDirectoryServingOptionsAutoIndex          = 1 <<   1,
    CRStaticDirectoryServingOptionsFollowSymlinks     = 1 <<   2,
};

#endif /* CRTypes_h */
