//
//  AppDelegate.m
//  
//
//  Created by Cătălin Stan on 16/09/2022.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (readonly) CRHTTPServer *server;

@end

@implementation AppDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        _server = [CRHTTPServer new];
    }
    return self;
}

#pragma mark - CRApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self.server add:^(CRRequest *request, CRResponse *response, CRRouteCompletionBlock completionHandler) {
            [response send:@"Hello world"];
    }];
    
    [self.server startListening];
}

@end
