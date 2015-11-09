//
//  AppDelegate.m
//  HelloWorld
//
//  Created by Cătălin Stan on 28/04/15.
//  Copyright (c) 2015 Catalin Stan. All rights reserved.
//



#import "AppDelegate.h"

#define HTTPPortNumber 10782
#define FCGIPortNumber 10781

@interface AppDelegate () <CRServerDelegate>


@property (nonatomic, strong) CRHTTPServer* HTTPServer;
@property (nonatomic, strong) CRFCGIServer* FCGIServer;

@end

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    // Get some info

    self.HTTPServer = [[CRHTTPServer alloc] initWithDelegate:self];
    NSError* HTTPServerError;
    if ( ! [self.HTTPServer startListeningOnPortNumber:HTTPPortNumber error:&HTTPServerError] ) {
        [CRApp logErrorFormat:@"Failed to start HTTP server. %@", HTTPServerError.localizedDescription];
    } else {
        [CRApp logFormat:@"Started HTTP server at http://%@:%lu/", self.HTTPServer.configuration.CRServerInterface.length == 0 ? @"127.0.0.1" : self.HTTPServer.configuration.CRServerInterface, self.HTTPServer.configuration.CRServerPort];
    }

    self.FCGIServer = [[CRFCGIServer alloc] initWithDelegate:self];
    NSError* FCGIServerError;
    if ( ! [self.FCGIServer startListeningOnPortNumber:FCGIPortNumber error:&FCGIServerError] ) {
        [CRApp logErrorFormat:@"Failed to start FCGI server. %@", FCGIServerError.localizedDescription];
    } else {
        [CRApp logFormat:@"Running FCGI server on %@:%lu", self.FCGIServer.configuration.CRServerInterface.length == 0 ? @"127.0.0.1" : self.FCGIServer.configuration.CRServerInterface, self.FCGIServer.configuration.CRServerPort];
    }

    CRRouteHandlerBlock helloBlock = ^(CRRequest* request, CRResponse* response, void(^completionHandler)()) {

    };

    CRRouteHandlerBlock statusBlock =
    // Ablock that creates a screenshot and sends it to the clinet
    CRRouteHandlerBlock screenshotBlock = ^(CRRequest *request, CRResponse *response, void (^completionHandler)()) {

        NSMutableData* imageData = [NSMutableData data];

        CGImageRef windowImage = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionOnScreenOnly, 0, kCGWindowImageBestResolution);
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

    [self.HTTPServer addHandlerBlock:helloBlock];
    [self.HTTPServer addHandlerBlock:statusBlock forPath:@"/status" HTTPMethod:@"GET"];
    [self.HTTPServer addHandlerBlock:screenshotBlock forPath:@"/screenshot" HTTPMethod:@"GET"];

    [self.FCGIServer addHandlerBlock:helloBlock];
    [self.FCGIServer addHandlerBlock:statusBlock forPath:@"/status" HTTPMethod:@"GET"];
    [self.FCGIServer addHandlerBlock:screenshotBlock forPath:@"/screenshot" HTTPMethod:@"GET"];


    if ( HTTPServerError != nil  && FCGIServerError != nil ) {
        [CRApp logErrorFormat:@"%@", @"Neither the FCGI nor the HTTP server could be started. Exiting."];
        [CRApp terminate:nil];
    }
}

- (CRApplicationTerminateReply)applicationShouldTerminate:(CRApplication *)sender {
    if ( self.HTTPServer.connections.count > 0 || self.FCGIServer.connections.count > 0 ) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self.HTTPServer closeAllConnections];
            [self.FCGIServer closeAllConnections];
        });
        return CRTerminateLater;
    } else {
        return CRTerminateNow;
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self.HTTPServer stopListening];
    [self.FCGIServer stopListening];
}

#pragma mark - CRServerDelegate

@end
