//
//  CRFCGIRequest.h
//
//
//  Created by Cătălin Stan on 10/31/15.
//

#import <Criollo/CRRequest.h>

typedef NS_ENUM(UInt8, CRFCGIRequestRole) {
    CRFCGIRequestRoleResponder = 1,
    CRFCGIRequestRoleAuthorizer = 2,
    CRFCGIRequestRoleFilter = 3
};

typedef NS_OPTIONS(NSUInteger, CRFCGIRequestFlags) {
    CRFCGIRequestFlagKeepAlive = 1 << 0,
};

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * NSStringFromCRFCGIRequestRole(CRFCGIRequestRole requestRole);

@interface CRFCGIRequest : CRRequest

@property (nonatomic, assign) UInt16 requestID;
@property (nonatomic, assign) CRFCGIRequestRole requestRole;
@property (nonatomic, assign) CRFCGIRequestFlags requestFlags;

@end

NS_ASSUME_NONNULL_END
