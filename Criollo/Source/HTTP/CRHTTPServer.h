//
//  CRHTTPServer.h
//  Criollo
//
//  Created by Cătălin Stan on 10/25/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//


#import <Criollo/CRServer.h>

@class CRHTTPServerConfiguration;

@interface CRHTTPServer : CRServer

@property (nonatomic) BOOL isSecure;

@property (nonatomic, strong, nullable) NSString *identityPath;
@property (nonatomic, strong, nullable) NSString *password;

#if SEC_OS_OSX_INCLUDES
@property (nonatomic, strong, nullable) NSString *certificatePath;
@property (nonatomic, strong, nullable) NSString *privateKeyPath;
#endif

@end
