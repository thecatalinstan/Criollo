//
//  CRTypes.h
//  Criollo
//
//  Created by Cătălin Stan on 11/20/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#ifndef CRTypes_h
#define CRTypes_h

typedef NS_ENUM(NSUInteger, CRHTTPMethod) {
    CRHTTPMethodGet     = 0,
    CRHTTPMethodPost    = 1,
    CRHTTPMethodPut     = 2,
    CRHTTPMethodDelete  = 3,
    CRHTTPMethodPatch   = 4,
    CRHTTPMethodOptions = 5,
};

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

typedef NS_ENUM(NSUInteger, CRStaticFileContentDisposition) {
    CRStaticFileContentDispositionNone,
    CRStaticFileContentDispositionInline,
    CRStaticFileContentDispositionAttachment
};

#endif /* CRTypes_h */
