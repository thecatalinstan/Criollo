//
//  CRRequestRange_Internal.h
//
//
//  Created by Cătălin Stan on 06/03/16.
//

#import <Criollo/CRRequestRange.h>

NS_ASSUME_NONNULL_BEGIN

@interface CRRequestByteRange ()

- (instancetype)initWithByteRangeSpec:(NSString *)byteRangeSpec NS_DESIGNATED_INITIALIZER;

@end

@interface CRRequestRange ()

+ (NSArray<NSString *> *)acceptedRangeUnits;

- (instancetype)initWithRangesSpecifier:(NSString *)rangesSpecifier NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
