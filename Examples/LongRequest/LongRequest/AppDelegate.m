//
//  AppDelegate.m
//  LongRequest
//
//  Created by Cătălin Stan on 11/02/2018.
//  Copyright © 2018 Cătălin Stan. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate () <CRServerDelegate>

@property (nonatomic, strong) CRHTTPServer *server;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.server = [[CRHTTPServer alloc] initWithDelegate:self];
    
    // https://localhost:10781/
    // Shows the request enviroment variables
    [self.server get:@"/" block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        
        NSMutableString *string = [NSMutableString string];
        [request.env enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [string appendFormat:@"%@ = %@\n", key, obj];
        }];
        [response send:string];
    }];
    
    // https://localhost:10781/timeout
    // Simulates a long lasting request (in truth it just sleeps for 20 seconds
    [self.server get:@"/timeout" block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        NSDate *startDate = [NSDate date];
        NSMutableString *string = [NSMutableString string];
        [string appendFormat:@"Started: %@\n", startDate];
        
        sleep(20);
        
        NSDate *endDate = [NSDate date];
        [string appendFormat:@"Ended: %@ (%.3f seconds)", endDate, [endDate timeIntervalSinceDate:startDate]];
        
        [response send:string];
        
    }];
    
    // https://localhost:10781/request
    // Performs a request to "/timeout" and returns the response of that request
    // to the client, or an error if one occured
    [self.server get:@"/request" block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
       
        NSURL* remoteURL = [NSURL URLWithString:@"https://localhost:10781/timeout"];
        NSMutableURLRequest *remoteRequest = [[NSMutableURLRequest alloc] initWithURL:remoteURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
        [remoteRequest setHTTPMethod:@"GET"];
        NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        
        [[session dataTaskWithRequest:remoteRequest completionHandler:^(NSData * _Nullable resData, NSURLResponse * _Nullable res, NSError * _Nullable error) {
            if ( error ) {
                [response setValue:@"text/plain" forHTTPHeaderField:@"Content-type"];
                [response setValue:@(error.description.length).stringValue forHTTPHeaderField:@"Content-length"];
                [response sendString:error.description];
            } else {
                [response setValue:((NSHTTPURLResponse *)res).MIMEType forHTTPHeaderField:@"Content-type"];
                [response setValue:@(resData.length).stringValue forHTTPHeaderField:@"Content-length"];
                [response sendData:resData];
            }
        }] resume];
    }];
    
    self.server.isSecure = YES;
    self.server.certificatePath = [NSBundle.mainBundle pathForResource:@"SecureHTTPServer.bundle" ofType:@"pem"];
    self.server.certificateKeyPath = [NSBundle.mainBundle pathForResource:@"SecureHTTPServer.key" ofType:@"pem"];
    
    [self.server startListening];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self.server stopListening];
}

- (void)server:(CRServer *)server didFinishRequest:(CRRequest *)request {
    NSLog(@"%@", request);
}

- (void)serverDidStartListening:(CRServer *)server {
    NSLog(@"%@", @"Server started listening.");
}

- (void)serverDidStopListening:(CRServer *)server {
    NSLog(@"%@", @"Server stopped listening.");
}

@end
