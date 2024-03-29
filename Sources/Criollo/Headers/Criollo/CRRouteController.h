//
//  CRRouteController.h
//
//
//  Created by Cătălin Stan on 19/07/16.
//

#import <Criollo/CRRouter.h>
#import <Criollo/CRTypes.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CRRouteController : CRRouter

@property (nonatomic, copy) CRRouteBlock routeBlock;
@property (nonatomic, strong, readonly) NSString *prefix;

- (instancetype)initWithPrefix:(NSString *)prefix NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
