//
//  CRHTTPSHelperTests.m
//  Criollo
//
//  Created by Cătălin Stan on 11/09/2017.
//  Copyright © 2017 Cătălin Stan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CRHTTPSHelper.h"

#if SEC_OS_OSX_INCLUDES

@interface CRHTTPSHelper ()

@property (nonatomic) SecKeychainRef keychain;

@end

#else

typedef CFTypeRef SecKeychainRef;

#endif

#define InvalidPath     @"/path/that/does/not/exist"
#define JunkPath        [self pathForSampleFile:@"CRHTTPSHelperTests.junk"]

@interface CRHTTPSHelperTests : XCTestCase

- (NSString *)pathForSampleFile:(NSString *)samplefile;

@end

@implementation CRHTTPSHelperTests

- (NSString *)pathForSampleFile:(NSString *)samplefile {
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    return [bundle.resourcePath stringByAppendingPathComponent:samplefile];
}

#if SEC_OS_OSX_INCLUDES
- (void)testSetupKeychain  {
    CRHTTPSHelper *httpsHelper = [CRHTTPSHelper new];
    SecKeychainRef keychain = httpsHelper.keychain;
    XCTAssertNotNil((__bridge id)keychain, @"Custom keychains should NOT return nil.");
}
#endif

- (void)testParseIdentityFile {
    NSString *password = @"password";
    
    // Test invalid file path
    {
        CRHTTPSHelper *httpsHelper = [CRHTTPSHelper new];
        
        NSString *path = InvalidPath;
        NSError *error = nil;
        NSArray *items = [httpsHelper parseIdentrityFile:path password:password withError:&error];

        XCTAssertNotNil(error, @"Parsing a non-existent identity file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidIdentityError, @"Non-existent identity files should yield CRHTTPSInvalidIdentityError errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }

    // Test junk data
    {
        CRHTTPSHelper *httpsHelper = [CRHTTPSHelper new];

        NSString *path = JunkPath;
        NSError *error = nil;
        NSArray *items = [httpsHelper parseIdentrityFile:path password:password withError:&error];

        XCTAssertNotNil(error, @"Parsing an invalid identity file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidIdentityError, @"Malformed identity files should yield CRHTTPSInvalidIdentityError errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }
    
    // Test valid identity file but incorrect password
    {
        CRHTTPSHelper *httpsHelper = [CRHTTPSHelper new];

        NSString *path = [self pathForSampleFile:@"CRHTTPSHelperTests.p12"];
        NSError *error = nil;
        NSArray *items = [httpsHelper parseIdentrityFile:path password:@"wrongpassword" withError:&error];
        
        XCTAssertNotNil(error, @"Parsing a valid identity file with an incorrect password should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidPasswordError, @"Authentication failures should yield CRHTTPSInvalidIdentityError errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }
    
    // Test valid identity file and correct password
    {
        CRHTTPSHelper *httpsHelper = [CRHTTPSHelper new];

        NSString *path = [self pathForSampleFile:@"CRHTTPSHelperTests.p12"];
        NSError *error = nil;
        NSArray *items = [httpsHelper parseIdentrityFile:path password:password withError:&error];
        
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
    NSString *PEMCertificatePath = [self pathForSampleFile:@"CRHTTPSHelperTests.pem"];
    NSString *DERCertificatePath = [self pathForSampleFile:@"CRHTTPSHelperTests.der"];
    NSString *PEMKeyPath = [self pathForSampleFile:@"CRHTTPSHelperTests.key.pem"];
    NSString *DERKeyPath = [self pathForSampleFile:@"CRHTTPSHelperTests.key.der"];
    NSString *PEMBundlePath = [self pathForSampleFile:@"CRHTTPSHelperTests.bundle.pem"];
    
    // Test invalid certificate path
    {
        CRHTTPSHelper *httpsHelper = [CRHTTPSHelper new];

        NSString *certificate = InvalidPath;
        NSString *key = InvalidPath;
        NSError *error = nil;
        NSArray *items = [httpsHelper parseCertificateFile:certificate certificateKeyFile:key withError:&error];

        XCTAssertNotNil(error, @"Parsing a non-existent certificate file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidCertificateError, @"Non-existent certificate files should yield CRHTTPSInvalidCertificateError errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }

    // Test valid certificate path but invalid key path
    {
        CRHTTPSHelper *httpsHelper = [CRHTTPSHelper new];

        NSString *certificate = JunkPath;
        NSString *key = InvalidPath;
        NSError *error = nil;
        NSArray *items = [httpsHelper parseCertificateFile:certificate certificateKeyFile:key withError:&error];

        XCTAssertNotNil(error, @"Parsing a non-existent private key file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidPrivateKeyError, @"Non-existent private key files should yield CRHTTPSInvalidPrivateKeyError errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }

    // Test junk certificate file
    {
        CRHTTPSHelper *httpsHelper = [CRHTTPSHelper new];

        NSString *certificate = JunkPath;
        NSString *key = JunkPath;
        NSError *error = nil;
        NSArray *items = [httpsHelper parseCertificateFile:certificate certificateKeyFile:key withError:&error];

        XCTAssertNotNil(error, @"Parsing an invalid certificate file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidCertificateError, @"Invalid certificate files should yield CRHTTPSInvalidCertificateError errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }

    // Test valid certificate path but junk key
    {
        CRHTTPSHelper *httpsHelper = [CRHTTPSHelper new];

        NSString *certificate = PEMCertificatePath;
        NSString *key = JunkPath;
        NSError *error = nil;
        NSArray *items = [httpsHelper parseCertificateFile:certificate certificateKeyFile:key withError:&error];

        XCTAssertNotNil(error, @"Parsing an invalid key file should result in an error.");
        XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidPrivateKeyError, @"Invalid key files should yield CRHTTPSInvalidPrivateKeyError errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }

    // Test PEM-encoded certificate and key
    {
        CRHTTPSHelper *httpsHelper = [CRHTTPSHelper new];

        NSString *certificate = PEMCertificatePath;
        NSString *key = PEMKeyPath;
        NSError *error = nil;
        NSArray *items = [httpsHelper parseCertificateFile:certificate certificateKeyFile:key withError:&error];
        
        NSUInteger expectedItemsCount = 1; // [identity]
        
        XCTAssertNil(error, @"Parsing properly formatted certificate and key files should not result in an error.");
        
        XCTAssertNotNil(items, @"Resulting items array should not be nil");
        XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
        
        XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    }
    
    // Test DER-encoded certificate and key
    {
        CRHTTPSHelper *httpsHelper = [CRHTTPSHelper new];

        NSString *certificate = DERCertificatePath;
        NSString *key = DERKeyPath;
        NSError *error = nil;
        NSArray *items = [httpsHelper parseCertificateFile:certificate certificateKeyFile:key withError:&error];
        
        NSUInteger expectedItemsCount = 1; // [identity]
        
        XCTAssertNil(error, @"Parsing properly formatted certificate and key files should not result in an error.");
        
        XCTAssertNotNil(items, @"Resulting items array should not be nil");
        XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
        
        XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    }
    
    // Test PEM-encoded certificate and DER-encoded key
    {
        CRHTTPSHelper *httpsHelper = [CRHTTPSHelper new];

        NSString *certificate = PEMCertificatePath;
        NSString *key = DERKeyPath;
        NSError *error = nil;
        NSArray *items = [httpsHelper parseCertificateFile:certificate certificateKeyFile:key withError:&error];
        
        NSUInteger expectedItemsCount = 1; // [identity]
        
        XCTAssertNil(error, @"Parsing properly formatted certificate and key files should not result in an error.");
        
        XCTAssertNotNil(items, @"Resulting items array should not be nil");
        XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
        
        XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    }
    
    // Test DER-encoded certificate and PEM-encoded key
    {
        CRHTTPSHelper *httpsHelper = [CRHTTPSHelper new];

        NSString *certificate = DERCertificatePath;
        NSString *key = PEMKeyPath;
        NSError *error = nil;
        NSArray *items = [httpsHelper parseCertificateFile:certificate certificateKeyFile:key withError:&error];
        
        NSUInteger expectedItemsCount = 1; // [identity]
        
        XCTAssertNil(error, @"Parsing properly formatted certificate and key files should not result in an error.");
        
        XCTAssertNotNil(items, @"Resulting items array should not be nil");
        XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
        
        XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    }

    // Test PEM-encoded chained certificate bundle and key
    {
        CRHTTPSHelper *httpsHelper = [CRHTTPSHelper new];

        NSString *certificate = PEMBundlePath;
        NSString *key = PEMKeyPath;
        NSError *error = nil;
        NSArray *items = [httpsHelper parseCertificateFile:certificate certificateKeyFile:key withError:&error];

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
        CRHTTPSHelper *httpsHelper = [CRHTTPSHelper new];

        NSString *certificate = PEMBundlePath;
        NSString *key = DERKeyPath;
        NSError *error = nil;
        NSArray *items = [httpsHelper parseCertificateFile:certificate certificateKeyFile:key withError:&error];
        
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
