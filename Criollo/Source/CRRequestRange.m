//
//  CRRequestRange.m
//  Criollo
//
//  Created by Cătălin Stan on 06/03/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CRRequestRange.h"
#import "CRRequestRange_Internal.h"
#import "CRRequest_Internal.h"

@implementation CRRequestByteRange

- (instancetype)init {
    return [self initWithByteRangeSpec:@""];
}

- (instancetype)initWithByteRangeSpec:(NSString *)byteRangeSpec {
    self = [super init];
    if ( self != nil ) {
        NSArray<NSString *>* byteRangeSpecComponents = [byteRangeSpec componentsSeparatedByString:@"-"];
        if( byteRangeSpecComponents.count == 2 ) {
            if (byteRangeSpecComponents[0].length > 0) {
                _firstBytePos = byteRangeSpecComponents[0];
            }
            if (byteRangeSpecComponents[1].length > 0) {
                _lastBytePos = byteRangeSpecComponents[1];
            }
        }
    }
    return self;
}

@end


@implementation CRRequestRange

+ (instancetype)reuestRangeWithRangesSpecifier:(NSString *)rangesSpecifier {
    CRRequestRange* requestRange = [[CRRequestRange alloc] initWithRangesSpecifier:rangesSpecifier];
    return requestRange;
}

- (instancetype)init {
    return [self initWithRangesSpecifier:@""];
}

- (instancetype)initWithRangesSpecifier:(NSString *)rangesSpecifier {
    self = [super init];
    if ( self != nil ) {
        if ( rangesSpecifier.length > 0 ) {
            NSString* byteRangesSpecifier = [rangesSpecifier componentsSeparatedByString:CRRequestHeaderSeparator][0];
            NSArray* byteRangesSpecifierComponents = [byteRangesSpecifier componentsSeparatedByString:@"="];
            if ( byteRangesSpecifierComponents.count == 2 ) {
                _bytesUnit = byteRangesSpecifierComponents[0];
                NSString* byteRangeSetSepecifier = byteRangesSpecifierComponents[1];
                if ( byteRangeSetSepecifier.length > 0 ) {
                    NSArray<NSString *>* byteRangeSpecs = [byteRangeSetSepecifier componentsSeparatedByString:CRRequestHeaderArraySeparator];
                    NSMutableArray<CRRequestByteRange *> *byteRangeSet = [NSMutableArray arrayWithCapacity:byteRangeSpecs.count];
                    [byteRangeSpecs enumerateObjectsUsingBlock:^(NSString * _Nonnull byteRangeSpec, NSUInteger idx, BOOL * _Nonnull stop) {
                        CRRequestByteRange *byteRange = [[CRRequestByteRange alloc] initWithByteRangeSpec:byteRangeSpec];
                        [byteRangeSet addObject:byteRange];
                    }];
                    _byteRangeSet = byteRangeSet;
                }
            }
        }
    }
    return self;
}

- (NSString *)description {
    NSMutableString* description = [super description].mutableCopy;
    
    return description;
}

@end
