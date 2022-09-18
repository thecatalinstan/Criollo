//
//  CRHTTPVersion.h
//  
//
//  Created by Cătălin Stan on 18/09/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// The HTTP version identifiers.
/// See [RFC2616 section 3.1](https://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.1).
typedef NSString *CRHTTPVersion NS_TYPED_ENUM;

/// HTTP version 1.0. (HTTP/1.0)
FOUNDATION_EXTERN CRHTTPVersion const CRHTTPVersion1_0;

/// HTTP version 1.1. (HTTP/1.1)
FOUNDATION_EXTERN CRHTTPVersion const CRHTTPVersion1_1;

/// HTTP version 2.0. (HTTP/2.0)
FOUNDATION_EXTERN CRHTTPVersion const CRHTTPVersion2_0 NS_AVAILABLE(10_10, 8_0);

/// HTTP version 3.0. (HTTP/3.0)
FOUNDATION_EXTERN CRHTTPVersion const CRHTTPVersion3_0 NS_AVAILABLE(10_15, 13_0);


FOUNDATION_EXTERN CRHTTPVersion _Nullable CRHTTPVersionFromString(NSString * versionSpec);

NS_ASSUME_NONNULL_END
