//
//  CRContentDisposition.h
//  
//
//  Created by Cătălin Stan on 18/09/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///  The HTTP Content-Disposition header specification.
///
///  @see [RFC2616 section 19.5.1](https://www.w3.org/Protocols/rfc2616/rfc2616-sec19.html#sec19.5.1)
typedef NSString *CRContentDisposition NS_TYPED_ENUM;

FOUNDATION_EXPORT CRContentDisposition const CRContentDispositionInline;
FOUNDATION_EXPORT CRContentDisposition const CRContentDispositionAttachment;

FOUNDATION_EXPORT CRContentDisposition _Nullable CRContentDispositionMake(NSString *contentDispositionName);

NS_ASSUME_NONNULL_END
