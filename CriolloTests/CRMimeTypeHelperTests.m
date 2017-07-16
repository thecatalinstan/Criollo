//
//  CRMimeTypeHelperTests.m
//  Criollo
//
//  Created by Cătălin Stan on 15/07/2017.
//  Copyright © 2017 Cătălin Stan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CRMimeTypeHelper.h"

#define DefaultMimeType                     @"application/octet-stream; charset=binary"

@interface CRMimeTypeHelperTests : XCTestCase

@property (strong) NSArray<NSString *> *extensions;

@end

@implementation CRMimeTypeHelperTests

- (NSString *)pathForSampleFile:(NSString *)samplefile {
    return [[@(__FILE__).stringByDeletingLastPathComponent stringByAppendingPathComponent:@"Samples/CRMimeTypeHelper"] stringByAppendingPathComponent:samplefile];
}
- (NSString *)dummyMimeTypeForExtension:(NSString *)extension {
    return [NSString stringWithFormat:@"mime-test-type/%@", extension];
}

- (void)testSharedHelper {
    XCTAssertNoThrow([CRMimeTypeHelper sharedHelper], "Instantiating the shared helper should not throw an exception.");
    XCTAssertNotNil([CRMimeTypeHelper sharedHelper], "The shared helper should not be nil.");
    
    XCTAssertEqualObjects([CRMimeTypeHelper sharedHelper], [CRMimeTypeHelper sharedHelper], "The shared helper should point to the same instance.");
}

- (void)testMimeTypeForExtension {
    CRMimeTypeHelper *helper = [CRMimeTypeHelper sharedHelper];
    NSString *extension = @"dummy";
    
    // No extensions should be known at first
    XCTAssertNil([helper mimeTypeForExtension:extension], @"Extension %@ should not be known.", extension);
    
    // Let's add some extensions to the dictionary
    [helper setMimeType:[self dummyMimeTypeForExtension: extension] forExtension:extension];
    
    NSString *expectedMimeType = [self dummyMimeTypeForExtension: extension];
    NSString *mimeType = [helper mimeTypeForExtension:extension];
    
    XCTAssertNotNil(mimeType, @"Extension %@ should be known.", extension);
    XCTAssertTrue([mimeType isEqualToString:expectedMimeType], @"Extension %@ should be %@ not %@.", extension, expectedMimeType, mimeType);
    
}

- (void)testMimeTypeForFileAtPath {
    CRMimeTypeHelper *helper = [CRMimeTypeHelper new];
    NSString *type;
    NSString *expectedType;
    
    // A conent type should be returned no matter what
    type = [helper mimeTypeForFileAtPath:[self pathForSampleFile:@"empty.empty"]];
    XCTAssertNotNil(type, "A mime type should always be returned.");
    
    // Known file types should be recognized even if empty (html, txt, rtf, png, jpg, gif, mov, icns)
    for (NSString *extension in self.extensions) {
        type = [helper mimeTypeForFileAtPath:[@"sample." stringByAppendingPathExtension:extension]];
        XCTAssertFalse([type isEqualToString:DefaultMimeType], @"Extension %@ should not be %@", extension, DefaultMimeType);
    }
    
    // Text types should be registered as text/plain; charset=utf-8 (md)
    
    // Source code types should be registered as text/plain; charset=utf-8 (js, php, c, h, m)
    
    // XML types should be registered as application/xml; charset=utf-8 (samplexml)
    
    // Unknown/indeterminate content types should be registered as application/octet-stream; charset=binary
    expectedType = DefaultMimeType;
    type = [helper mimeTypeForFileAtPath:[self pathForSampleFile:@"unknown.unknown"]];
    XCTAssertTrue([type isEqualToString:expectedType], @"Unknown files should return %@", expectedType);

    // Known file types that conform to the text / source type should have charset=urf-8 ()
    
    // Files masquerading as an already determined mime type should be served as that mime-type. not re-identified
}



- (void)testSharedHelperInstantiationPerformance {
    [self measureBlock:^{
        [CRMimeTypeHelper sharedHelper];
    }];
}

- (void)testMimeTypeForFileAtPathPerformance {
    CRMimeTypeHelper *helper = [CRMimeTypeHelper new];
    NSString *path = [self pathForSampleFile:@"random.random"];
    [self measureBlock:^{
        [helper mimeTypeForFileAtPath:path];
    }];
}

@end
