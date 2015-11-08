//
//  RequestInfo.h
//  HelloWorld-Cocoa
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CRRequest;

@interface RequestInfo : NSObject

@property (strong) NSString* localAddress;
@property (assign) NSUInteger localPort;
@property (strong) NSString* remoteAddress;
@property (assign) NSUInteger remotePort;

@property (strong) NSString* method;
@property (strong) NSString* version;
@property (strong) NSString* path;

@property (assign) NSUInteger status;

- (instancetype)initWithRequest:(CRRequest*)request;

@end
