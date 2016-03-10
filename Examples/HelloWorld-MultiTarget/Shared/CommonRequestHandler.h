//
//  SharedRequestHandler.h
//  HelloWorld
//
//  Created by Cătălin Stan on 11/9/15.
//
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <CriolloiOS/CriolloiOS.h>
#else
#import <Criollo/Criollo.h>
#endif

@interface CommonRequestHandler : NSObject

@property (nonatomic, readonly) CRRouteBlock identifyBlock;
@property (nonatomic, readonly) CRRouteBlock helloWorldBlock;
@property (nonatomic, readonly) CRRouteBlock jsonHelloWorldBlock;
@property (nonatomic, readonly) CRRouteBlock statusBlock;
@property (nonatomic, readonly) CRRouteBlock redirectBlock;

+ (instancetype)defaultHandler;

@end
