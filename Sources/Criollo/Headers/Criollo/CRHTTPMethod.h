//
//  CRHTTPMethod.h
//  
//
//  Created by Cătălin Stan on 18/09/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// The HTTP request moethods.
/// @see [RFC9110 section 9.3](https://www.rfc-editor.org/rfc/rfc9110.html#name-method-definitions)
typedef NSString *CRHTTPMethod NS_TYPED_ENUM;

/// The GET HTTP request method. (GET)
FOUNDATION_EXPORT CRHTTPMethod const CRHTTPMethodGet;

/// The HEAD HTTP request method. (HEAD)
FOUNDATION_EXPORT CRHTTPMethod const CRHTTPMethodHead;

/// The POST HTTP request method. (POST)
FOUNDATION_EXPORT CRHTTPMethod const CRHTTPMethodPost;

/// The PUT HTTP request method. (PUT)
FOUNDATION_EXPORT CRHTTPMethod const CRHTTPMethodPut;

/// The DELETE HTTP request method. (DELETE)
FOUNDATION_EXPORT CRHTTPMethod const CRHTTPMethodDelete;

/// The CONNECT HTTP request method. (CONNECT)
FOUNDATION_EXPORT CRHTTPMethod const CRHTTPMethodConnect;

/// The OPTIONS HTTP request method. (OPTIONS)
FOUNDATION_EXPORT CRHTTPMethod const CRHTTPMethodOptions;

/// The PATCH HTTP request method. (PATCH)
FOUNDATION_EXPORT CRHTTPMethod const CRHTTPMethodPatch;

/// An abstraction for any HTTP request method. (ALL)
FOUNDATION_EXPORT CRHTTPMethod const CRHTTPMethodAny;

FOUNDATION_EXTERN CRHTTPMethod _Nullable CRHTTPMethodFromString(NSString *methodSpec);

NS_ASSUME_NONNULL_END
