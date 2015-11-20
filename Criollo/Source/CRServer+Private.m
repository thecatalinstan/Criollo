//
//  CRServer+Private.m
//  Criollo
//
//  Created by Cătălin Stan on 11/20/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRServer+Private.h"

@implementation CRServer (Private)

- (void)didCloseConnection:(CRConnection*)connection {
    if ( [self.delegate respondsToSelector:@selector(server:didCloseConnection:)]) {
        [self.delegate server:self didCloseConnection:connection];
    }
    dispatch_queue_t isolationQueue = [self valueForKey:@"isolationQueue"];
    dispatch_async(isolationQueue, ^(){
        [self.connections removeObject:connection];
    });
}

@end
