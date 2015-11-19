//
//  SharedRequestHandler.h
//  HelloWorld
//
//  Created by Cătălin Stan on 11/9/15.
//
//

#import <Foundation/Foundation.h>

@class CRRequest, CRResponse;

@interface CommonRequestHandler : NSObject

@property (nonatomic, readonly) void(^helloWorldBlock)(CRRequest*, CRResponse*, void(^)());
@property (nonatomic, readonly) void(^jsonHelloWorldBlock)(CRRequest*, CRResponse*, void(^)());
@property (nonatomic, readonly) void(^statusBlock)(CRRequest*, CRResponse*, void(^)());

+ (instancetype)defaultHandler;

@end
