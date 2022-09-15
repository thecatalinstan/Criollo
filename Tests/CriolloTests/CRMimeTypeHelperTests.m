//
//  CRMimeTypeHelperTests.m
//
//
//  Created by Cătălin Stan on 15/07/2017.
//

#import <XCTest/XCTest.h>
#import <Criollo/CRMimeTypeHelper.h>

#define DefaultMimeType                     @"application/octet-stream; charset=binary"
#define TextMimeType                        @"text/plain; charset=utf-8"

@interface CRMimeTypeHelperTests : XCTestCase

@end

@implementation CRMimeTypeHelperTests

- (NSString *)pathForSampleFile:(NSString *)samplefile {
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    return [bundle.resourcePath stringByAppendingPathComponent:samplefile];
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
    
    // The extension should not be known at first
    XCTAssertNil([helper mimeTypeForExtension:extension], @"Extension %@ should not be known.", extension);
    
    // Let's add the extension to the dictionary
    [helper setMimeType:[self dummyMimeTypeForExtension: extension] forExtension:extension];
    
    NSString *expectedMimeType = [self dummyMimeTypeForExtension: extension];
    NSString *mimeType = [helper mimeTypeForExtension:extension];
    
    XCTAssertNotNil(mimeType, @"Extension %@ should be known.", extension);
    XCTAssertTrue([mimeType isEqualToString:expectedMimeType], @"Extension %@ should be %@ not %@.", extension, expectedMimeType, mimeType);
}

- (void)testMimeTypeForFileAtPath {
    CRMimeTypeHelper *helper = [CRMimeTypeHelper new];
    NSString *type, *expectedType;
    NSString *path;
    
    // A conent type should be returned no matter what
    path = [self pathForSampleFile:@"empty.empty"];
    type = [helper mimeTypeForFileAtPath:path];
    XCTAssertNotNil(type, "A mime type should always be returned.");
    
    // Known file types should be recognized even if empty
    path = [self pathForSampleFile:@"sample.html"];
    type = [helper mimeTypeForFileAtPath:path];
    XCTAssertFalse([type isEqualToString:DefaultMimeType], @"Extension %@ should not be %@", @"html", DefaultMimeType);
    
    // Text types should be registered as text/plain; charset=utf-8
    path = [self pathForSampleFile:@"sample.text"];
    expectedType = TextMimeType;
    type = [helper mimeTypeForFileAtPath:path];
    XCTAssertTrue([type isEqualToString:expectedType], @"Text files should return %@ not %@", expectedType, type);
    
    // Unknown/indeterminate content types should be registered as application/octet-stream; charset=binary
    expectedType = DefaultMimeType;
    type = [helper mimeTypeForFileAtPath:[self pathForSampleFile:@"unknown.unknown"]];
    XCTAssertTrue([type isEqualToString:expectedType], @"Unknown files should return %@", expectedType);
}

@end
