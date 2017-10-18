//
//  CRHTTPSTests.m
//  Criollo
//
//  Created by Cătălin Stan on 11/09/2017.
//  Copyright © 2017 Cătălin Stan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CRHTTPS.h"

#if !SEC_OS_OSX_INCLUDES
typedef CFTypeRef SecKeychainRef;
#endif

#define InvalidPath     @"/path/that/does/not/exist"
#define JunkPath        [self pathForSampleFile:@"CRHTTPSTests.junk"]

@interface CRHTTPS()

+ (SecKeychainRef _Nullable)getKeychainWithError:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

@interface CRHTTPSTests : XCTestCase

- (NSString *)pathForSampleFile:(NSString *)samplefile;

@end

@implementation CRHTTPSTests

- (NSString *)pathForSampleFile:(NSString *)samplefile {
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    return [bundle.resourcePath stringByAppendingPathComponent:samplefile];
}

- (void)testGetKeychain  {
    NSError *error = nil;
    SecKeychainRef keychain = [CRHTTPS getKeychainWithError:&error];
    XCTAssertNil(error, @"No errors should be returned.");
#if SEC_OS_OSX_INCLUDES
    XCTAssertNotNil((__bridge id)keychain, @"Custom keychains should NOT return nil on OSX.");
    
    OSStatus status = SecKeychainDelete(keychain);
    XCTAssertNotEqual(errSecInvalidKeychain, status, @"Deleting custom keychains should not attept to delete the user default keychain.");
    XCTAssertEqual(errSecSuccess, status, @"Deleting custom keychains should succeed.");
    
    CFRelease(keychain);
#else
    XCTAssertNil((__bridge id)keychain, @"Custom keychains should return nil on non OSX platforms.");
#endif
}

- (void)testParseIdentityFile {
    NSString *password = @"password";
    
    // Test invalid file path
    {
        NSString *path = InvalidPath;
        NSError *error = nil;
        NSArray *items = [CRHTTPS parseIdentrityFile:path password:password withError:&error];

        XCTAssertNotNil(error, @"Parsing a non-existent identity file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidIdentityError, @"Non-existent identity files should yield CRHTTPSInvalidIdentityError errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }

    // Test junk data
    {
        NSString *path = JunkPath;
        NSError *error = nil;
        NSArray *items = [CRHTTPS parseIdentrityFile:path password:password withError:&error];

        XCTAssertNotNil(error, @"Parsing an invalid identity file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidIdentityError, @"Malformed identity files should yield CRHTTPSInvalidIdentityError errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }
    
    // Test valid identity file but incorrect password
    {
        NSString *path = [self pathForSampleFile:@"CRHTTPSTests.p12"];
        NSError *error = nil;
        NSArray *items = [CRHTTPS parseIdentrityFile:path password:@"wrongpassword" withError:&error];
        
        XCTAssertNotNil(error, @"Parsing a valid identity file with an incorrect password should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidPasswordError, @"Authentication failures should yield CRHTTPSInvalidIdentityError errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }
    
    // Test valid identity file and correct password
    {
        NSString *path = [self pathForSampleFile:@"CRHTTPSTests.p12"];
        NSError *error = nil;
        NSArray *items = [CRHTTPS parseIdentrityFile:path password:password withError:&error];
        
        NSUInteger expectedItemsCount = 3; // [identity, cert (intermediate), cert (root)]

        XCTAssertNil(error, @"Parsing a properly formatted identity file should not result in an error.");
     
        XCTAssertNotNil(items, @"Resulting items array should not be nil");
        XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
        
        XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
        XCTAssertTrue(SecCertificateGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[1]), @"The second item in the array should be a SecCertificateRef");
        XCTAssertTrue(SecCertificateGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[2]), @"The third item in the array should be a SecCertificateRef");
    }
}

- (void)testParseCertificateAndPrivateKeyFiles {
    NSString *PEMCertificatePath = [self pathForSampleFile:@"CRHTTPSTests.pem"];
    NSString *DERCertificatePath = [self pathForSampleFile:@"CRHTTPSTests.der"];
    NSString *PEMKeyPath = [self pathForSampleFile:@"CRHTTPSTests.key.pem"];
    NSString *DERKeyPath = [self pathForSampleFile:@"CRHTTPSTests.key.der"];
    NSString *PEMBundlePath = [self pathForSampleFile:@"CRHTTPSTests.bundle.pem"];
    
    // Test invalid certificate path
    {
        NSString *certificate = InvalidPath;
        NSString *key = InvalidPath;
        NSError *error = nil;
        NSArray *items = [CRHTTPS parseCertificateFile:certificate certificateKeyFile:key withError:&error];

        XCTAssertNotNil(error, @"Parsing a non-existent certificate file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidCertificateError, @"Non-existent certificate files should yield CRHTTPSInvalidCertificateError errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }

    // Test valid certificate path but invalid key path
    {
        NSString *certificate = JunkPath;
        NSString *key = InvalidPath;
        NSError *error = nil;
        NSArray *items = [CRHTTPS parseCertificateFile:certificate certificateKeyFile:key withError:&error];

        XCTAssertNotNil(error, @"Parsing a non-existent private key file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidPrivateKeyError, @"Non-existent private key files should yield CRHTTPSInvalidPrivateKeyError errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }

    // Test junk certificate file
    {
        NSString *certificate = JunkPath;
        NSString *key = JunkPath;
        NSError *error = nil;
        NSArray *items = [CRHTTPS parseCertificateFile:certificate certificateKeyFile:key withError:&error];

        XCTAssertNotNil(error, @"Parsing an invalid certificate file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidCertificateError, @"Invalid certificate files should yield CRHTTPSInvalidCertificateError errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }

    // Test valid certificate path but junk key
    {
        NSString *certificate = PEMCertificatePath;
        NSString *key = JunkPath;
        NSError *error = nil;
        NSArray *items = [CRHTTPS parseCertificateFile:certificate certificateKeyFile:key withError:&error];

        XCTAssertNotNil(error, @"Parsing an invalid key file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidPrivateKeyError, @"Invalid key files should yield CRHTTPSInvalidPrivateKeyError errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }

    // Test PEM-encoded certificate and key
    {
        NSString *certificate = PEMCertificatePath;
        NSString *key = PEMKeyPath;
        NSError *error = nil;
        NSArray *items = [CRHTTPS parseCertificateFile:certificate certificateKeyFile:key withError:&error];
        
        NSUInteger expectedItemsCount = 1; // [identity]
        
        XCTAssertNil(error, @"Parsing properly formatted certificate and key files should not result in an error.");
        
        XCTAssertNotNil(items, @"Resulting items array should not be nil");
        XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
        
        XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    }
    
    // Test DER-encoded certificate and key
    {
        NSString *certificate = DERCertificatePath;
        NSString *key = DERKeyPath;
        NSError *error = nil;
        NSArray *items = [CRHTTPS parseCertificateFile:certificate certificateKeyFile:key withError:&error];
        
        NSUInteger expectedItemsCount = 1; // [identity]
        
        XCTAssertNil(error, @"Parsing properly formatted certificate and key files should not result in an error.");
        
        XCTAssertNotNil(items, @"Resulting items array should not be nil");
        XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
        
        XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    }
    
    // Test PEM-encoded certificate and DER-encoded key
    {
        NSString *certificate = PEMCertificatePath;
        NSString *key = DERKeyPath;
        NSError *error = nil;
        NSArray *items = [CRHTTPS parseCertificateFile:certificate certificateKeyFile:key withError:&error];
        
        NSUInteger expectedItemsCount = 1; // [identity]
        
        XCTAssertNil(error, @"Parsing properly formatted certificate and key files should not result in an error.");
        
        XCTAssertNotNil(items, @"Resulting items array should not be nil");
        XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
        
        XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    }
    
    // Test DER-encoded certificate and PEM-encoded key
    {
        NSString *certificate = DERCertificatePath;
        NSString *key = PEMKeyPath;
        NSError *error = nil;
        NSArray *items = [CRHTTPS parseCertificateFile:certificate certificateKeyFile:key withError:&error];
        
        NSUInteger expectedItemsCount = 1; // [identity]
        
        XCTAssertNil(error, @"Parsing properly formatted certificate and key files should not result in an error.");
        
        XCTAssertNotNil(items, @"Resulting items array should not be nil");
        XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
        
        XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    }

    // Test PEM-encoded chained certificate bundle and key
    {
        NSString *certificate = PEMBundlePath;
        NSString *key = PEMKeyPath;
        NSError *error = nil;
        NSArray *items = [CRHTTPS parseCertificateFile:certificate certificateKeyFile:key withError:&error];

        NSUInteger expectedItemsCount;
#if SEC_OS_OSX_INCLUDES
        expectedItemsCount = 3; // [identity, cert (intermediate), cert (root)]
#else
        expectedItemsCount = 1; // [identity]
#endif

        XCTAssertNil(error, @"Parsing properly formatted certificate and key files should not result in an error.");

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
        NSString *certificate = PEMBundlePath;
        NSString *key = DERKeyPath;
        NSError *error = nil;
        NSArray *items = [CRHTTPS parseCertificateFile:certificate certificateKeyFile:key withError:&error];
        
        NSUInteger expectedItemsCount;
#if SEC_OS_OSX_INCLUDES
        expectedItemsCount = 3; // [identity, cert (intermediate), cert (root)]
#else
        expectedItemsCount = 1; // [identity]
#endif
        
        XCTAssertNil(error, @"Parsing properly formatted certificate and key files should not result in an error.");
        
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
