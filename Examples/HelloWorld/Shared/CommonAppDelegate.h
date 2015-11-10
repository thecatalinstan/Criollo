//
//  CommonAppDelegate.h
//  HelloWorld
//
//  Created by Cătălin Stan on 11/9/15.
//
//

#define PortNumber  10781
#define LogDebug        1

#define LogMessageNotificationName  @"LogMessageNotification"

#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR
#import <CriolloiOS/CriolloiOS.h>
#import <UIKit/UIKit.h>
#else
#import <Criollo/Criollo.h>
#import <Cocoa/Cocoa.h>
#endif

@interface CommonAppDelegate : NSObject <CRServerDelegate>

@property (nonatomic, strong) CRHTTPServer* server;

- (void)setupServer;
- (void)closeAllConnections;

- (IBAction)startListening:(id)sender;
- (IBAction)stopListening:(id)sender;

- (void)serverDidFailToStartWithError:(NSError*)error;
- (void)serverDidStartAtURL:(NSURL*)URL;

- (NSDictionary*)logTextAtributes;
- (NSDictionary*)logDebugAtributes;
- (NSDictionary*)logErrorAtributes;
- (NSDictionary*)linkTextAttributes;

- (void)logFormat:(NSString *)format, ...;
- (void)logDebugFormat:(NSString *)format, ...;
- (void)logErrorFormat:(NSString *)format, ...;

- (void)logString:(NSString*)string attributes:(NSDictionary*)attributes;

@end
