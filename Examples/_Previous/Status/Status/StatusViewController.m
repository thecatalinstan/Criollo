//
//  StatusViewController.m
//  Status
//
//  Created by Cătălin Stan on 12/04/15.
//  Copyright (c) 2015 Catalin Stan. All rights reserved.
//
#import <FCGIKit/FCGIKit.h>

#import "StatusViewController.h"

@implementation StatusViewController

- (void)viewDidLoad
{
    [self.response setValue:( @"text/html; charset=utf-8" ) forHTTPHeaderField:@"Content-type"];
}

- (NSString *)presentViewController:(BOOL)writeData
{
    NSMutableString* output = [NSMutableString stringWithString:@"<h1>FCGIKit Status App</h1>"];
    [output appendString:@"<pre>"];
    [output appendFormat:@"Current Requests:  \t%@\n", @([FKApp currentRequests].count)];
    [output appendFormat:@"Connected Sockets: \t%@", @([FKApp connectedSockets].count)];
    [output appendString:@"</pre>"];
    
    [output appendString:@"<pre>"];
    [output appendFormat:@"Thread: %@\n", [NSThread currentThread]];
    [output appendFormat:@"Queue: %s", dispatch_queue_get_label(self.request.FCGIRequest.socket.delegateQueue)];
    [output appendString:@"</pre>"];
    
    if ( writeData ) {
        [self.response writeString:output.copy];
        
        if ( self.automaticallyFinishesResponse ) {
            [self.response finish];
        }
    }
    return output;
}

- (BOOL)automaticallyFinishesResponse
{
    return YES;
}

@end
