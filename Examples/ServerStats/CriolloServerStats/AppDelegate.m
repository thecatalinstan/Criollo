//
//  AppDelegate.m
//  CriolloServerStats
//
//  Created by Cătălin Stan on 28/09/2017.
//  Copyright © 2017 Cătălin Stan. All rights reserved.
//

#import "AppDelegate.h"

#import <CSSystemInfoHelper/CSSystemInfoHelper.h>

@interface AppDelegate () <CRServerDelegate>

@property (nonatomic, assign) NSUInteger portNumber;
- (void)addRoutes;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.server = [[CRHTTPServer alloc] initWithDelegate:self];

    self.portNumber = 12345;

    if ( self.server ) {
        // This is where the server is set up to do the actual work
        [self addRoutes];
    }

    // This is just so that the black text field updates :)
    [[NSNotificationCenter defaultCenter] addObserverForName:NewRequestNotification object:nil queue:NSOperationQueue.currentQueue usingBlock:^(NSNotification * _Nonnull note) {
        [self willChangeValueForKey:@"lastLogMessage"];
        _lastLogMessage = note.object;
        [self didChangeValueForKey:@"lastLogMessage"];
    }];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self.server stopListening];
}

#pragma mark - CRServerDelegate

// This is just so that we can update the numbers in the UI
- (void)serverDidStartListening:(CRServer *)server {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isListening = YES;
    });

    NSLog(@"Successfully started server at %@:%ld", CSSystemInfoHelper.sharedHelper.IPAddress ? : @"127.0.0.1", self.portNumber);

    // Show the list of routes configured
    NSArray<NSString *> *paths = [[self.server valueForKeyPath:@"routes.@distinctUnionOfObjects.path"] sortedArrayUsingSelector:@selector(compare:)];
    [paths enumerateObjectsUsingBlock:^(NSString *  _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@" ** http://%@:%ld%@", CSSystemInfoHelper.sharedHelper.IPAddress ? : @"127.0.0.1", self.portNumber, path);
    }];
}

// This is just so that we can update the UI
- (void)serverDidStopListening:(CRServer *)server {
    NSLog(@"%@", @"Server stopped listening.");
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isListening = NO;
    });
}

// This is just so that we can update the UI
- (void)server:(CRServer *)server didAcceptConnection:(CRConnection *)connection {
    dispatch_async(dispatch_get_main_queue(), ^{
        @synchronized (self) {
            self.connectionsReceived++;
        }
    });
}

// This is just so that we can update the UI
- (void)server:(CRServer *)server didReceiveRequest:(CRRequest *)request {
    dispatch_async(dispatch_get_main_queue(), ^{
        @synchronized (self) {
            self.requestsReceived++;
        }
    });
}


- (void)server:(CRServer *)server didFinishRequest:(CRRequest *)request {
    // We do logging on a separate queue, just so that we don't take up the main
    // thread's time with non-essential stuff
    static dispatch_queue_t loggingQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        loggingQueue = dispatch_queue_create("loggingQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(loggingQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
    });

    dispatch_async(loggingQueue, ^{
        // This is just so that we can update the UI
        NSString *message = [NSString stringWithFormat:@"%@ %@ - %lu", [NSDate date], request, request.response.statusCode];
        NSLog(@"%@", message);
        [[NSNotificationCenter defaultCenter] postNotificationName:NewRequestNotification object:message];
    });

}

#pragma mark - Actions

- (void)startServer:(id)sender {
    self.isListening = NO;
    self.requestsReceived = 0;
    self.connectionsReceived = 0;

    NSError *error;
    if ( ! [self.server startListening:&error portNumber:self.portNumber] ) {
        NSLog(@"Error starting server: %@", error);
    }
}

- (void)stopServer:(id)sender {
    [self.server closeAllConnections:^{
        [self.server stopListening];
    }];
}

#pragma mark - Routes

// This is where we tell the server how to react to various requests
- (void)addRoutes {
    // Set a header for all routes
    [self.server add:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response setValue:[NSBundle mainBundle].bundleIdentifier forHTTPHeaderField:@"Server"];
        completionHandler();
    }];

    // Show the available paths
    [self.server get:@"/" block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response setValue:@"text/html" forHTTPHeaderField:@"Content-type"];

        [response writeFormat:@"<h1>%@</h1>", NSBundle.mainBundle.bundleIdentifier];
        [response writeFormat:@"<p>%@</p>", @"Available paths are:"];
        [response write:@"<ul>"];

        NSArray<NSString *> *paths = [[self.server valueForKeyPath:@"routes.@distinctUnionOfObjects.path"] sortedArrayUsingSelector:@selector(compare:)];
        [paths enumerateObjectsUsingBlock:^(NSString *  _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *url = [NSString stringWithFormat:@"http://%@:%ld%@", CSSystemInfoHelper.sharedHelper.IPAddress ? : @"127.0.0.1", self.portNumber, path];
            [response writeFormat:@"<li><a href=\"%@\">%@</a></li>", url, url];
        }];
        [response write:@"</ul>"];
        [response finish];
    }];

    // Send a dictionary as json
    [self.server get:@"/ping" block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
        [response send:@{@"status": @YES}];
    }];

    // Print some basic system info
    [self.server get:@"/info" block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
        CSSystemInfoHelper *sysinfo = [CSSystemInfoHelper sharedHelper];
        NSDictionary *output = @{
            @"SystemInfo": sysinfo.systemInfo,
            @"IPAddresses": sysinfo.AllIPAddresses
        };

        // Not Pretty-printed JSON
//        [response send:output]

        // Pretty-printed JSON
        NSData *prettyPrintedJSON = [NSJSONSerialization dataWithJSONObject:output options:NSJSONWritingPrettyPrinted error:nil];
        [response sendData:prettyPrintedJSON];
    }];

    // A block that creates a screenshot and sends it to the client as a png
    [self.server get:@"/screenshot" block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSMutableData* imageData = [NSMutableData data];

        CGImageRef windowImage = CGWindowListCreateImage(CGRectInfinite, kCGWindowListOptionOnScreenOnly, kCGNullWindowID, kCGWindowImageBestResolution);
        CGImageDestinationRef destination =  CGImageDestinationCreateWithData((CFMutableDataRef)imageData, kUTTypePNG, 1, NULL);
        CGImageDestinationAddImage(destination, windowImage, nil);
        CGImageDestinationFinalize(destination);

        CFRelease(destination);
        CFRelease(windowImage);

        [response setValue:@"inline; filename=\"screenshot.png\"" forHTTPHeaderField:@"Content-disposition"];
        [response setValue:@"image/png" forHTTPHeaderField:@"Content-type"];
        [response setValue:@(imageData.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [response sendData:imageData];
    }];

    // Serve your home directory as a astatic folder
    [self.server mount:@"/home" directoryAtPath:@"~" options:CRStaticDirectoryServingOptionsAutoIndex];

    // A more fancy way of defining paths
    [self.server get:@"/fancy/:foo/:bar" block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response setValue:@"text/plain" forHTTPHeaderField:@"Content-type"];
        [response send:[NSString stringWithFormat:@"%@", request.query]];
    }];
}

#pragma mark - Properties

- (void)setConnectionsReceived:(NSUInteger)connectionsReceived {
    [self willChangeValueForKey:@"connectionsReceived"];
    _connectionsReceived = connectionsReceived;
    [self didChangeValueForKey:@"connectionsReceived"];
}

- (void)setRequestsReceived:(NSUInteger)requestsReceived {
    [self willChangeValueForKey:@"requestsReceived"];
    _requestsReceived = requestsReceived;
    [self didChangeValueForKey:@"requestsReceived"];
}

- (void)setIsListening:(BOOL)isListening {
    [self willChangeValueForKey:@"isListening"];
    _isListening = isListening;
    [self didChangeValueForKey:@"isListening"];
}

- (NSString *)statusText {
    return [NSString stringWithFormat:@"Server is %@listening.", self.isListening ? @"" : @"not "];
}

#pragma mark - KVO

// This stuff here is just to make sure the UI is updated correctly in response
// to the properties changing

+ (NSSet<NSString *> *)keyPathsForValuesAffectingRequestsReceived {
    return [NSSet setWithObjects:@"server", @"isListening", @"connectionsReceived", nil];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingConnectionsReceived {
    return [NSSet setWithObjects:@"server", @"isListening", @"requestsReceived", nil];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingIsListening {
    return [NSSet setWithObjects:@"server", @"requestsReceived", @"connectionsReceived", nil];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingStatusText {
    return [NSSet setWithObjects:@"server", @"isListening", nil];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingLastLogMessage {
    return [NSSet setWithObjects:@"server", @"isListening", @"requestsReceived", @"connectionsReceived", nil];
}

@end
