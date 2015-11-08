//
//  AppDelegate.m
//  HelloWorld-iOS
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Catalin Stan. All rights reserved.
//

#import <CriolloiOS/CriolloiOS.h>

#import "AppDelegate.h"
#import "RequestInfo.h"

#define PortNumber          5000   // HTTP server port
#define Interface    @"127.0.0.1"   // HTTP server port
#define LogDebug                0   // Debug logging
#define KVO                     1   // Update user interface with every request

@interface AppDelegate () <CRServerDelegate>

@property (readonly) NSArray<RequestInfo*> *requests;

- (void)logFormat:(NSString *)format, ...;
- (void)logDebugFormat:(NSString *)format, ...;
- (void)logErrorFormat:(NSString *)format, ...;

- (void)logString:(NSString*)string attributes:(NSDictionary*)attributes;

- (NSDictionary*)logTextAtributes;
- (NSDictionary*)logDebugAtributes;
- (NSDictionary*)logErrorAtributes;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

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

    // Ablock that creates a screenshot and sends it to the clinet
    CRRouteHandlerBlock screenshotBlock = ^(CRRequest *request, CRResponse *response, void (^completionHandler)()) {

        UIView* hostView = self.window.rootViewController.view;

        UIGraphicsBeginImageContextWithOptions(hostView.bounds.size, hostView.opaque, 0.0);
        [hostView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        NSData* imageData = UIImagePNGRepresentation(img);
        [response setValue:@"image/png" forHTTPHeaderField:@"Content-type"];
        [response setValue:@(imageData.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [response sendData:imageData];

        completionHandler();
    };
    [self.server addHandlerBlock:screenshotBlock forPath:@"/screenshot" HTTPMethod:@"GET"];

    // Start listening
    NSError* serverError;
    if ( [self.server startListeningOnPortNumber:PortNumber interface:Interface  error:&serverError] ) {
        [self logErrorFormat:@"Failed to start HTTP server. %@", serverError.localizedDescription];
    }

    if ( serverError != nil ) {
        [self logErrorFormat:@"%@\n%@", @"The HTTP server could be started.", serverError.localizedDescription];
    }

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [self.server stopListening];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {

}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSError* serverError;
    if ( [self.server startListeningOnPortNumber:PortNumber interface:Interface error:&serverError] ) {
        [self logErrorFormat:@"Failed to start HTTP server. %@", serverError.localizedDescription];
    }

    if ( serverError != nil ) {
        [self logErrorFormat:@"%@\n%@", @"The HTTP server could be started.", serverError.localizedDescription];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Stop listening
    [self logFormat:@"Exiting"];
    [self.server stopListening];
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
}

- (void)server:(CRServer *)server didCloseConnection:(CRConnection *)connection {
    [self logDebugFormat:@" * Disconnected."];
}

- (void)server:(CRServer *)server didReceiveRequest:(CRRequest *)request {
    [self logDebugFormat:@" * Request: %@", request];
}

- (void)server:(CRServer *)server didFinishRequest:(CRRequest *)request {
    [self logFormat:@" * Request: %@ - %lu", request, request.response.statusCode];
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
                               NSFontAttributeName: [UIFont systemFontOfSize:12],
                               NSForegroundColorAttributeName: [UIColor darkGrayColor],
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
                               NSFontAttributeName: [UIFont systemFontOfSize:12],
                               NSForegroundColorAttributeName: [UIColor lightGrayColor],
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
                               NSFontAttributeName: [UIFont systemFontOfSize:12],
                               NSForegroundColorAttributeName: [UIColor redColor],
                               NSParagraphStyleAttributeName: style,
                               };
    });
    return _logTextAttributes;
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
    NSAttributedString* attributedString = [[NSAttributedString alloc] initWithString:[string stringByAppendingString:@"\n"] attributes:attributes];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LogMessage" object:attributedString];
}

@end
