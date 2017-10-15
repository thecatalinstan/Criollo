//
//  CRHTTPSTests.m
//  Criollo
//
//  Created by Cătălin Stan on 11/09/2017.
//  Copyright © 2017 Cătălin Stan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CRHTTPS.h"

@interface CRHTTPSTests : XCTestCase

@property (nonatomic, strong, nullable) NSString *password;

@property (nonatomic, strong, nullable) NSString *basePath;

@property (nonatomic, strong, nullable) NSString *bogusPath;
@property (nonatomic, strong, nullable) NSString *identityPath;
@property (nonatomic, strong, nullable) NSString *chainedIdentityPath;
@property (nonatomic, strong, nullable) NSString *chainedCertificatePath;
@property (nonatomic, strong, nullable) NSString *certificatePath;
@property (nonatomic, strong, nullable) NSString *certificateKeyPath;


@end

@implementation CRHTTPSTests

- (void)setUp {
    [super setUp];
    
    // Setup a bassword
    self.password = NSUUID.UUID.UUIDString;

    self.basePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSStringFromClass(self.class) stringByAppendingString:NSUUID.UUID.UUIDString]];
    [NSFileManager.defaultManager createDirectoryAtPath:self.basePath withIntermediateDirectories:YES attributes:nil error:nil];
#if SEC_OS_OSX
    [NSWorkspace.sharedWorkspace openFile:self.basePath];
#endif
    
    // Create some bogus data file
    self.bogusPath = [self.basePath stringByAppendingPathComponent:@"junk"];
    
    // Create self signed certificate root
//    self.bogusPath =
    
    // Create self signed cert-key pair
    
    // Create chained bundle
    
    // Create identity
}

- (void)tearDown {
    
    // Delete all created files
    if ( self.bogusPath.length > 0 )
        [NSFileManager.defaultManager removeItemAtPath:self.bogusPath error:nil];
    if ( self.identityPath.length > 0 )
        [NSFileManager.defaultManager removeItemAtPath:self.identityPath error:nil];
    if ( self.chainedIdentityPath.length > 0 )
        [NSFileManager.defaultManager removeItemAtPath:self.chainedIdentityPath error:nil];
    if ( self.chainedCertificatePath.length > 0 )
        [NSFileManager.defaultManager removeItemAtPath:self.chainedCertificatePath error:nil];
    if ( self.certificatePath.length > 0 )
        [NSFileManager.defaultManager removeItemAtPath:self.certificatePath error:nil];
    if ( self.certificateKeyPath.length > 0 )
        [NSFileManager.defaultManager removeItemAtPath:self.certificateKeyPath error:nil];
    if ( self.basePath.length > 0 )
        [NSFileManager.defaultManager removeItemAtPath:self.basePath error:nil];
    
    [super tearDown];
}

- (void)testPrivateKeychainCreation  {
}

- (void)testIdentityImport {
    // Test invalid file path
    {
        NSError *error = nil;
        NSArray *items = [CRHTTPS parseIdentrityFile:@"/path/that/does/not/exist" password:self.password withError:&error];
        
        XCTAssertNotNil(error, @"Parsing a non-existent identity file should result in an error.");
        XCTAssertTrue([error.domain isEqualToString:CRHTTPSErrorDomain], @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidIdentityFile, @"Non-existent identity files should yield CRHTTPSInvalidIdentityFile errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }
    
    // Test bogus data
    {
        NSError *error = nil;
        NSArray *items = [CRHTTPS parseIdentrityFile:self.bogusPath password:self.password withError:&error];
        
        XCTAssertNotNil(error, @"Parsing an invalid identity file should result in an error.");
        XCTAssertTrue([error.domain isEqualToString:CRHTTPSErrorDomain], @"CRHTTPS errors should have the domain CRHTTPSErrorDomain.");
        XCTAssertEqual(error.code, CRHTTPSInvalidIdentityFile, @"Malformed identity files should yield CRHTTPSInvalidIdentityFile errors.");
        XCTAssertNil(items, @"Resulting items array should be nil");
    }
    
    // Test identity
    {
        NSError *error = nil;
        NSArray *items = [CRHTTPS parseIdentrityFile:self.identityPath password:self.password withError:&error];
        
        XCTAssertNil(error, @"Parsing a properly formatted identity file should not result in an error.");
        XCTAssertNil(items, @"Resulting items array should not be nil");
        XCTAssertGreaterThan(0, items.count, @"Resulting items array should have at least one element.");
        XCTAssertTrue(SecIdentityGetTypeID() == CFGetTypeID((__bridge CFTypeRef)items.firstObject), @"The first should be a SecIdentityRef");
    }
    
}

- (void)testCertificateKeyImport {
    
}

@end
