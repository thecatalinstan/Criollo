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
@property (strong) IBOutlet NSTextView *logTextView;

- (void)logString:(NSString*)string error:(BOOL)flag;
- (void)logFormat:(NSString *)format, ...;
- (void)logErrorFormat:(NSString *)format, ...;

- (NSDictionary*)logTextAtributes;
- (NSDictionary*)logErrorAtributes;
- (NSDictionary*)linkTextAttributes;

@end

@implementation AppDelegate

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    // Eye-candy
    self.logTextView.linkTextAttributes = self.linkTextAttributes;

    // Start a server
    self.server = [[CRHTTPServer alloc] initWithDelegate:self];

    // A simple hello world block
    CRRouteHandlerBlock helloBlock = ^(CRRequest* request, CRResponse* response, void(^completionHandler)()) {
        [response setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        [response sendFormat:@"Hello World"];

        completionHandler();
    };
    [self.server addHandlerBlock:helloBlock];

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
    [self.server addHandlerBlock:statusBlock forPath:@"/status" HTTPMethod:@"GET"];

    // Start listening
    NSError* serverError;
    if ( ! [self.server startListeningOnPortNumber:PortNumber error:&serverError] ) {
        [self logErrorFormat:@"Failed to start HTTP server. %@", serverError.localizedDescription];
    } else {
        [self logFormat:@"Started HTTP server at http://%@:%lu/", self.server.configuration.CRServerInterface.length == 0 ? @"127.0.0.1" : self.server.configuration.CRServerInterface, self.server.configuration.CRServerPort];
    }

    if ( serverError != nil ) {
        [self logErrorFormat:@"%@\n%@", @"The HTTP server could be started.", serverError.localizedDescription];
    }

}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Close connections so that we exit cleanly
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
    // Stop listening
    [self.server stopListening];
}

#pragma mark - Logging

- (NSDictionary *)logTextAtributes {
    static NSDictionary* _logTextAttributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableParagraphStyle* style = [[NSMutableParagraphStyle alloc] init];
        style.lineHeightMultiple = 1.1;
        style.lineBreakMode = NSLineBreakByWordWrapping;
        _logTextAttributes = @{
                               NSFontAttributeName: [NSFont systemFontOfSize:12],
                               NSForegroundColorAttributeName: [NSColor darkGrayColor],
                               NSParagraphStyleAttributeName: style,
                               };
    });
    return _logTextAttributes;
}

- (NSDictionary *)logErrorAtributes {
    static NSDictionary* _logTextAttributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableParagraphStyle* style = [[NSMutableParagraphStyle alloc] init];
        style.lineHeightMultiple = 1.1;
        style.lineBreakMode = NSLineBreakByWordWrapping;
        _logTextAttributes = @{
                               NSFontAttributeName: [NSFont systemFontOfSize:12],
                               NSForegroundColorAttributeName: [NSColor redColor],
                               NSParagraphStyleAttributeName: style,
                               };
    });
    return _logTextAttributes;
}

- (NSDictionary*)linkTextAttributes {
    static NSDictionary* _linkTextAttributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _linkTextAttributes = @{
                                NSForegroundColorAttributeName: [NSColor blueColor],
                                NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                                };
    });
    return _linkTextAttributes;
}

- (void)logErrorFormat:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    [self logString:formattedString error:NO];
}

- (void)logFormat:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    [self logString:formattedString error:NO];
}

- (void)logString:(NSString *)string error:(BOOL)flag {
    NSAttributedString* attributedString = [[NSAttributedString alloc] initWithString:[string stringByAppendingString:@"\n"] attributes:(flag ? self.logErrorAtributes : self.logTextAtributes)];

    [self.logTextView.textStorage appendAttributedString:attributedString];
    [self.logTextView scrollRangeToVisible:NSMakeRange(self.logTextView.string.length, 0)];
}

@end
