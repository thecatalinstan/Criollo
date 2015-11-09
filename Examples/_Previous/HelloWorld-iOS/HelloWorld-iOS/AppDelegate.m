//
//  AppDelegate.m
//  HelloWorld-iOS
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Catalin Stan. All rights reserved.
//

#import <CriolloiOS/CriolloiOS.h>
#import <sys/utsname.h>

#import "AppDelegate.h"
#import "RequestInfo.h"

@interface AppDelegate () <CRServerDelegate> {
}

@property (strong) NSString* uname;
@property (readonly) NSArray<RequestInfo*> *requests;

- (void)logString:(NSString*)string attributes:(NSDictionary*)attributes;

- (NSDictionary*)logTextAtributes;
- (NSDictionary*)logDebugAtributes;
- (NSDictionary*)logErrorAtributes;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // Get some info
    struct utsname systemInfo;
    uname(&systemInfo);
    _uname = [NSString stringWithFormat:@"%s %s %s %s %s", systemInfo.sysname, systemInfo.nodename, systemInfo.release, systemInfo.version, systemInfo.machine];

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

    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Stop listening
    [self logFormat:@"Exiting"];
    [self.server stopListening];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
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
    [self logFormat:@" * Connection from: %@:%lu", connection.remoteAddress, connection.remotePort];
}

- (void)server:(CRServer *)server didCloseConnection:(CRConnection *)connection {
    [self logFormat:@" * Disconnected."];
}

- (void)server:(CRServer *)server didReceiveRequest:(CRRequest *)request {
//    [self logDebugFormat:@" * Request: %@", request];
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
                               NSFontAttributeName: [UIFont systemFontOfSize:[UIFont systemFontSize]],
                               NSForegroundColorAttributeName: [UIColor lightGrayColor],
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
                               NSFontAttributeName: [UIFont systemFontOfSize:[UIFont systemFontSize]],
                               NSForegroundColorAttributeName: [UIColor grayColor],
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
                               NSFontAttributeName: [UIFont systemFontOfSize:[UIFont systemFontSize]],
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
