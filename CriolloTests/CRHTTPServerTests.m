//
//  CRHTTPServerTests.m
//  Criollo
//
//  Created by Cătălin Stan on 18/10/2017.
//  Copyright © 2017 Cătălin Stan. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "CRHTTPServer.h"
#import "CRHTTPSHelper.h"

#define InvalidPath         @"/path/that/does/not/exist"
#define JunkPath            [self pathForSampleFile:@"CRHTTPSHelperTests.junk"]

#define PEMCertificatePath  [self pathForSampleFile:@"CRHTTPSHelperTests.pem"]
#define PEMKeyPath          [self pathForSampleFile:@"CRHTTPSHelperTests.key.pem"]
#define PEMBundlePath       [self pathForSampleFile:@"CRHTTPSHelperTests.bundle.pem"]

#define DERCertificatePath  [self pathForSampleFile:@"CRHTTPSHelperTests.der"]
#define DERKeyPath          [self pathForSampleFile:@"CRHTTPSHelperTests.key.der"];

#define PKCS12IdentityPath  [self pathForSampleFile:@"CRHTTPSHelperTests.p12"]
#define PKCS12Password      @"password"

#define CRHTTPServerCreate() CRHTTPServer *server = [CRHTTPServer new]
#define CRHTTPServerDestroy() server = nil
#define CRHTTPServerStart() NSError *error; while(![server startListening:&error portNumber:(2000 + (NSUInteger)arc4random_uniform(3000))] && [error.domain isEqualToString:NSPOSIXErrorDomain] && error.code == EADDRINUSE) { NSLog(@" *** %@", error); error = nil;}
#define CRHTTPServerStop() [server stopListening]

@interface CRHTTPServer ()
@property (nonatomic, strong) NSArray *certificates;
@end

@interface CRHTTPServerTests : XCTestCase

- (NSString *)pathForSampleFile:(NSString *)samplefile;

@end

@implementation CRHTTPServerTests

#pragma mark - Identity

- (NSString *)pathForSampleFile:(NSString *)samplefile {
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    return [bundle.resourcePath stringByAppendingPathComponent:samplefile];
}

- (void)test_isSecure_NoCredentials_failsWithMissingCredentialsError {
    CRHTTPServerCreate();
    server.isSecure = YES;
    
    CRHTTPServerStart();
    
    XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer with no credential files should result in an error.");
    XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
    XCTAssertEqual(error.code, CRHTTPSMissingCredentialsError, @"Setting up a secure CRHTTPServer with no credential files should yield CRHTTPSMissingCredentialsError errors.");
    
    CRHTTPServerStop();
}

- (void)test_isSecure_NoCredentials_yieldsNilCertificatesArray {
    CRHTTPServerCreate();
    server.isSecure = YES;
    
    CRHTTPServerStart();
    
    XCTAssertNil(server.certificates, @"Resulting items array should be nil");
    
    CRHTTPServerStop();
}

- (void)test_isSecure_InvalidIdentityPath_failsWithInvalidIdentityError {
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.identityPath = InvalidPath;
    
    CRHTTPServerStart();
    
    XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer with a non-existent identity file should result in an error.");
    XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
    XCTAssertEqual(error.code, CRHTTPSInvalidIdentityError, @"Non-existent identity files should yield CRHTTPSInvalidIdentityError errors.");
    
    CRHTTPServerStop();
}

- (void)test_isSecure_InvalidIdentityPath_yieldsNilCertificatesArray {
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.identityPath = InvalidPath;
    
    CRHTTPServerStart();
    
    XCTAssertNil(server.certificates, @"Resulting items array should be nil");
    
    CRHTTPServerStop();
}

- (void)test_isSecure_MalformedIdentity_failsWithInvalidIdentityError {
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.identityPath = JunkPath;
    
    CRHTTPServerStart();
    
    XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer with a malformed file should result in an error.");
    XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
    XCTAssertEqual(error.code, CRHTTPSInvalidIdentityError, @"Malformed identity files should yield CRHTTPSInvalidIdentityError errors.");

    CRHTTPServerStop();
}

- (void)test_isSecure_MalformedIdentity_yieldsNilCertificatesArray {
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.identityPath = InvalidPath;
    
    CRHTTPServerStart();
    
    XCTAssertNil(server.certificates, @"Resulting items array should be nil");
    
    CRHTTPServerStop();
}

- (void)test_isSecure_ValidIdentityWrongPassword_failsWithInvalidPasswordError {
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.identityPath = PKCS12IdentityPath;
    server.password = @"wrongpassword";
    
    CRHTTPServerStart();
    
    XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer with an incorrect password should result in an error.");
    XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
    XCTAssertEqual(error.code, CRHTTPSInvalidPasswordError, @"Authentication failures should yield CRHTTPSInvalidPasswordError errors.");

    CRHTTPServerStop();
}

- (void)test_isSecure_ValidIdentityWrongPassword_yieldsNilCertificatesArray {
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.identityPath = PKCS12IdentityPath;
    server.password = @"wrongpassword";
    
    CRHTTPServerStart();

    XCTAssertNil(server.certificates, @"Resulting items array should be nil");
    
    CRHTTPServerStop();
}

- (void)test_isSecure_ValidIdentityAndPassword_succeedsWithNoError {
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.identityPath = PKCS12IdentityPath;
    server.password = PKCS12Password;
    
    CRHTTPServerStart();
    
    XCTAssertNil(error, @"Setting up a secure CRHTTPServer with a properly formatted identity file should not result in an error.");
    
    CRHTTPServerStop();
}

- (void)test_isSecure_ValidIdentityAndPassword_yeldsCorrectCertificatesArray {
    NSUInteger expectedItemsCount = 3; // [identity, cert (intermediate), cert (root)]

    CRHTTPServerCreate();
    server.isSecure = YES;
    server.identityPath = PKCS12IdentityPath;
    server.password = PKCS12Password;
        
    CRHTTPServerStart();
    NSArray *items = server.certificates;
        
    XCTAssertNotNil(items, @"Resulting items array should not be nil");
    XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
    
    XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    XCTAssertTrue(SecCertificateGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[1]), @"The second item in the array should be a SecCertificateRef");
    XCTAssertTrue(SecCertificateGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[2]), @"The third item in the array should be a SecCertificateRef");
    
    CRHTTPServerStop();
}

#pragma mark - Certificates

#if SEC_OS_OSX_INCLUDES

- (void)test_isSecure_InvalidCertificatePath_failsWithInvalidCertificateError {
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.certificatePath = InvalidPath;
    server.privateKeyPath = InvalidPath;
    
    CRHTTPServerStart();
    
    XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer with a non-existent certificate file should result in an error.");
    XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
    XCTAssertEqual(error.code, CRHTTPSInvalidCertificateError, @"Non-existent certificate files should yield CRHTTPSInvalidCertificateError errors.");
    
    CRHTTPServerStop();
}

- (void)test_isSecure_InvalidCertificatePath_yieldsNilCertificatesArray {
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.certificatePath = InvalidPath;
    server.privateKeyPath = InvalidPath;
    
    CRHTTPServerStart();
    
    XCTAssertNil(server.certificates, @"Resulting items array should be nil");
    
    CRHTTPServerStop();
}

- (void)test_isSecure_ValidCertificatePathInvalidPrivateKeyPath_failsWithInvalidPrivateKeyError {
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.certificatePath = JunkPath;
    server.privateKeyPath = InvalidPath;
    
    CRHTTPServerStart();
    
    XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer with a non-existent private key file should result in an error.");
    XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
    XCTAssertEqual(error.code, CRHTTPSInvalidPrivateKeyError, @"Non-existent private key files should yield CRHTTPSInvalidPrivateKeyError errors.");
    
    CRHTTPServerStop();
}

- (void)test_isSecure_ValidCertificatePathInvalidPrivateKeyPath_yieldsNilCertificatesArray {
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.certificatePath = JunkPath;
    server.privateKeyPath = InvalidPath;
    
    CRHTTPServerStart();

    XCTAssertNil(server.certificates, @"Resulting items array should be nil");
    
    CRHTTPServerStop();
}

- (void)test_isSecure_MalformedCertificate_failsWithInvalidCertificateError {
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.certificatePath = JunkPath;
    server.privateKeyPath = JunkPath;
    
    CRHTTPServerStart();
    
    XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer an invalid certificate file should result in an error.");
    XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
    XCTAssertEqual(error.code, CRHTTPSInvalidCertificateError, @"Invalid certificate files should yield CRHTTPSInvalidCertificateError errors.");

    CRHTTPServerStop();
}

- (void)test_isSecure_MalformedCertificate_yieldsNilCertificatesArray {
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.certificatePath = JunkPath;
    server.privateKeyPath = JunkPath;
    
    CRHTTPServerStart();

    XCTAssertNil(server.certificates, @"Resulting items array should be nil");
    
    CRHTTPServerStop();
}

- (void)test_isSecure_ValidCertificateMalformedPrivateKey_failsWithInvalidPrivateKeyError {
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.certificatePath = PEMCertificatePath;
    server.privateKeyPath = JunkPath;
    
    CRHTTPServerStart();
    
    XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer with an invalid key file should result in an error.");
    XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
    XCTAssertEqual(error.code, CRHTTPSInvalidPrivateKeyError, @"Invalid key files should yield CRHTTPSInvalidPrivateKeyError errors.");
    
    CRHTTPServerStop();
}

- (void)test_isSecure_ValidCertificateMalformedPrivateKey_yieldsNilCertificatesArray {
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.certificatePath = PEMCertificatePath;
    server.privateKeyPath = JunkPath;
    
    CRHTTPServerStart();

    XCTAssertNil(server.certificates, @"Resulting items array should be nil");
    
    CRHTTPServerStop();
}

- (void)test_isSecure_ValidPEMCertificateAndPrivateKey_succeedsWithNoError {
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.certificatePath = PEMCertificatePath;
    server.privateKeyPath = PEMKeyPath;
    
    CRHTTPServerStart();
    XCTAssertNil(error, @"Setting up a secure CRHTTPServer with properly formatted certificate and key files should not result in an error.");
}

- (void)test_isSecure_ValidPEMCertificateAndPrivateKey_yeldsCorrectCertificatesArray {
    NSUInteger expectedItemsCount = 1; // [identity]
    
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.certificatePath = PEMCertificatePath;
    server.privateKeyPath = PEMKeyPath;
    
    CRHTTPServerStart();
    NSArray *items = server.certificates;
    
    XCTAssertNotNil(items, @"Resulting items array should not be nil");
    XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
 
    XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
}

- (void)test_isSecure_ValidDERCertificateAndPrivateKey_succeedsWithNoError {
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.certificatePath = DERCertificatePath;
    server.privateKeyPath = DERKeyPath;
    
    CRHTTPServerStart();
    
    XCTAssertNil(error, @"Setting up a secure CRHTTPServer with properly formatted certificate and key files should not result in an error.");
    
    CRHTTPServerStop();
}
 
- (void)test_isSecure_ValidDERCertificateAndPrivateKey_yeldsCorrectCertificatesArray {
    NSUInteger expectedItemsCount = 1; // [identity]

    CRHTTPServerCreate();
    server.isSecure = YES;
    server.certificatePath = DERCertificatePath;
    server.privateKeyPath = DERKeyPath;
    
    CRHTTPServerStart();
    NSArray *items = server.certificates;
        
    XCTAssertNotNil(items, @"Resulting items array should not be nil");
    XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
    
    XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    
    CRHTTPServerStop();
}

- (void)test_isSecure_ValidPEMCertificateAndDERPrivateKey_succeedsWithNoError {
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.certificatePath = PEMCertificatePath;
    server.privateKeyPath = DERKeyPath;

    CRHTTPServerStart();

    XCTAssertNil(error, @"Setting up a secure CRHTTPServer with properly formatted certificate and key files should not result in an error.");

    CRHTTPServerStop();
}

- (void)test_isSecure_ValidPEMCertificateAndDERPrivateKey_yeldsCorrectCertificatesArray {
    NSUInteger expectedItemsCount = 1; // [identity]

    CRHTTPServerCreate();
    server.isSecure = YES;
    server.certificatePath = PEMCertificatePath;
    server.privateKeyPath = DERKeyPath;

    CRHTTPServerStart();
    NSArray *items = server.certificates;

    XCTAssertNotNil(items, @"Resulting items array should not be nil");
    XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);

    XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    
    CRHTTPServerStop();
}

- (void)test_isSecure_ValidDERCertificateAndPEMPrivateKey_succeedsWithNoError {
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.certificatePath = DERCertificatePath;
    server.privateKeyPath = PEMKeyPath;
    
    CRHTTPServerStart();
    
    XCTAssertNil(error, @"Setting up a secure CRHTTPServer with properly formatted certificate and key files should not result in an error.");
    
    CRHTTPServerStop();
}

- (void)test_isSecure_ValidDERCertificateAndPEMPrivateKey_yeldsCorrectCertificatesArray {
    NSUInteger expectedItemsCount = 1; // [identity]

    CRHTTPServerCreate();
    server.isSecure = YES;
    server.certificatePath = DERCertificatePath;
    server.privateKeyPath = PEMKeyPath;
    
    CRHTTPServerStart();
    NSArray *items = server.certificates;
    
    XCTAssertNotNil(items, @"Resulting items array should not be nil");
    XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
    
    XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    
    CRHTTPServerStop();
}

- (void)test_isSecure_ValidPEMFullchainCertificateAndPEMPrivateKey_succeedsWithNoError {
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.certificatePath = PEMBundlePath;
    server.privateKeyPath = PEMKeyPath;
    
    CRHTTPServerStart();
    
    XCTAssertNil(error, @"Setting up a secure CRHTTPServer with properly formatted certificate and key files should not result in an error.");
    
    CRHTTPServerStop();
}

- (void)test_isSecure_ValidPEMFullchainCertificateAndPEMPrivateKey_yeldsCorrectCertificatesArray {
    NSUInteger expectedItemsCount = 3; // [identity, cert (intermediate), cert (root)]
    
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.certificatePath = PEMBundlePath;
    server.privateKeyPath = PEMKeyPath;
    
    CRHTTPServerStart();
    NSArray *items = server.certificates;
    
    XCTAssertNotNil(items, @"Resulting items array should not be nil");
    XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
    
    XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    XCTAssertTrue(SecCertificateGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[1]), @"The second item in the array should be a SecCertificateRef");
    XCTAssertTrue(SecCertificateGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[2]), @"The third item in the array should be a SecCertificateRef");
}

- (void)test_isSecure_ValidPEMFullchainCertificateAndDERPrivateKey_succeedsWithNoError {
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.certificatePath = PEMBundlePath;
    server.privateKeyPath = DERKeyPath;
    
    CRHTTPServerStart();

    XCTAssertNil(error, @"Setting up a secure CRHTTPServer with properly formatted certificate and key files should not result in an error.");
    
    CRHTTPServerStop();
}

- (void)test_isSecure_ValidPEMFullchainCertificateAndDERPrivateKey_yeldsCorrectCertificatesArray {
    NSUInteger expectedItemsCount = 3; // [identity, cert (intermediate), cert (root)]
    
    CRHTTPServerCreate();
    server.isSecure = YES;
    server.certificatePath = PEMBundlePath;
    server.privateKeyPath = DERKeyPath;
    
    CRHTTPServerStart();
    NSArray *items = server.certificates;
    
    XCTAssertNotNil(items, @"Resulting items array should not be nil");
    XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
    
    XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    XCTAssertTrue(SecCertificateGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[1]), @"The second item in the array should be a SecCertificateRef");
    XCTAssertTrue(SecCertificateGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[2]), @"The third item in the array should be a SecCertificateRef");
}

#endif

@end
