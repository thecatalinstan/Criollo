//
//  CRHTTPServerTests.m
//  Criollo
//
//  Created by Cătălin Stan on 18/10/2017.
//  Copyright © 2017 Cătălin Stan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CRHTTPServer.h"
#import "CRHTTPS.h"

#define InvalidPath     @"/path/that/does/not/exist"
#define JunkPath        [self pathForSampleFile:@"CRHTTPSTests.junk"]

@interface CRHTTPServer ()

- (nullable NSArray *)fetchIdentityWithError:(NSError * _Nullable __autoreleasing * _Nullable)error;

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
    
    NSError *error = nil;
    NSArray *items = [server fetchIdentityWithError:&error];
    
    XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer with no credential files should result in an error.");
    XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
    XCTAssertEqual(error.code, CRHTTPSInvalidCredentialFiles, @"Setting up a secure CRHTTPServer with no credential files should yield CRHTTPSInvalidCredentialFiles errors.");
    XCTAssertNil(items, @"Resulting items array should be nil");
}

- (void)testSecureCRHTTPServerWithIdentityFile {
    NSString *password = @"password";
    
    // Test invalid file path
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.identityPath = InvalidPath;
        
        NSError *error = nil;
        NSArray *items = [server fetchIdentityWithError:&error];

        XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer with a non-existent identity file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidIdentityFile, @"Non-existent identity files should yield CRHTTPSInvalidIdentityFile errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }
    
    // Test junk data
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.identityPath = JunkPath;
        
        NSError *error = nil;
        NSArray *items = [server fetchIdentityWithError:&error];
        
        XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer with a malformed file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidIdentityFile, @"Malformed identity files should yield CRHTTPSInvalidIdentityFile errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }

    // Test valid identity file but incorrect password
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.identityPath = [self pathForSampleFile:@"CRHTTPSTests.p12"];
        server.password = @"wrongpassword";
        
        NSError *error = nil;
        NSArray *items = [server fetchIdentityWithError:&error];
        
        XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer with an incorrect password should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidIdentityPassword, @"Authentication failures should yield CRHTTPSInvalidIdentityPassword errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }

    // Test valid identity file and correct password
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.identityPath = [self pathForSampleFile:@"CRHTTPSTests.p12"];
        server.password = password;
        
        NSError *error = nil;
        NSArray *items = [server fetchIdentityWithError:&error];
        
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
    NSString *PEMCertificatePath = [self pathForSampleFile:@"CRHTTPSTests.pem"];
    NSString *DERCertificatePath = [self pathForSampleFile:@"CRHTTPSTests.der"];
    NSString *PEMKeyPath = [self pathForSampleFile:@"CRHTTPSTests.key.pem"];
    NSString *DERKeyPath = [self pathForSampleFile:@"CRHTTPSTests.key.der"];
    NSString *PEMBundlePath = [self pathForSampleFile:@"CRHTTPSTests.bundle.pem"];

    // Test invalid certificate path
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.certificatePath = InvalidPath;
        server.certificateKeyPath = InvalidPath;
        
        NSError *error = nil;
        NSArray *items = [server fetchIdentityWithError:&error];

        XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer with a non-existent certificate file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidCertificateBundle, @"Non-existent certificate files should yield CRHTTPSInvalidCertificateBundle errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }

    // Test valid certificate path but invalid key path
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.certificatePath = JunkPath;
        server.certificateKeyPath = InvalidPath;
        
        NSError *error = nil;
        NSArray *items = [server fetchIdentityWithError:&error];

        XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer with a non-existent private key file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidCertificatePrivateKey, @"Non-existent private key files should yield CRHTTPSInvalidCertificatePrivateKey errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }

    // Test junk certificate file
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.certificatePath = JunkPath;
        server.certificateKeyPath = JunkPath;
        
        NSError *error = nil;
        NSArray *items = [server fetchIdentityWithError:&error];
        
        XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer an invalid certificate file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidCertificateBundle, @"Invalid certificate files should yield CRHTTPSInvalidCertificateBundle errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }

    // Test valid certificate path but junk key
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.certificatePath = PEMCertificatePath;
        server.certificateKeyPath = JunkPath;
        
        NSError *error = nil;
        NSArray *items = [server fetchIdentityWithError:&error];

        XCTAssertNotNil(error, @"Setting up a secure CRHTTPServer with an invalid key file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"Secure CRHTTPServer errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidCertificatePrivateKey, @"Invalid key files should yield CRHTTPSInvalidCertificatePrivateKey errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }

    // Test PEM-encoded certificate and key
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.certificatePath = PEMCertificatePath;
        server.certificateKeyPath = PEMKeyPath;
        
        NSError *error = nil;
        NSArray *items = [server fetchIdentityWithError:&error];
        
        NSUInteger expectedItemsCount = 1; // [identity]

        XCTAssertNil(error, @"Setting up a secure CRHTTPServer with properly formatted certificate and key files should not result in an error.");
        
        XCTAssertNotNil(items, @"Resulting items array should not be nil");
        XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);

        XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    }

    // Test DER-encoded certificate and key
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.certificatePath = DERCertificatePath;
        server.certificateKeyPath = DERKeyPath;
        
        NSError *error = nil;
        NSArray *items = [server fetchIdentityWithError:&error];
        
        NSUInteger expectedItemsCount = 1; // [identity]

        XCTAssertNil(error, @"Setting up a secure CRHTTPServer with properly formatted certificate and key files should not result in an error.");

        XCTAssertNotNil(items, @"Resulting items array should not be nil");
        XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);

        XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    }

    // Test PEM-encoded certificate and DER-encoded key
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.certificatePath = PEMCertificatePath;
        server.certificateKeyPath = DERKeyPath;
        
        NSError *error = nil;
        NSArray *items = [server fetchIdentityWithError:&error];
        
        NSUInteger expectedItemsCount = 1; // [identity]
        
        XCTAssertNil(error, @"Setting up a secure CRHTTPServer with properly formatted certificate and key files should not result in an error.");
        
        XCTAssertNotNil(items, @"Resulting items array should not be nil");
        XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
        
        XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    }

    // Test DER-encoded certificate and PEM-encoded key
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.certificatePath = DERCertificatePath;
        server.certificateKeyPath = PEMKeyPath;
        
        NSError *error = nil;
        NSArray *items = [server fetchIdentityWithError:&error];
        
        NSUInteger expectedItemsCount = 1; // [identity]
        
        XCTAssertNil(error, @"Setting up a secure CRHTTPServer with properly formatted certificate and key files should not result in an error.");
        
        XCTAssertNotNil(items, @"Resulting items array should not be nil");
        XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
        
        XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    }

    // Test PEM-encoded chained certificate bundle and key
    {
        CRHTTPServer *server = [CRHTTPServer new];
        server.certificatePath = PEMBundlePath;
        server.certificateKeyPath = PEMKeyPath;
        
        NSError *error = nil;
        NSArray *items = [server fetchIdentityWithError:&error];
        

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
        server.certificatePath = PEMBundlePath;
        server.certificateKeyPath = DERKeyPath;
        
        NSError *error = nil;
        NSArray *items = [server fetchIdentityWithError:&error];
        
        
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
