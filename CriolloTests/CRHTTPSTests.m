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
