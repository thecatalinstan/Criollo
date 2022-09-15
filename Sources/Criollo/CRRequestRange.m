//
//  CRRequestRange.m
//
//
//  Created by Cătălin Stan on 06/03/16.
//

#import <Criollo/CRRequestRange.h>

#import "CRRequest_Internal.h"
#import "CRRequestRange_Internal.h"

/// Parse a requested byte range
/// @see: https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35.1
NS_INLINE NSRange NSRangeFromCRRequesByteRange(CRRequestByteRange *byteRange, NSUInteger fileSize);

@implementation CRRequestByteRange

- (instancetype)init {
    return [self initWithByteRangeSpec:@""];
}

- (instancetype)initWithByteRangeSpec:(NSString *)byteRangeSpec {
    self = [super init];
    if ( self != nil ) {
        NSArray<NSString *> *byteRangeSpecComponents = [byteRangeSpec componentsSeparatedByString:@"-"];
        if( byteRangeSpecComponents.count == 2 ) {
            _firstBytePos = byteRangeSpecComponents[0];
            _lastBytePos = byteRangeSpecComponents[1];
        }
    }
    return self;
}

- (NSString *)description {
    NSMutableString* description = [super description].mutableCopy;
    [description appendFormat:@" firstBytePos: %@, lastBytePos: %@", _firstBytePos, _lastBytePos];
    return description;
}

- (BOOL)isSatisfiableForFileSize:(unsigned long long)fileSize dataRange:(NSRange *)dataRange {
    NSRange range = NSRangeFromCRRequesByteRange(self, (NSUInteger)fileSize);
    if (dataRange != NULL) {
        *dataRange = range;
    }
    return range.location != NSNotFound && range.length > 0 && range.location + range.length <= fileSize;
}

- (NSString *)contentRangeSpecForFileSize:(unsigned long long)fileSize satisfiable:(BOOL)flag dataRange:(NSRange)dataRange {
    NSString* contentRangeSpec;
    NSString* fileSizeString = fileSize == UINT_MAX ? @"*" : @(fileSize).stringValue;
    if (flag) {
        contentRangeSpec = [NSString stringWithFormat:@"%lu-%lu/%@", (unsigned long)dataRange.location, (unsigned long)(dataRange.location + dataRange.length - 1), fileSizeString];
    } else {
        contentRangeSpec = [NSString stringWithFormat:@"*/%@", fileSizeString];
    }
    return contentRangeSpec;
}

- (NSString *)contentLengthSpecForFileSize:(unsigned long long)fileSize satisfiable:(BOOL)flag dataRange:(NSRange)dataRange {
    NSString* contentLengthSpec;
    if (flag) {
        contentLengthSpec = @(dataRange.length).stringValue;
    } else {
        contentLengthSpec = @(fileSize).stringValue;
    }
    return contentLengthSpec;
}

@end

@implementation CRRequestRange

static NSArray<NSString *> *acceptedRangeUnits;
static NSString *acceptRangesSpec;

+ (void)initialize {
    acceptedRangeUnits = @[@"bytes"];
    acceptRangesSpec = [[CRRequestRange acceptedRangeUnits] componentsJoinedByString:CRRequestHeaderSeparator];
    if ( acceptRangesSpec.length == 0 ) {
        acceptRangesSpec = @"none";
    }
}

+ (NSArray<NSString *> *)acceptedRangeUnits {
    return (NSArray<NSString *> *)acceptedRangeUnits;
}

+ (NSString *)acceptRangesSpec {
    return (NSString *)acceptRangesSpec;
}

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
    [description appendFormat:@" bytesUnit: %@, byteRangeSet: %@", _bytesUnit, _byteRangeSet];
    return description;
}

- (BOOL)isSatisfiableForFileSize:(unsigned long long)fileSize {
    if (![CRRequestRange.acceptedRangeUnits containsObject:self.bytesUnit] || !self.byteRangeSet.firstObject) {
        return NO;
    }
 
    __block BOOL isSatisfiable = YES;
    [self.byteRangeSet enumerateObjectsUsingBlock:^(CRRequestByteRange * _Nonnull byteRange, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![byteRange isSatisfiableForFileSize:fileSize dataRange:NULL]) {
            isSatisfiable = NO;
            *stop = YES;
        }
    }];
    return isSatisfiable;
}

@end

NSRange NSRangeFromCRRequesByteRange(CRRequestByteRange *byteRange, NSUInteger fileSize) {
    NSRange dataRange = NSMakeRange(NSNotFound, 0);
    if ( byteRange.firstBytePos.length > 0 ) {
        // byte-range
        dataRange.location = byteRange.firstBytePos.integerValue;
        if ( byteRange.lastBytePos.length > 0 ) {
            dataRange.length = byteRange.lastBytePos.integerValue - byteRange.firstBytePos.integerValue + 1;
        } else {
            dataRange.length = fileSize - dataRange.location;
        }
    } else {
        // suffix-range
        dataRange.length = byteRange.lastBytePos.integerValue;
        if ( fileSize >= dataRange.length ) {
            dataRange.location = fileSize - dataRange.length;
        }
    }
    return dataRange;
}
