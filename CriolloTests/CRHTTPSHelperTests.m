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
#endif

#define InvalidPath         @"/path/that/does/not/exist"
#define JunkPath            [self pathForSampleFile:@"CRHTTPSHelperTests.junk"]

#define PEMCertificatePath  [self pathForSampleFile:@"CRHTTPSHelperTests.pem"]
#define PEMKeyPath          [self pathForSampleFile:@"CRHTTPSHelperTests.key.pem"]
#define PEMBundlePath       [self pathForSampleFile:@"CRHTTPSHelperTests.bundle.pem"]

#define DERCertificatePath  [self pathForSampleFile:@"CRHTTPSHelperTests.der"]
#define DERKeyPath          [self pathForSampleFile:@"CRHTTPSHelperTests.key.der"]

#define PKCS12IdentityPath  [self pathForSampleFile:@"CRHTTPSHelperTests.p12"]
#define PKCS12Password      @"password"

#define CRHTTPSHelperCreate() CRHTTPSHelper *helper = [CRHTTPSHelper new]

@interface CRHTTPSHelperTests : XCTestCase
- (NSString *)pathForSampleFile:(NSString *)samplefile;
@end

@implementation CRHTTPSHelperTests

- (NSString *)pathForSampleFile:(NSString *)samplefile {
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    return [bundle.resourcePath stringByAppendingPathComponent:samplefile];
}

#if SEC_OS_OSX_INCLUDES
- (void)test_keychain_notNil  {
    XCTAssertNotNil((__bridge id)CRHTTPSHelper.new.keychain, @"Custom keychains should NOT return nil.");
}
#endif

- (void)test_parseIdentityFile_InvalidPath_failsWithInvalidIdentityError {
    NSError *error;
    [CRHTTPSHelper.new parseIdentrityFile:InvalidPath password:PKCS12Password withError:&error];

    XCTAssertNotNil(error, @"Parsing a non-existent identity file should result in an error.");
    XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
    XCTAssertEqual(error.code, CRHTTPSInvalidIdentityError, @"Non-existent identity files should yield CRHTTPSInvalidIdentityError errors.");
}

- (void)test_parseIdentityFile_InvalidPath_yieldsNilCertificatesArray {
    XCTAssertNil([CRHTTPSHelper.new parseIdentrityFile:InvalidPath password:PKCS12Password withError:nil], @"Resulting items array should be nil");
}

- (void)test_parseIdentityFile_MalformedIdentityFile_failsWithInvalidIdentityError {
    NSError *error;
    [CRHTTPSHelper.new parseIdentrityFile:JunkPath password:PKCS12Password withError:&error];
    
    XCTAssertNotNil(error, @"Parsing an invalid identity file should result in an error.");
    XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
    XCTAssertEqual(error.code, CRHTTPSInvalidIdentityError, @"Malformed identity files should yield CRHTTPSInvalidIdentityError errors.");
}

- (void)test_parseIdentityFile_MalformedIdentityFile_yieldsNilCertificatesArray {
    XCTAssertNil([CRHTTPSHelper.new parseIdentrityFile:JunkPath password:PKCS12Password withError:nil], @"Resulting items array should be nil");
}

- (void)test_parseIdentityFile_ValidIdentityFileWrongPassword_failsWithInvalidPasswordError {
    NSError *error;
    [CRHTTPSHelper.new parseIdentrityFile:PKCS12IdentityPath password:@"wrongpassword" withError:&error];
    
    XCTAssertNotNil(error, @"Parsing a valid identity file with an incorrect password should result in an error.");
    XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
    XCTAssertEqual(error.code, CRHTTPSInvalidPasswordError, @"Authentication failures should yield CRHTTPSInvalidIdentityError errors.");
}

- (void)test_parseIdentityFile_ValidIdentityFileWrongPassword_yieldsNilCertificatesArray {
    XCTAssertNil([CRHTTPSHelper.new parseIdentrityFile:PKCS12IdentityPath password:@"wrongpassword" withError:nil], @"Resulting items array should be nil");
}

- (void)test_parseIdentityFile_ValidIdentityFileAndPassword_succeedsWithNoError {
    NSError *error;
    [CRHTTPSHelper.new parseIdentrityFile:PKCS12IdentityPath password:PKCS12Password withError:&error];

    XCTAssertNil(error, @"Parsing a properly formatted identity file should not result in an error.");
}

- (void)test_parseIdentityFile_ValidIdentityFileAndPassword_yieldsCorrectCertificatesArray {
    NSUInteger expectedItemsCount = 3; // [identity, cert (intermediate), cert (root)]

    NSArray *items = [CRHTTPSHelper.new parseIdentrityFile:PKCS12IdentityPath password:PKCS12Password withError:nil];
    
    XCTAssertNotNil(items, @"Resulting items array should not be nil");
    XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
    
    XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
    XCTAssertTrue(SecCertificateGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[1]), @"The second item in the array should be a SecCertificateRef");
    XCTAssertTrue(SecCertificateGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[2]), @"The third item in the array should be a SecCertificateRef");
}

- (void)test_parseCertificateFilePrivateKeyFile_InvalidCertificatePath_failsWithInvalidCertificateError {
        NSError *error;
    [CRHTTPSHelper.new parseCertificateFile:InvalidPath certificateKeyFile:InvalidPath withError:&error];

    XCTAssertNotNil(error, @"Parsing a non-existent certificate file should result in an error.");
    XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
    XCTAssertEqual(error.code, CRHTTPSInvalidCertificateError, @"Non-existent certificate files should yield CRHTTPSInvalidCertificateError errors.");
}

- (void)test_parseCertificateFilePrivateKeyFile_InvalidCertificatePath_yieldsNilCertificatesArray {
    XCTAssertNil([CRHTTPSHelper.new parseCertificateFile:InvalidPath certificateKeyFile:InvalidPath withError:nil], @"Resulting items array should be nil");
}

- (void)test_parseCertificateFilePrivateKeyFile_ValidCertificatePathInvalidKeyPath_failsWithInvalidPrivateKeyError {
    NSError *error;
    [CRHTTPSHelper.new parseCertificateFile:JunkPath certificateKeyFile:InvalidPath withError:&error];

    XCTAssertNotNil(error, @"Parsing a non-existent private key file should result in an error.");
    XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
    XCTAssertEqual(error.code, CRHTTPSInvalidPrivateKeyError, @"Non-existent private key files should yield CRHTTPSInvalidPrivateKeyError errors.");
}

- (void)test_parseCertificateFilePrivateKeyFile_ValidCertificatePathInvalidKeyPath_yieldsNilCertificatesArray {
    XCTAssertNil([CRHTTPSHelper.new parseCertificateFile:JunkPath certificateKeyFile:InvalidPath withError:nil], @"Resulting items array should be nil");
}

- (void)test_parseCertificateFilePrivateKeyFile_MalformedCertificate_failsWithInvalidCertificateError {
    NSError *error;
    [CRHTTPSHelper.new parseCertificateFile:JunkPath certificateKeyFile:JunkPath withError:&error];

    XCTAssertNotNil(error, @"Parsing an invalid certificate file should result in an error.");
    XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
    XCTAssertEqual(error.code, CRHTTPSInvalidCertificateError, @"Invalid certificate files should yield CRHTTPSInvalidCertificateError errors.");
}

- (void)test_parseCertificateFilePrivateKeyFile_MalformedCertificate_yieldsNilCertificatesArray {
    XCTAssertNil([CRHTTPSHelper.new parseCertificateFile:JunkPath certificateKeyFile:JunkPath withError:nil], @"Resulting items array should be nil");
}

- (void)test_parseCertificateFilePrivateKeyFile_ValidCertificateMalformedPrivateKey_failsWithInvalidPrivateKeyError {
    NSError *error;
    [CRHTTPSHelper.new parseCertificateFile:PEMCertificatePath certificateKeyFile:JunkPath withError:&error];

    XCTAssertNotNil(error, @"Parsing an invalid key file should result in an error.");
    XCTAssertEqualObjects(error.domain, CRHTTPSErrorDomain, @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
    XCTAssertEqual(error.code, CRHTTPSInvalidPrivateKeyError, @"Invalid key files should yield CRHTTPSInvalidPrivateKeyError errors.");
}

- (void)test_parseCertificateFilePrivateKeyFile_ValidCertificateMalformedPrivateKey_yieldsNilCertificatesArray {
    XCTAssertNil([CRHTTPSHelper.new parseCertificateFile:PEMCertificatePath certificateKeyFile:JunkPath withError:nil], @"Resulting items array should be nil");
}

- (void)test_parseCertificateFilePrivateKeyFile_ValidPEMCertificateAndPrivateKey_succeedsWithNoError {
    NSError *error;
    [CRHTTPSHelper.new parseCertificateFile:PEMCertificatePath certificateKeyFile:PEMKeyPath withError:&error];
    
    XCTAssertNil(error, @"Parsing properly formatted certificate and key files should not result in an error.");
}

- (void)test_parseCertificateFilePrivateKeyFile_ValidPEMCertificateAndPrivateKey_yieldsCorrectCertificatesArray {
    NSUInteger expectedItemsCount = 1; // [identity]

    NSArray *items = [CRHTTPSHelper.new parseCertificateFile:PEMCertificatePath certificateKeyFile:PEMKeyPath withError:nil];
    
    XCTAssertNotNil(items, @"Resulting items array should not be nil");
    XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
    
    XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
}

- (void)test_parseCertificateFilePrivateKeyFile_ValidDERCertificateAndPrivateKey_succeedsWithNoError {
    NSError *error;
    [CRHTTPSHelper.new parseCertificateFile:DERCertificatePath certificateKeyFile:DERKeyPath withError:&error];
    
    XCTAssertNil(error, @"Parsing properly formatted certificate and key files should not result in an error.");
}

- (void)test_parseCertificateFilePrivateKeyFile_ValidDERCertificateAndPrivateKey_yieldsCorrectCertificatesArray {
    NSUInteger expectedItemsCount = 1; // [identity]

    NSArray *items = [CRHTTPSHelper.new parseCertificateFile:DERCertificatePath certificateKeyFile:DERKeyPath withError:nil];
    
    XCTAssertNotNil(items, @"Resulting items array should not be nil");
    XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
    
    XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
}

- (void)test_parseCertificateFilePrivateKeyFile_ValidPEMCertificateAndDERPrivateKey_succeedsWithNoError {
    NSError *error;
    [CRHTTPSHelper.new parseCertificateFile:PEMCertificatePath certificateKeyFile:DERKeyPath withError:&error];
    
    XCTAssertNil(error, @"Parsing properly formatted certificate and key files should not result in an error.");
}

- (void)test_parseCertificateFilePrivateKeyFile_ValidPEMCertificateAndDERPrivateKey_yieldsCorrectCertificatesArray {
    NSUInteger expectedItemsCount = 1; // [identity]

    NSArray *items = [CRHTTPSHelper.new parseCertificateFile:PEMCertificatePath certificateKeyFile:DERKeyPath withError:nil];
    
    XCTAssertNotNil(items, @"Resulting items array should not be nil");
    XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
    
    XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
}

- (void)test_parseCertificateFilePrivateKeyFile_ValidDERCertificateAndPEMPrivateKey_succeedsWithNoError {
    NSError *error;
    [CRHTTPSHelper.new parseCertificateFile:DERCertificatePath certificateKeyFile:PEMKeyPath withError:&error];
    
    XCTAssertNil(error, @"Parsing properly formatted certificate and key files should not result in an error.");
}

- (void)test_parseCertificateFilePrivateKeyFile_ValidDERCertificateAndPEMPrivateKey_yieldsCorrectCertificatesArray {
    NSUInteger expectedItemsCount = 1; // [identity]

    NSArray *items = [CRHTTPSHelper.new parseCertificateFile:DERCertificatePath certificateKeyFile:PEMKeyPath withError:nil];
    
    XCTAssertNotNil(items, @"Resulting items array should not be nil");
    XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
    
    XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
}

- (void)test_parseCertificateFilePrivateKeyFile_ValidPEMFullchainCertificateAndPrivateKey_succeedsWithNoError {
    NSError *error;
    [CRHTTPSHelper.new parseCertificateFile:PEMBundlePath certificateKeyFile:PEMKeyPath withError:&error];
    
    XCTAssertNil(error, @"Parsing properly formatted certificate and key files should not result in an error.");
}

- (void)test_parseCertificateFilePrivateKeyFile_ValidPEMFullchainCertificateAndPrivateKey_yieldsCorrectCertificatesArray {
#if SEC_OS_OSX_INCLUDES
    NSUInteger expectedItemsCount = 3; // [identity, cert (intermediate), cert (root)]
#else
    NSUInteger expectedItemsCount = 1; // [identity]
#endif
    
    NSArray *items = [CRHTTPSHelper.new parseCertificateFile:PEMBundlePath certificateKeyFile:PEMKeyPath withError:nil];
    
    XCTAssertNotNil(items, @"Resulting items array should not be nil");
    XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
    
    XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
#if SEC_OS_OSX_INCLUDES
    XCTAssertTrue(SecCertificateGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[1]), @"The second item in the array should be a SecCertificateRef");
    XCTAssertTrue(SecCertificateGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[2]), @"The third item in the array should be a SecCertificateRef");
#endif
}

- (void)test_parseCertificateFilePrivateKeyFile_ValidPEMFullchainCertificateAndDERPrivateKey_succeedsWithNoError {
    NSError *error;
    [CRHTTPSHelper.new parseCertificateFile:PEMBundlePath certificateKeyFile:DERKeyPath withError:&error];
    
    XCTAssertNil(error, @"Parsing properly formatted certificate and key files should not result in an error.");
}

- (void)test_parseCertificateFilePrivateKeyFile_ValidPEMFullchainCertificateAndDERPrivateKey_yieldsCorrectCertificatesArray {
#if SEC_OS_OSX_INCLUDES
    NSUInteger expectedItemsCount = 3; // [identity, cert (intermediate), cert (root)]
#else
    NSUInteger expectedItemsCount = 1; // [identity]
#endif
    
    NSArray *items = [CRHTTPSHelper.new parseCertificateFile:PEMBundlePath certificateKeyFile:DERKeyPath withError:nil];
    
    XCTAssertNotNil(items, @"Resulting items array should not be nil");
    XCTAssertEqual(items.count, expectedItemsCount, @"Resulting items array should have exactly %lu elements.", expectedItemsCount);
    
    XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[0]), @"The first item in the array should be a SecIdentityRef");
#if SEC_OS_OSX_INCLUDES
    XCTAssertTrue(SecCertificateGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[1]), @"The second item in the array should be a SecCertificateRef");
    XCTAssertTrue(SecCertificateGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items[2]), @"The third item in the array should be a SecCertificateRef");
#endif
}

@end
