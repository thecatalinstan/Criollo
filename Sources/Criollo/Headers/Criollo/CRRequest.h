//
//  CRRequest.h
//
//
//  Created by Cătălin Stan on 3/30/14.
//

#import <Criollo/CRHTTPMethod.h>
#import <Criollo/CRMessage.h>
#import <Foundation/Foundation.h>

@class CRResponse, CRUploadedFile, CRConnection, CRRequestRange;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const CRRequestErrorDomain;
NS_ERROR_ENUM(CRRequestErrorDomain, CRRequestErrorCode) {
    CRErrorRequestMalformedRequest = 1001,
    CRErrorRequestUnsupportedMethod = 1002,
    CRRequestErrorMalformedBody = 3001,
    CRRequestFileWriteError = 3010,
};

#pragma mark - Request Content Types

/// Mime types of the requests we support body parsing for
typedef NSString * CRRequestContentType NS_TYPED_EXTENSIBLE_ENUM;

FOUNDATION_EXPORT CRRequestContentType const CRRequestContentTypeJSON;
FOUNDATION_EXPORT CRRequestContentType const CRRequestContentTypeURLEncoded;
FOUNDATION_EXPORT CRRequestContentType const CRRequestContentTypeMultipart;
FOUNDATION_EXPORT CRRequestContentType const CRRequestContentTypeOther;

@interface NSString (CRRequestContentType)

@property (nonatomic, readonly, strong) CRRequestContentType requestContentType;

@end

@interface CRRequest : CRMessage

@property (nonatomic, readonly) NSURL *URL;
@property (nonatomic, readonly) CRHTTPMethod method;

@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> *env;
@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> *query;
@property (nonatomic, readonly, nullable) NSDictionary<NSString *, NSString *> *cookies;
@property (nonatomic, readonly, nullable) id body;
@property (nonatomic, readonly, nullable) NSDictionary<NSString *, CRUploadedFile *> *files;

@property (nonatomic, readonly, nullable) CRRequestRange *range;

@end

NS_ASSUME_NONNULL_END
