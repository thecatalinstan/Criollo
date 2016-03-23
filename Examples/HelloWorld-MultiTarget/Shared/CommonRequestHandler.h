//
//  SharedRequestHandler.h
//  HelloWorld
//
//  Created by Cătălin Stan on 11/9/15.
//
//

#import <Foundation/Foundation.h>
#import <Criollo/Criollo.h>

@interface CommonRequestHandler : NSObject

@property (nonatomic, readonly) CRRouteBlock identifyBlock;
@property (nonatomic, readonly) CRRouteBlock helloWorldBlock;
@property (nonatomic, readonly) CRRouteBlock jsonHelloWorldBlock;
@property (nonatomic, readonly) CRRouteBlock statusBlock;
@property (nonatomic, readonly) CRRouteBlock redirectBlock;

+ (instancetype)defaultHandler;

@end
