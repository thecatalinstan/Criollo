//
//  CRRoute_Internal.h
//
//
//  Created by Cătălin Stan on 24/07/16.
//

#import "CRRoute.h"

NS_ASSUME_NONNULL_BEGIN

@interface CRRoute ()

@property (nonatomic, strong, nullable, readonly) NSRegularExpression * pathRegex;
@property (nonatomic, strong, nullable, readonly) NSArray<NSString *> * pathKeys;
@property (nonatomic, strong, nullable) id associatedObject;

- (NSArray<NSString *> *)processMatchesInPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
