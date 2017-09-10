//
//  CRHTTPServer.h
//  Criollo
//
//  Created by Cătălin Stan on 10/25/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//


#import "CRServer.h"

#define CRHTTPServerErrorDomain                     @"CRHTTPServerErrorDomain"

#define CRHTTPServerInternalError                   1000
#define CRHTTPServerInvalidCertificateBundle        1001
#define CRHTTPServerInvalidCertificatePrivateKey    1002
#define CRHTTPServerInvalidIdentityFile             1003
#define CRHTTPServerInvalidCredentialFiles          1004

#define CRHTTPServerIdentityPathKey                 @"CRHTTPServerIdentityPath"
#define CRHTTPServerCertificatePathKey              @"CRHTTPServerCertificatePath"
#define CRHTTPServerCertificateKeyPathKey           @"CRHTTPServerCertificateKeyPath"

@class CRHTTPServerConfiguration;

@interface CRHTTPServer : CRServer

@property (nonatomic) BOOL isSecure;

@property (nonatomic, strong, nullable) NSString *identityPath;
@property (nonatomic, strong, nullable) NSString *password;
@property (nonatomic, strong, nullable) NSString *certificatePath;
@property (nonatomic, strong, nullable) NSString *certificateKeyPath;

@end
