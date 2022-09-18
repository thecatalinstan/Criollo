//
//  CRRequestRange.h
//
//
//  Created by Cătălin Stan on 06/03/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CRRequestByteRange : NSObject

@property (nonatomic, readonly, nullable) NSString *firstBytePos;
@property (nonatomic, readonly, nullable) NSString *lastBytePos;

- (BOOL)isSatisfiableForFileSize:(unsigned long long)fileSize dataRange:(NSRange * _Nullable)dataRange;

- (NSString *)contentRangeSpecForFileSize:(unsigned long long)fileSize satisfiable:(BOOL)flag dataRange:(NSRange)dataRange;
- (NSString *)contentLengthSpecForFileSize:(unsigned long long)fileSize satisfiable:(BOOL)flag dataRange:(NSRange)dataRange;

@end

@interface CRRequestRange : NSObject

@property (nonatomic, readonly, strong) NSArray<CRRequestByteRange *> *byteRangeSet;
@property (nonatomic, readonly, strong) NSString *bytesUnit;

+ (instancetype)reuestRangeWithRangesSpecifier:(NSString *)rangesSpecifier;
+ (NSString *)acceptRangesSpec;

- (BOOL)isSatisfiableForFileSize:(unsigned long long)fileSize;

@end

NS_ASSUME_NONNULL_END
