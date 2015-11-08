//
//  RequestInfo.m
//  HelloWorld-Cocoa
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Catalin Stan. All rights reserved.
//

#import <Criollo/Criollo.h>
#import "RequestInfo.h"

@implementation RequestInfo

- (instancetype)initWithRequest:(CRRequest*)request {
    self = [self init];
    if ( self != nil ) {
        @synchronized(request) {
            self.remoteAddress = request.response.connection.remoteAddress.copy;
            self.remotePort = request.response.connection.remotePort;
            self.localAddress = request.response.connection.localAddress.copy;
            self.localPort = request.response.connection.localPort;
            self.method = request.method.copy;
            self.version = request.version.copy;
            self.path = request.URL.path.copy;
            self.status = request.response.statusCode;
        }
    }
    return self;
}

@end
