//
//  CRRouteMatchingResult.h
//
//
//  Created by Cătălin Stan on 24/07/16.
//

#import <Foundation/Foundation.h>

@class CRRoute;

NS_ASSUME_NONNULL_BEGIN

@interface CRRouteMatchingResult : NSObject

@property (nonatomic, readonly) CRRoute *route;
@property (nonatomic, nullable, readonly) NSArray<NSString *> *matches;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
