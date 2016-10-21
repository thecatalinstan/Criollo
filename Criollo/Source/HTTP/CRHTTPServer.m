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
#import "CRApplication.h"

#define CRHTTPServerPEMBeginCertMarker          @"-----BEGIN CERTIFICATE-----"
#define CRHTTPServerPEMEndCertMarker            @"-----END CERTIFICATE-----"

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

        NSLog(@" * %s %@ %@", __PRETTY_FUNCTION__, self.certificates, settings);
        [connection.socket startTLS:settings];
    }
    return connection;
}

- (BOOL)startListening:(NSError *__autoreleasing  _Nullable *)error portNumber:(NSUInteger)portNumber interface:(NSString *)interface {
    _certificates = [self fetchIdentityAndCertificates];
    return [super startListening:error portNumber:portNumber interface:interface];
}

- (NSArray *)fetchIdentityAndCertificates {
    NSMutableArray * certificates = [NSMutableArray array];

    if ( self.certificatePath.length == 0 ) {
        return certificates;
    }

    NSError * pemReadError;
    NSData * pemContents = [NSData dataWithContentsOfFile:self.certificatePath options:NSDataReadingUncached error:&pemReadError];
    if ( pemContents.length == 0 ) {
        [CRApp logErrorFormat:@"Unable to parse pem certificates: %@", pemReadError];
        return certificates;
    }

    NSData *beginMarker = [NSData dataWithBytesNoCopy:CRHTTPServerPEMBeginCertMarker.UTF8String length:CRHTTPServerPEMBeginCertMarker.length freeWhenDone:NO];
    NSData *endMarker = [NSData dataWithBytesNoCopy:CRHTTPServerPEMEndCertMarker.UTF8String length:CRHTTPServerPEMEndCertMarker.length freeWhenDone:NO];

    NSUInteger offset = 0;
    while ( offset < pemContents.length ) {
        // Search for the end marker and extract data before it
        NSRange endMarkerSearchRange = NSMakeRange(offset, pemContents.length - offset);
        NSRange endMarkerRange = [pemContents rangeOfData:endMarker options:0 range:endMarkerSearchRange];

        if ( endMarkerRange.location == NSNotFound ) {
            break;
        }

        // Search for the begin marker and extract data after it
        NSRange beginMarkerSearchRange = NSMakeRange(offset, endMarkerRange.location - offset);
        NSRange beginMarkerRange = [pemContents rangeOfData:beginMarker options:0 range:beginMarkerSearchRange];

        // Extract the certificate data
        NSRange pemDataRange = NSMakeRange(beginMarkerRange.location + beginMarkerRange.length, endMarkerRange.location - beginMarkerRange.location - beginMarkerRange.length);
        NSData *pemData = [NSData dataWithBytesNoCopy:(void *)pemContents.bytes + pemDataRange.location length:pemDataRange.length freeWhenDone:NO];

        // Decode the base64 DER
        SecTransformRef transform = SecDecodeTransformCreate(kSecBase64Encoding, NULL);
        if ( !transform ) {
            break;
        }

        NSData *decodedPemData = nil;
        if (SecTransformSetAttribute(transform, kSecTransformInputAttributeName, (__bridge CFDataRef)pemData, NULL)) {
            decodedPemData = CFBridgingRelease(SecTransformExecute(transform, NULL));
        }

        if ( transform ) {
            CFRelease(transform);
        }

        // Create a certificate ref
        SecCertificateRef certificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)decodedPemData);
        if ( !certificate) {
            break;
        }

        // SecCertificateCreateWithData does not always return NULL radar://problem/16124651
        // Check that the certificate serial number can be retrieved. According to
        // RFC5280, the serial number field is required.
        NSData *serial = CFBridgingRelease(SecCertificateCopySerialNumber(certificate, NULL));
        if ( serial ) {
            [certificates addObject:(__bridge id _Nonnull)(certificate)];
        }
        CFRelease(certificate);  // was retained when added to the certificates array

        offset = endMarkerRange.location + endMarkerRange.length;
    }

    return certificates;
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
