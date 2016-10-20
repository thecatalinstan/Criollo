//
//  CRHTTPServer.m
//  Criollo
//
//  Created by Cătălin Stan on 10/25/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRServer_Internal.h"
#import "CRHTTPServer.h"
#import "CRHTTPConnection.h"
#import "CRConnection_Internal.h"
#import "CRHTTPServerConfiguration.h"
#import "GCDAsyncSocket.h"

@interface CRHTTPServer () <GCDAsyncSocketDelegate>

@property (nonatomic, strong, nullable, readonly) NSArray *certificates;

@end

@implementation CRHTTPServer {
    NSArray * _certificates;
}

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

- (NSArray *)certificates {
    if ( _certificates != nil ) {
        return _certificates;
    }

    _certificates = [NSMutableArray array];

    if ( self.certificatePath.length > 0 ) {
        
    }

    return _certificates;
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socketDidSecure:(GCDAsyncSocket *)sock {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)socket:(GCDAsyncSocket *)sock didReceiveTrust:(SecTrustRef)trust completionHandler:(void (^)(BOOL))completionHandler {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, trust);
    completionHandler(YES);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, err);
}


@end
