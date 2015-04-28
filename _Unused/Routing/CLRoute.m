//
//  CLRoute.m
//  Criollo
//
//  Created by Cătălin Stan on 5/18/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "CLRoute.h"
#import "CLViewController.h"
#import "Criollo.h"

@implementation CLRoute

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
        _controllerClass = controllerClass == nil ? [CLViewController class] : controllerClass;
        _nibName = nibName;
        _userInfo = userInfo;
    }
    return self;
}

- (instancetype)initWithInfoDictionary:(NSDictionary *)infoDictionary
{
    NSString* requestPath = infoDictionary[CLRoutePathKey];
    Class controllerClass = NSClassFromString(infoDictionary[CLRouteControllerKey]);
    NSString* nibName = infoDictionary[CLRouteNibNameKey];
    NSDictionary* userInfo = infoDictionary[CLRouteUserInfoKey];
    return [self initWithRequestPath:requestPath controllerClass:controllerClass nibName:nibName userInfo:userInfo];
}

- (NSDictionary *)infoDictionary
{
	NSDictionary* infoDictionary = @{ CLRoutePathKey: self.requestPath,
									  CLRouteControllerKey: NSStringFromClass(self.controllerClass),
									  CLRouteNibNameKey: self.nibName,
									  CLRouteUserInfoKey: self.userInfo
									 };
	return infoDictionary;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (Controller: %@, Path: %@, NibName: %@)", super.description, self.controllerClass, self.requestPath, self.nibName];
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.requestPath forKey:CLRoutePathKey];
    [encoder encodeObject:self.controllerClass forKey:CLRouteControllerKey];
	[encoder encodeObject:self.nibName forKey:CLRouteNibNameKey];
	[encoder encodeObject:self.userInfo forKey:CLRouteUserInfoKey];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [self init];
    if( self != nil ) {
		self.requestPath = [decoder decodeObjectForKey:CLRoutePathKey];
		self.controllerClass = [decoder decodeObjectForKey:CLRouteControllerKey];
		self.nibName = [decoder decodeObjectForKey:CLRouteNibNameKey];
		self.userInfo = [decoder decodeObjectForKey:CLRouteUserInfoKey];
		
    }
    return self;
}

@end