//
//  CRHTTPS.h
//  Criollo
//
//  Created by Cătălin Stan on 10/09/2017.
//  Copyright © 2017 Cătălin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const CRHTTPSErrorDomain;

FOUNDATION_EXPORT NSUInteger const CRHTTPSInternalError;
FOUNDATION_EXPORT NSUInteger const CRHTTPSInvalidCertificateError;
FOUNDATION_EXPORT NSUInteger const CRHTTPSInvalidPrivateKeyError;
FOUNDATION_EXPORT NSUInteger const CRHTTPSInvalidIdentityError;
FOUNDATION_EXPORT NSUInteger const CRHTTPSInvalidPasswordError;
FOUNDATION_EXPORT NSUInteger const CRHTTPSMissingCredentialsError;
FOUNDATION_EXPORT NSUInteger const CRHTTPSCreateIdentityError;

FOUNDATION_EXPORT NSString * const CRHTTPSIdentityPathKey;
FOUNDATION_EXPORT NSString * const CRHTTPSCertificatePathKey;
FOUNDATION_EXPORT NSString * const CRHTTPSCertificateKeyPathKey;

@interface CRHTTPS : NSObject

+ (nullable NSArray *)parseIdentrityFile:(NSString *)identityFilePath password:(NSString *)password withError:(NSError * _Nullable __autoreleasing * _Nullable)error;
+ (nullable NSArray *)parseCertificateFile:(NSString *)certificatePath certificateKeyFile:(NSString *)certificateKeyPath withError:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
