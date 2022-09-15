//
//  CRNibTests.m
//
//
//  Created by Cătălin Stan on 06/08/2017.
//

#import <XCTest/XCTest.h>
#import <Criollo/CRNib.h>

@interface CRNibTests : XCTestCase

@end

@implementation CRNibTests

- (void)testNibCreation {
    NSBundle *bundle = [NSBundle bundleForClass:[CRNibTests class]];
    XCTAssertNotNil(bundle, "The bundle for the test case should not be nil.");
    
    CRNib *emptyNib = [[CRNib alloc] initWithNibNamed:@"invalid" bundle:bundle];
    XCTAssertNotNil(emptyNib, "We should be able to create a CRNib object, even if the path is invalid.");
    XCTAssertNotNil(emptyNib.data, "Nib data should never be nil.");
    XCTAssertEqual(emptyNib.data.length, 0, "Nib data created from invalid files should be zero-length.");
    
    NSString *nibFilePath = [bundle pathForResource:NSStringFromClass(self.class) ofType:@"html"];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:nibFilePath], "The nib file %@ should exist.", nibFilePath.lastPathComponent);

    NSError *nibReadError;
    NSData *nibData = [NSData dataWithContentsOfFile:nibFilePath options:NSDataReadingUncached error:&nibReadError];
    XCTAssertNil(nibReadError, "We should be able to read the nib file.");
    XCTAssertTrue(nibData.length > 0, "Data read manually from the file should be non-zero length.");
    
    CRNib *nib = [[CRNib alloc] initWithNibNamed:NSStringFromClass(self.class) bundle:bundle];
    XCTAssertTrue(nib.data.length > 0, "Data read by [CRNib init] from the file should be non-zero length.");
    XCTAssertTrue([nib.data isEqualToData:nibData], "Data read manually should be the same as the data read by [CRNib init].");
}

@end
