//
//  CRRequestRange_Internal.h
//  Criollo
//
//  Created by Cătălin Stan on 06/03/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CRRequestRange.h"

@interface CRRequestByteRange ()

- (nonnull instancetype)initWithByteRangeSpec:(NSString * _Nonnull)byteRangeSpec NS_DESIGNATED_INITIALIZER;

@end

@interface CRRequestRange ()

- (nonnull instancetype)initWithRangesSpecifier:(NSString * _Nonnull)rangesSpecifier NS_DESIGNATED_INITIALIZER;

@end
