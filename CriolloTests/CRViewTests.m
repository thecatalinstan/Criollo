//
//  CRViewTests.m
//  Criollo
//
//  Created by Cătălin Stan on 06/08/2017.
//  Copyright © 2017 Cătălin Stan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CRView.h"
#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

@interface CRViewTests : XCTestCase

@end

@implementation CRViewTests

- (CRView *)testView:(NSString *)name {
    NSBundle *bundle = [NSBundle bundleForClass:[CRViewTests class]];
    XCTAssertNotNil(bundle, "The bundle for the test case should not be nil.");
    
    NSString* path = [bundle pathForResource:NSStringFromClass(self.class) ofType:@"html"];
    XCTAssertNotNil(path, "Path of test file CRViewTests.html should not be nil.");
    
    NSError *fileReadError;
    NSData *contents = [NSData dataWithContentsOfFile:path options:NSDataReadingUncached error:&fileReadError];
    XCTAssertNotNil(contents, "Contents of file %@ should not be nil.", path);
    XCTAssertNotEqual(contents.length, 0, "Contents of file %@ should not be empty.", path);
    XCTAssertNil(fileReadError, "Encountered %@ code %lu: %@, while reading %@", fileReadError.domain, fileReadError.code, fileReadError.localizedDescription, path);
    
    NSString *contentsString = [[NSString alloc] initWithBytesNoCopy:(void *)contents.bytes length:contents.length encoding:NSUTF8StringEncoding freeWhenDone:NO];
    XCTAssertNotNil(contentsString, "No-copy converted string should be non-nil.");
    XCTAssertEqual(contentsString.length, contents.length, "Length of the data (%lu) should be eqaul to the converted string (%lu). (%lu != %lu)", contents.length, contentsString.length, contents.length, contentsString.length);
    
    CRView *view = [[CRView alloc] initWithContents:contentsString];
    XCTAssertNotNil(view, "View object created with valid contents should not be nil");
    XCTAssertEqual(view.contents.hash, contentsString.hash, "View content string object should not be copied ( %lu != %lu).", (unsigned long)view.contents.hash, (unsigned long)contentsString.hash);
    XCTAssertTrue([view.contents isEqualToString:contentsString], "Contents of view created with valid contents should be the same as the initial string.");
    
    return view;
}

- (void)testView {
    [self testView:NSStringFromClass(self.class)];
}

- (void)testEmptyView {
    CRView *emptyView = [[CRView alloc] initWithContents:nil];
    XCTAssertNotNil(emptyView, "View object created with nil contents should not be nil");
    XCTAssertNotNil(emptyView.contents, "Contents of view object created with nil contents should not be nil");
    XCTAssertTrue([emptyView.contents isEqualToString:@""], "Contents of view created with nil contents should be an empty string");
}

- (void)testRender {
    CRView *view = [self testView:NSStringFromClass(self.class)];
    
    NSString *nonReplaced = [view render:nil];
    XCTAssertNotNil(nonReplaced, "Rendering should produce a non nil result.");
    XCTAssertTrue([view.contents isEqualToString:nonReplaced], "Rendering with an empty replacement should return the original string.");
    
    NSDictionary *variables = @{@"title": NSStringFromClass(self.class)};
    NSString *replaced = [view render:variables];
    XCTAssertEqual([replaced rangeOfString:@"{{title}}"].location, NSNotFound, "Rendered string should not contain '{{title}}'.");
    XCTAssertNotEqual([replaced rangeOfString:NSStringFromClass(self.class)].location, NSNotFound, "Rendered string should contain '%@'.", NSStringFromClass(self.class));
    XCTAssertNotEqual([replaced rangeOfString:@"{{var}}"].location, NSNotFound, "Rendered string should contain '{{var}}', the unhandled placeholder.");
}

- (void)testInvalidData {
    CRView *view = [self testView:NSStringFromClass(self.class)];
    
    NSMutableArray *invalidData = [NSMutableArray array];
    [invalidData addObject:@YES];
    [invalidData addObject:@(M_PI)];
    [invalidData addObject:[NSData dataWithBytesNoCopy:(void *)view.contents.UTF8String length:view.contents.length freeWhenDone:NO]];
    [invalidData addObject:[NSNull new]];
    [invalidData addObject:[NSBundle bundleForClass:self.class]];
#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR
    [invalidData addObject:[UIBezierPath bezierPathWithRect:CGRectZero]];
#else
    [invalidData addObject:[NSBezierPath bezierPathWithRect:NSZeroRect]];
#endif
    
    NSMutableDictionary *variables = [NSMutableDictionary dictionary];
    variables[@"title"] = NSStringFromClass(self.class);
    
    [invalidData enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        variables[@"var"] = obj;
        NSString *rendered = [view render:variables];
        
        XCTAssertEqual([rendered rangeOfString:@"{{title}}"].location, NSNotFound, "Rendered string should not contain '{{title}}'.");
        XCTAssertNotEqual([rendered rangeOfString:NSStringFromClass(self.class)].location, NSNotFound, "Rendered string should contain '%@'.", NSStringFromClass(self.class));
        
        XCTAssertEqual([rendered rangeOfString:@"{{var}}"].location, NSNotFound, "Rendered string should contain '{{var}}', the unhandled placeholder.");
        XCTAssertNotEqual([rendered rangeOfString:[obj description]].location, NSNotFound, "Rendered string should contain '%@'.", [obj description]);
    }];
    
}

@end
