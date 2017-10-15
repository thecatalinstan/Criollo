//
//  CRHTTPS.h
//  Criollo
//
//  Created by Cătălin Stan on 10/09/2017.
//  Copyright © 2017 Cătălin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CRHTTPSErrorDomain                     @"CRHTTPSErrorDomain"

#define CRHTTPSInternalError                   1000
#define CRHTTPSInvalidCertificateBundle        1001
#define CRHTTPSInvalidCertificatePrivateKey    1002
#define CRHTTPSInvalidIdentityFile             1003
#define CRHTTPSInvalidCredentialFiles          1004
#define CRHTTPSIdentityCreateError             1005

#define CRSSLErrorDomain                       @"CRSSLErrorDomain"

#define CRSSLInvalidCertificateBundle          CRHTTPSInvalidCertificateBundle
#define CRSSLInvalidCertificatePrivateKey      CRHTTPSInvalidCertificatePrivateKey
#define CRSSLIdentityCreateError               CRHTTPSIdentityCreateError

#define CRHTTPSIdentityPathKey                 @"CRHTTPSIdentityPath"
#define CRHTTPSCertificatePathKey              @"CRHTTPSCertificatePath"
#define CRHTTPSCertificateKeyPathKey           @"CRHTTPSCertificateKeyPath"

NS_ASSUME_NONNULL_BEGIN

@interface CRHTTPS : NSObject

+ (nullable NSArray *)parseIdentrityFile:(NSString *)identityFilePath password:(NSString *)password withError:(NSError * _Nullable __autoreleasing * _Nullable)error;
+ (nullable NSArray *)parseCertificateFile:(NSString *)certificatePath certificateKeyFile:(NSString *)certificateKeyPath withError:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
