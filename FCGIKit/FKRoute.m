//
//  FCGIKitRoute.m
//  FCGIKit
//
//  Created by Cătălin Stan on 5/18/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "FKRoute.h"
#import "FKViewController.h"
#import "FCGIKit.h"

@implementation FKRoute

@synthesize requestPath = _requestPath;
@synthesize controllerClass = _controllerClass;
@synthesize nibName = _nibName;
@synthesize userInfo = _userInfo;

- (instancetype)initWithRequestPath:(NSString *)requestPath controllerClass:(Class)controllerClass nibName:(NSString*)nibName userInfo:(NSDictionary *)userInfo
{
    if ( requestPath == nil ) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"The request path cannot be nil." userInfo:nil];
        return nil;
    }
    self = [self init];
    if ( self != nil ) {
        _requestPath = requestPath;
        _controllerClass = controllerClass == nil ? [FKViewController class] : controllerClass;
        _nibName = nibName;
        _userInfo = userInfo;
    }
    return self;
}

- (instancetype)initWithInfoDictionary:(NSDictionary *)infoDictionary
{
    NSString* requestPath = infoDictionary[FKRoutePathKey];
    Class controllerClass = NSClassFromString(infoDictionary[FKRouteControllerKey]);
    NSString* nibName = infoDictionary[FKRouteNibNameKey];
    NSDictionary* userInfo = infoDictionary[FKRouteUserInfoKey];
    return [self initWithRequestPath:requestPath controllerClass:controllerClass nibName:nibName userInfo:userInfo];
}

- (NSDictionary *)infoDictionary
{
	NSDictionary* infoDictionary = @{ FKRoutePathKey: self.requestPath,
									  FKRouteControllerKey: NSStringFromClass(self.controllerClass),
									  FKRouteNibNameKey: self.nibName,
									  FKRouteUserInfoKey: self.userInfo
									 };
	return infoDictionary;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (Controller: %@, Path: %@, NibName: %@)", super.description, self.controllerClass, self.requestPath, self.nibName];
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.requestPath forKey:FKRoutePathKey];
    [encoder encodeObject:self.controllerClass forKey:FKRouteControllerKey];
	[encoder encodeObject:self.nibName forKey:FKRouteNibNameKey];
	[encoder encodeObject:self.userInfo forKey:FKRouteUserInfoKey];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [self init];
    if( self != nil ) {
		self.requestPath = [decoder decodeObjectForKey:FKRoutePathKey];
		self.controllerClass = [decoder decodeObjectForKey:FKRouteControllerKey];
		self.nibName = [decoder decodeObjectForKey:FKRouteNibNameKey];
		self.userInfo = [decoder decodeObjectForKey:FKRouteUserInfoKey];
		
    }
    return self;
}

@end