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

#define InvalidPath     @"/path/that/does/not/exist"
#define JunkPath        [self pathForSampleFile:@"CRHTTPSHelperTests.junk"]

@interface CRHTTPServer ()

@property (nonatomic, strong) NSArray *certificates;

@end

@interface CRHTTPServerTests : XCTestCase

- (NSString *)pathForSampleFile:(NSString *)samplefile;

@end

@implementation CRHTTPServerTests

- (NSString *)pathForSampleFile:(NSString *)samplefile {
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    return [bundle.resourcePath stringByAppendingPathComponent:samplefile];
}

- (void)testSecureCRHTTPServerWithNoCredentialFiles {
    CRHTTPServer *server = [CRHTTPServer new];
    server.isSecure = YES;
    
    NSError *error;
    [server startListening:&error];
    NSArray *items = server.certificates;
    
    XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer with no credential files should result in an error.");
    XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
    XCTAssertEqual(error.code, CRHTTPSMissingCredentialsError, @"Setting up a secure CRHTTPServer with no credential files should yield CRHTTPSMissingCredentialsError errors.");
    XCTAssertNil(items, @"Resulting items array should be nil");
}

- (void)testSecureCRHTTPServerWithIdentityFile {
    NSString *password = @"password";
    
    // Test invalid file path
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.isSecure = YES;
        server.identityPath = InvalidPath;
        
        NSError *error;
        [server startListening:&error];
        NSArray *items = server.certificates;
        
        XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer with a non-existent identity file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidIdentityError, @"Non-existent identity files should yield CRHTTPSInvalidIdentityError errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }
    
    // Test junk data
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.isSecure = YES;
        server.identityPath = JunkPath;
        
        NSError *error;
        [server startListening:&error];
        NSArray *items = server.certificates;
        
        XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer with a malformed file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidIdentityError, @"Malformed identity files should yield CRHTTPSInvalidIdentityError errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }
    
    // Test valid identity file but incorrect password
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.isSecure = YES;
        server.identityPath = [self pathForSampleFile:@"CRHTTPSHelperTests.p12"];
        server.password = @"wrongpassword";
        
        NSError *error;
        [server startListening:&error];
        NSArray *items = server.certificates;
        
        XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer with an incorrect password should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidPasswordError, @"Authentication failures should yield CRHTTPSInvalidPasswordError errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }
    
    // Test valid identity file and correct password
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.isSecure = YES;
        server.identityPath = [self pathForSampleFile:@"CRHTTPSHelperTests.p12"];
        server.password = password;
        
        NSError *error;
        [server startListening:&error];
        NSArray *items = server.certificates;
        
        NSUInteger expectedItemsCount = 3; // [identity, cert (intermediate), cert (root)]
        
        XCTAssertNil(error, @"Setting up a secure CRHTTPServer with a properly formatted identity file should not result in an error.");
        XCTAssertNotNil(items, @"Resulting items array should not be nil");
        XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
        
        XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
        XCTAssertTrue(SecCertificateGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[1]), @"The second item in the array should be a SecCertificateRef");
        XCTAssertTrue(SecCertificateGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[2]), @"The third item in the array should be a SecCertificateRef");
    }
}

- (void)testSecureCRHTTPServerWithCertificateAndPrivateKeyFiles {
    NSString *PEMCertificatePath = [self pathForSampleFile:@"CRHTTPSHelperTests.pem"];
    NSString *DERCertificatePath = [self pathForSampleFile:@"CRHTTPSHelperTests.der"];
    NSString *PEMKeyPath = [self pathForSampleFile:@"CRHTTPSHelperTests.key.pem"];
    NSString *DERKeyPath = [self pathForSampleFile:@"CRHTTPSHelperTests.key.der"];
    NSString *PEMBundlePath = [self pathForSampleFile:@"CRHTTPSHelperTests.bundle.pem"];
    
    // Test invalid certificate path
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.isSecure = YES;
        server.certificatePath = InvalidPath;
        server.certificateKeyPath = InvalidPath;
        
        NSError *error;
        [server startListening:&error];
        NSArray *items = server.certificates;
        
        XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer with a non-existent certificate file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidCertificateError, @"Non-existent certificate files should yield CRHTTPSInvalidCertificateError errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }
    
    // Test valid certificate path but invalid key path
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.isSecure = YES;
        server.certificatePath = JunkPath;
        server.certificateKeyPath = InvalidPath;
        
        NSError *error;
        [server startListening:&error];
        NSArray *items = server.certificates;
        
        XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer with a non-existent private key file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidPrivateKeyError, @"Non-existent private key files should yield CRHTTPSInvalidPrivateKeyError errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }
    
    // Test junk certificate file
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.isSecure = YES;
        server.certificatePath = JunkPath;
        server.certificateKeyPath = JunkPath;
        
        NSError *error;
        [server startListening:&error];
        NSArray *items = server.certificates;
        
        XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer an invalid certificate file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidCertificateError, @"Invalid certificate files should yield CRHTTPSInvalidCertificateError errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }
    
    // Test valid certificate path but junk key
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.isSecure = YES;
        server.certificatePath = PEMCertificatePath;
        server.certificateKeyPath = JunkPath;
        
        NSError *error;
        [server startListening:&error];
        NSArray *items = server.certificates;
        
        XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer with an invalid key file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidPrivateKeyError, @"Invalid key files should yield CRHTTPSInvalidPrivateKeyError errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }
    
    // Test PEM-encoded certificate and key
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.isSecure = YES;
        server.certificatePath = PEMCertificatePath;
        server.certificateKeyPath = PEMKeyPath;
        
        NSError *error;
        [server startListening:&error];
        NSArray *items = server.certificates;
        
        NSUInteger expectedItemsCount = 1; // [identity]
        
        XCTAssertNil(error, @"Setting up a secure CRHTTPServer with properly formatted certificate and key files should not result in an error.");
        
        XCTAssertNotNil(items, @"Resulting items array should not be nil");
        XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
        
        XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    }
    
    // Test DER-encoded certificate and key
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.isSecure = YES;
        server.certificatePath = DERCertificatePath;
        server.certificateKeyPath = DERKeyPath;
        
        NSError *error;
        [server startListening:&error];
        NSArray *items = server.certificates;
        
        NSUInteger expectedItemsCount = 1; // [identity]
        
        XCTAssertNil(error, @"Setting up a secure CRHTTPServer with properly formatted certificate and key files should not result in an error.");
        
        XCTAssertNotNil(items, @"Resulting items array should not be nil");
        XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
        
        XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    }
    
    // Test PEM-encoded certificate and DER-encoded key
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.isSecure = YES;
        server.certificatePath = PEMCertificatePath;
        server.certificateKeyPath = DERKeyPath;
        
        NSError *error;
        [server startListening:&error];
        NSArray *items = server.certificates;
        
        NSUInteger expectedItemsCount = 1; // [identity]
        
        XCTAssertNil(error, @"Setting up a secure CRHTTPServer with properly formatted certificate and key files should not result in an error.");
        
        XCTAssertNotNil(items, @"Resulting items array should not be nil");
        XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
        
        XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    }
    
    // Test DER-encoded certificate and PEM-encoded key
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.isSecure = YES;
        server.certificatePath = DERCertificatePath;
        server.certificateKeyPath = PEMKeyPath;
        
        NSError *error;
        [server startListening:&error];
        NSArray *items = server.certificates;
        
        NSUInteger expectedItemsCount = 1; // [identity]
        
        XCTAssertNil(error, @"Setting up a secure CRHTTPServer with properly formatted certificate and key files should not result in an error.");
        
        XCTAssertNotNil(items, @"Resulting items array should not be nil");
        XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
        
        XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    }
    
    // Test PEM-encoded chained certificate bundle and key
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.isSecure = YES;
        server.certificatePath = PEMBundlePath;
        server.certificateKeyPath = PEMKeyPath;
        
        NSError *error;
        [server startListening:&error];
        NSArray *items = server.certificates;
        
        
        NSUInteger expectedItemsCount;
#if SEC_OS_OSX_INCLUDES
        expectedItemsCount = 3; // [identity, cert (intermediate), cert (root)]
#else
        expectedItemsCount = 1; // [identity]
#endif
        
        XCTAssertNil(error, @"Setting up a secure CRHTTPServer with properly formatted certificate and key files should not result in an error.");
        
        XCTAssertNotNil(items, @"Resulting items array should not be nil");
        XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
        
        XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
#if SEC_OS_OSX_INCLUDES
        XCTAssertTrue(SecCertificateGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[1]), @"The second item in the array should be a SecCertificateRef");
        XCTAssertTrue(SecCertificateGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[2]), @"The third item in the array should be a SecCertificateRef");
#endif
    }
    
    // Test PEM-encoded chained certificate bundle and DER-encoded key
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.isSecure = YES;
        server.certificatePath = PEMBundlePath;
        server.certificateKeyPath = DERKeyPath;
        
        NSError *error;
        [server startListening:&error];
        NSArray *items = server.certificates;
        
        
        NSUInteger expectedItemsCount;
#if SEC_OS_OSX_INCLUDES
        expectedItemsCount = 3; // [identity, cert (intermediate), cert (root)]
#else
        expectedItemsCount = 1; // [identity]
#endif
        
        XCTAssertNil(error, @"Setting up a secure CRHTTPServer with properly formatted certificate and key files should not result in an error.");
        
        XCTAssertNotNil(items, @"Resulting items array should not be nil");
        XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
        
        XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
#if SEC_OS_OSX_INCLUDES
        XCTAssertTrue(SecCertificateGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[1]), @"The second item in the array should be a SecCertificateRef");
        XCTAssertTrue(SecCertificateGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[2]), @"The third item in the array should be a SecCertificateRef");
#endif
    }
    
}

@end

