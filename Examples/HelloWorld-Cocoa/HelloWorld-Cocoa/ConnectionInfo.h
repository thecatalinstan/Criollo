//
//  ConnectionInfo.h
//  HelloWorld-Cocoa
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RequestInfo, CRConnection;

@interface ConnectionInfo : NSObject

@property (strong) NSString* remoteHost;
@property (assign) NSUInteger remotePort;

@property (strong) NSArray<RequestInfo*>* requests;

@property (readonly) NSUInteger requestsCount;
@property (readonly) BOOL hasRequests;

- (instancetype)initWithConnection:(CRConnection*)connection;

@end
