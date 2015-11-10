//
//  CommonAppDelegate.h
//  HelloWorld
//
//  Created by Cătălin Stan on 11/9/15.
//
//

#import <Criollo/Criollo.h>

#define PortNumber  10781
#define LogDebug        1

@interface CommonAppDelegate : NSObject <CRServerDelegate>

@property (nonatomic, strong) CRHTTPServer* server;

- (void)setupServer;
- (void)closeAllConnections;

- (IBAction)startListening:(id)sender;
- (IBAction)stopListening:(id)sender;

- (void)serverDidFailToStartWithError:(NSError*)error;
- (void)serverDidStartAtURL:(NSURL*)URL;

@end
