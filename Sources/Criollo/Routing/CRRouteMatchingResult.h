//
//  CRRouteMatchingResult.h
//
//
//  Created by Cătălin Stan on 24/07/16.
//

#import <Criollo/CRTypes.h>
#import <Foundation/Foundation.h>

@class CRRoute;

NS_ASSUME_NONNULL_BEGIN

@interface CRRouteMatchingResult : NSObject

@property (nonatomic, strong, readonly) CRRoute * route;
@property (nonatomic, strong, nullable, readonly) NSArray<NSString *> * matches;

@end

NS_ASSUME_NONNULL_END
