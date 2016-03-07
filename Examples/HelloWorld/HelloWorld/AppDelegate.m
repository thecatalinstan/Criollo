//
//  AppDelegate.m
//  HelloWorld
//
//  Created by Cătălin Stan on 07/03/16.
//  Copyright © 2016 Criollo.io. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate () <CRServerDelegate>

@property (nonatomic, strong, nonnull) CRServer* server;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.server = [[CRHTTPServer alloc] init];

    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response setValue:[NSBundle mainBundle].bundleIdentifier forHTTPHeaderField:@"Server"];
        completionHandler();
    }];

    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response sendString:@"Hello world!"];
        completionHandler();
    } forPath:@"/" HTTPMethod:CRHTTPMethodGET];

    [self.server addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSUInteger statusCode = request.response.statusCode;
        NSString* contentLength = [request.response valueForHTTPHeaderField:@"Content-Length"];
        NSString* userAgent = request.env[@"HTTP_USER_AGENT"];
        NSString* remoteAddress = request.connection.remoteAddress;
        NSLog(@"%@ %@ - %lu %@ - %@", remoteAddress, request, statusCode, contentLength ? : @"-", userAgent);
    }];

    [self.server startListening];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
