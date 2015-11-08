//
//  AppDelegate.m
//  HelloWorld-Cocoa
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Catalin Stan. All rights reserved.
//

#import <Criollo/Criollo.h>
#import "AppDelegate.h"

#define PortNumber 10782

@interface AppDelegate () <CRServerDelegate>

@property (weak) IBOutlet NSWindow *window;
//@property (weak) IBOutlet NSText

- (void)logString:(NSString*)string;
- (void)logFormat:(NSString *)format, ...;
- (void)logErrorFormat:(NSString *)format, ...;

@end

@implementation AppDelegate

- (void)logErrorFormat:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    [self logString:formattedString];
}

- (void)logFormat:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    [self logString:formattedString];
}

- (void)logString:(NSString *)string {
    NSLog(@"%@", string);
}


#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.server = [[CRHTTPServer alloc] initWithDelegate:self];
    NSError* serverError;
    if ( ! [self.server startListeningOnPortNumber:PortNumber error:&serverError] ) {
        [self logErrorFormat:@"Failed to start HTTP server. %@", serverError.localizedDescription];
    } else {
        [self logFormat:@"Started HTTP server at http://%@:%lu/", self.server.configuration.CRServerInterface.length == 0 ? @"127.0.0.1" : self.server.configuration.CRServerInterface, self.server.configuration.CRServerPort];
    }

    // A simple hello world block
    CRRouteHandlerBlock helloBlock = ^(CRRequest* request, CRResponse* response, void(^completionHandler)()) {
        [response setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        [response sendFormat:@"Hello World"];

        completionHandler();
    };

    // A block that prints more info
    CRRouteHandlerBlock statusBlock = ^(CRRequest *request, CRResponse *response, void (^completionHandler)()) {
        NSDate* startTime = [NSDate date];

        NSMutableString* responseString = [[NSMutableString alloc] init];
        [responseString appendFormat:@"<h1>Status</h1>"];
        [responseString appendFormat:@"<h2>Request:</h2><pre>%@</pre>", request.allHTTPHeaderFields];
        [responseString appendFormat:@"<h2>Environment:</h2><pre>%@</pre>", request.env];
        [responseString appendString:@"<hr/>"];
        [responseString appendFormat:@"<small>Task took: %.4fms</small>", [startTime timeIntervalSinceNow] * -1000];

        [response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        [response setValue:@(responseString.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [response sendString:responseString];

        completionHandler();
    };

    [self.server addHandlerBlock:helloBlock];
    [self.server addHandlerBlock:statusBlock forPath:@"/status" HTTPMethod:@"GET"];

    if ( serverError != nil ) {
        [CRApp logErrorFormat:@"%@", @"Neither the FCGI nor the HTTP server could be started. Exiting."];
        [NSApp terminate:nil];
    }

}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    if ( self.server.connections.count > 0 ) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self.server closeAllConnections];
        });
        return NSTerminateLater;
    } else {
        return NSTerminateNow;
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self.server stopListening];
}



@end
