//
//  CRRequestRange.h
//  Criollo
//
//  Created by Cătălin Stan on 06/03/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CRRequestByteRange : NSObject

@property (nonatomic, readonly, nullable) NSString *firstBytePos;
@property (nonatomic, readonly, nullable) NSString *lastBytePos;

@end

@interface CRRequestRange : NSObject

@property (nonatomic, readonly, strong, nonnull) NSArray<CRRequestByteRange *> *byteRangeSet;
@property (nonatomic, readonly, strong, nonnull) NSString *bytesUnit;

+ (nonnull instancetype)reuestRangeWithRangesSpecifier:(NSString * _Nonnull)rangesSpecifier;

@end
