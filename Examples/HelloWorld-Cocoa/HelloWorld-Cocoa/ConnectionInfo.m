//
//  ConnectionInfo.m
//  HelloWorld-Cocoa
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Catalin Stan. All rights reserved.
//

#import <Criollo/Criollo.h>
#import "ConnectionInfo.h"
#import "RequestInfo.h"

@implementation ConnectionInfo

- (instancetype)initWithConnection:(CRConnection *)connection {
    self = [self init];
    if ( self != nil ) {
        self.remoteHost = connection.remoteAddress.copy;
        self.remotePort = connection.remotePort;

        NSMutableArray* requests = [NSMutableArray arrayWithCapacity:connection.requests.count];
        NSArray* connectionRequests = connection.requests.copy;
        [connectionRequests enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            RequestInfo* requestInfo = [[RequestInfo alloc] initWithRequest:obj];
            [requests addObject:requestInfo];
        }];
        self.requests = requests.copy;
    }
    return self;
}

- (NSArray *)requestsAtIndexes:(NSIndexSet *)indexes {
    return [self.requests objectsAtIndexes:indexes];
}

- (NSUInteger)requestsCount {
    return self.requests.count;
}

- (BOOL)hasRequests {
    return self.requests.count > 0;
}

@end
