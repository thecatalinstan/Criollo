//
//  CLRoute.h
//  Criollo
//
//  Created by Cătălin Stan on 5/18/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

/**

The CLRoute Object
 
 */
@interface CLRoute : NSObject<NSCoding> {
    NSString* _requestPath;
    Class _controllerClass;
    NSString* _nibName;
    NSDictionary* _userInfo;
}

@property (nonatomic, retain) NSString* requestPath;
@property (atomic, assign) Class controllerClass;
@property (nonatomic, retain) NSString* nibName;
@property (nonatomic, retain) NSDictionary* userInfo;

- (instancetype)initWithRequestPath:(NSString *)requestPath controllerClass:(Class)controllerClass nibName:(NSString*)nibName userInfo:(NSDictionary *)userInfo;
- (instancetype)initWithInfoDictionary:(NSDictionary*)infoDictionary;

@property (nonatomic, readonly, copy) NSDictionary *infoDictionary;

@end
