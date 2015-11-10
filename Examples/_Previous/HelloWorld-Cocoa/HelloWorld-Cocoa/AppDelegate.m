//
//  AppDelegate.m
//  HelloWorld-Cocoa
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Catalin Stan. All rights reserved.
//

#import <Criollo/Criollo.h>
#import <sys/utsname.h>

#import "AppDelegate.h"
#import "RequestInfo.h"

@interface AppDelegate () <CRServerDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSTextView *logTextView;

@property (strong) NSString* uname;
@property (readonly) NSArray<RequestInfo*> *requests;

- (void)updateConnectionInfo;

- (void)logFormat:(NSString *)format, ...;
- (void)logDebugFormat:(NSString *)format, ...;
- (void)logErrorFormat:(NSString *)format, ...;

- (void)logString:(NSString*)string attributes:(NSDictionary*)attributes;

- (NSDictionary*)logTextAtributes;
- (NSDictionary*)logDebugAtributes;
- (NSDictionary*)logErrorAtributes;
- (NSDictionary*)linkTextAttributes;
    
@end

@implementation AppDelegate

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    // Get some info
    struct utsname systemInfo;
    uname(&systemInfo);
    _uname = [NSString stringWithFormat:@"%s %s %s %s %s", systemInfo.sysname, systemInfo.nodename, systemInfo.release, systemInfo.version, systemInfo.machine];

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
        [responseString appendFormat:@"<small>%@</small><br/>", _uname];        
        [responseString appendFormat:@"<small>Task took: %.4fms</small>", [startTime timeIntervalSinceNow] * -1000];

        [response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        [response setValue:@(responseString.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [response sendString:responseString];

        completionHandler();
    };
    [self.server addHandlerBlock:statusBlock forPath:@"/status" HTTPMethod:@"GET"];

    // Ablock that creates a screenshot and sends it to the clinet
    CRRouteHandlerBlock screenshotBlock = ^(CRRequest *request, CRResponse *response, void (^completionHandler)()) {

        NSMutableData* imageData = [NSMutableData data];

        CGImageRef windowImage = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionOnScreenOnly, (CGWindowID)self.window.windowNumber, kCGWindowImageBestResolution);
        CGImageDestinationRef destination =  CGImageDestinationCreateWithData((CFMutableDataRef)imageData, kUTTypePNG, 1, NULL);
        CGImageDestinationAddImage(destination, windowImage, nil);
        CGImageDestinationFinalize(destination);

        CFRelease(destination);
        CFRelease(windowImage);

        [response setValue:@"image/png" forHTTPHeaderField:@"Content-type"];
        [response setValue:@(imageData.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [response sendData:imageData];

        completionHandler();
    };
    [self.server addHandlerBlock:screenshotBlock forPath:@"/screenshot" HTTPMethod:@"GET"];

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
        [self logFormat:@"Closing all connections"];
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
    [self logFormat:@"Exiting"];
    [self.server stopListening];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

#pragma mark - CRServerDelegate

// These methods are all optional and they are here only for updating the
// user interface so that it reflects the current connections
//
// Calling any sort of logging or KVO operations SEVERLY impacts performance
// Set KVO to 0 to disable

#if KVO
- (void)serverDidStartListening:(CRServer *)server {
    [self logDebugFormat:@" * Started listening on: %@:%lu", server.configuration.CRServerInterface, server.configuration.CRServerPort];
}

- (void)serverDidStopListening:(CRServer *)server {
    [self logDebugFormat:@" * Stopped listening on: %@:%lu", server.configuration.CRServerInterface, server.configuration.CRServerPort];
}

- (void)server:(CRServer *)server didAcceptConnection:(CRConnection *)connection {
    [self logDebugFormat:@" * Connection from: %@:%lu", connection.remoteAddress, connection.remotePort];
    [self updateConnectionInfo];
}

- (void)server:(CRServer *)server didCloseConnection:(CRConnection *)connection {
    [self logDebugFormat:@" * Disconnected."];
    [self updateConnectionInfo];
}

- (void)server:(CRServer *)server didReceiveRequest:(CRRequest *)request {
    [self logDebugFormat:@" * Request: %@", request];
    [self updateConnectionInfo];
}

- (void)server:(CRServer *)server didFinishRequest:(CRRequest *)request {
    [self logFormat:@" * Request: %@ - %lu", request, request.response.statusCode];
    [self updateConnectionInfo];
}
#endif

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

- (NSDictionary *)logDebugAtributes {
    static NSDictionary* _logTextAttributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableParagraphStyle* style = [[NSMutableParagraphStyle alloc] init];
        style.lineHeightMultiple = 1.1;
        style.lineBreakMode = NSLineBreakByWordWrapping;
        _logTextAttributes = @{
                               NSFontAttributeName: [NSFont systemFontOfSize:12],
                               NSForegroundColorAttributeName: [NSColor lightGrayColor],
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

- (void)logFormat:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    [self logString:formattedString attributes:self.logTextAtributes];
}

- (void)logDebugFormat:(NSString *)format, ... {
#if LogDebug
    va_list args;
    va_start(args, format);
    NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    [self logString:formattedString attributes:self.logDebugAtributes];
#endif
}

- (void)logErrorFormat:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    [self logString:formattedString attributes:self.logErrorAtributes];
}

- (void)logString:(NSString *)string attributes:(NSDictionary *)attributes {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAttributedString* attributedString = [[NSAttributedString alloc] initWithString:[string stringByAppendingString:@"\n"] attributes:attributes];
        [self.logTextView.textStorage appendAttributedString:attributedString];
        [self.logTextView scrollRangeToVisible:NSMakeRange(self.logTextView.string.length, 0)];
    });
}

#pragma mark - KVO

// This whole KVO thing doesn't really perform that well under heavy usage
// ab -c 100 -n 20000 -l -k http://127.0.0.1:10781/

- (void)updateConnectionInfo {
    NSMutableArray* requests = [NSMutableArray array];

    @try {
        @synchronized(self.server.connections) {
            NSArray* serverConnections = self.server.connections.copy;

            [serverConnections enumerateObjectsUsingBlock:^(CRConnection*  _Nonnull connection, NSUInteger idx, BOOL * _Nonnull stop) {
                @synchronized(connection) {
                    NSArray* connectionRequests = connection.requests.copy;
                    @synchronized(connectionRequests) {
                        [connectionRequests enumerateObjectsUsingBlock:^(CRRequest*  _Nonnull request, NSUInteger idx, BOOL * _Nonnull stop) {
                            RequestInfo* info = [[RequestInfo alloc] initWithRequest:request];
                            @synchronized(requests) {
                                [requests addObject:info];
                            }
                        }];
                    }
                }
            }];
        }
    }
    @catch (NSException *exception) {
//        NSLog(@"%@", exception);
    }
    @finally {
        @synchronized(_requests) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self willChangeValueForKey:@"requests"];
                _requests = requests;
                [self didChangeValueForKey:@"requests"];
            });
        }
    }
}

@end
