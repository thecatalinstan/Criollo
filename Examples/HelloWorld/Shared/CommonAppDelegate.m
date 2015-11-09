//
//  CommonAppDelegate.m
//  HelloWorld
//
//  Created by Cătălin Stan on 11/9/15.
//
//

#import "CommonAppDelegate.h"
#import "CommonRequestHandler.h"

@implementation CommonAppDelegate

- (void)setupServer {
    self.server = [[CRHTTPServer alloc] initWithDelegate:self];

    CRRouteHandlerBlock helloBlock = [CommonRequestHandler defaultHandler].helloWorldBlock;
    CRRouteHandlerBlock statusBlock = [CommonRequestHandler defaultHandler].statusBlock;

    [self.server addHandlerBlock:helloBlock];
    [self.server addHandlerBlock:statusBlock forPath:@"/status" HTTPMethod:@"GET"];
}

- (void)startListening:(id)sender {
    NSError*serverError;
    if ( ! [self.server startListeningOnPortNumber:PortNumber error:&serverError] ) {
        NSURL* URL;
        [self serverDidStartAtURL:URL];
    } else {
        [self serverDidFailToStartWithError:serverError];
    }
}

- (void)stopListening:(id)sender {
    [self.server stopListening];
}

- (void)closeAllConnections {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self.server closeAllConnections];
    });
}

- (void)serverDidStartAtURL:(NSURL *)URL {
}

- (void)serverDidFailToStartWithError:(NSError *)error {
}

@end
