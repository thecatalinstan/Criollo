//
//  CRHTTPServer.h
//
//
//  Created by Cătălin Stan on 10/25/15.
//

#import <Criollo/CRServer.h>
#import <Foundation/Foundation.h>
#import <Security/SecBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface CRHTTPServer : CRServer

@property (nonatomic) BOOL isSecure;

@property (nonatomic, nullable) NSString *identityPath;
@property (nonatomic, nullable) NSString *password;

#if SEC_OS_OSX_INCLUDES
@property (nonatomic, nullable) NSString *certificatePath;
@property (nonatomic, nullable) NSString *privateKeyPath;
#endif

@end

NS_ASSUME_NONNULL_END
