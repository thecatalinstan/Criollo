//
//  CRHTTPServer.m
//  Criollo
//
//  Created by Cătălin Stan on 10/25/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRServer_Internal.h"
#import "CRHTTPServer.h"
#import "CRHTTPS.h"
#import "CRHTTPConnection.h"
#import "CRConnection_Internal.h"
#import "CRHTTPServerConfiguration.h"
#import "GCDAsyncSocket.h"
#import "CRApplication.h"

#import <Security/Security.h>

@interface CRHTTPServer () <GCDAsyncSocketDelegate>

@property (nonatomic, strong, nullable) NSArray *certificates;

- (nullable NSArray *)fetchIdentityWithError:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

@implementation CRHTTPServer

- (instancetype)initWithDelegate:(id<CRServerDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    self = [super initWithDelegate:delegate delegateQueue:delegateQueue];
    if ( self != nil ) {
        self.configuration = [[CRHTTPServerConfiguration alloc] init];
    }
    return self;
}

- (CRConnection*)newConnectionWithSocket:(GCDAsyncSocket*)socket {
    CRHTTPConnection* connection = [[CRHTTPConnection alloc] initWithSocket:socket server:self];
    if ( self.isSecure && self.certificates.count > 0 ) {
        NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithCapacity:3];
        settings[(__bridge NSString *)kCFStreamSSLIsServer] = @YES;
        settings[(__bridge NSString *)kCFStreamSSLCertificates] = self.certificates;
        settings[(__bridge NSString *)kCFStreamPropertySocketSecurityLevel] = (__bridge NSString *)(kCFStreamSocketSecurityLevelNegotiatedSSL);
        [connection.socket startTLS:settings];
    }
    return connection;
}

- (BOOL)startListening:(NSError *__autoreleasing  _Nullable *)error portNumber:(NSUInteger)portNumber interface:(NSString *)interface {
    NSError * certificateParsingError;
    self.certificates = [self fetchIdentityWithError:&certificateParsingError];
    
    self.identityPath = nil;
    self.password = nil;
    self.certificatePath = nil;
    self.certificateKeyPath = nil;
    
    if ( self.certificates == nil ) {
        [CRApp logErrorFormat:NSLocalizedString(@"Unable to parse certificates: %@",), certificateParsingError];
        return NO;
    }
    
    return [super startListening:error portNumber:portNumber interface:interface];
}

- (NSArray *)fetchIdentityWithError:(NSError *__autoreleasing  _Nullable *)error {    
    if ( self.identityPath.length > 0 ) {
        return [CRHTTPS parseIdentrityFile:self.identityPath password:self.password withError:error];
    } else if ( self.certificatePath.length > 0 && self.certificateKeyPath.length > 0 ) {
        return [CRHTTPS parseCertificateFile:self.certificatePath certificateKeyFile:self.certificateKeyPath withError:error];
    } else {
        NSDictionary *info = @{
            NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to parse credential strings.",),
            CRHTTPSIdentityPathKey: self.identityPath ? : @"(null)",
            CRHTTPSCertificatePathKey: self.certificatePath ? : @"(null)",
            CRHTTPSCertificateKeyPathKey: self.certificateKeyPath ? : @"(null)"
        };
        *error = [[NSError alloc] initWithDomain:CRHTTPSErrorDomain code:CRHTTPSInvalidCredentialFiles userInfo:info];
        
        return nil;
    }
}


@end
