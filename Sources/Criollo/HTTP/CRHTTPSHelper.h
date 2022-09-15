//
//  CRHTTPSHelper.h
//
//
//  Created by Cătălin Stan on 10/09/2017.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const CRHTTPSErrorDomain;

FOUNDATION_EXPORT NSUInteger const CRHTTPSInternalError;
FOUNDATION_EXPORT NSUInteger const CRHTTPSInvalidIdentityError;
FOUNDATION_EXPORT NSUInteger const CRHTTPSInvalidPasswordError;
FOUNDATION_EXPORT NSUInteger const CRHTTPSMissingCredentialsError;

FOUNDATION_EXPORT NSString * const CRHTTPSIdentityPathKey;

#if SEC_OS_OSX_INCLUDES

FOUNDATION_EXPORT NSUInteger const CRHTTPSInvalidCertificateError;
FOUNDATION_EXPORT NSUInteger const CRHTTPSInvalidPrivateKeyError;
FOUNDATION_EXPORT NSUInteger const CRHTTPSCreateIdentityError;

FOUNDATION_EXPORT NSString * const CRHTTPSCertificatePathKey;
FOUNDATION_EXPORT NSString * const CRHTTPSCertificateKeyPathKey;

#endif

@interface CRHTTPSHelper : NSObject

- (nullable NSArray *)parseIdentrityFile:(NSString *)identityFilePath password:(NSString *)password error:(NSError * _Nullable __autoreleasing * _Nullable)error;

#if SEC_OS_OSX_INCLUDES
- (nullable NSArray *)parseCertificateFile:(NSString *)certificatePath privateKeyFile:(NSString *)privateKeyPath error:(NSError * _Nullable __autoreleasing * _Nullable)error;
#endif

@end

NS_ASSUME_NONNULL_END
