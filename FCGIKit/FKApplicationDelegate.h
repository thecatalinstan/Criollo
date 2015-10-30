//
//  FCGIApplicationDelegate.h
//  FCGIKit
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#ifndef NS_ENUM
@import Foundation;
#endif
typedef NS_ENUM(NSUInteger, FKApplicationTerminateReply) {
	FKTerminateCancel = 0,
	FKTerminateNow    = 1,
	FKTerminateLater  = 2
};

@class FKApplication, FKHTTPRequest, FKHTTPResponse, FKViewController;

@protocol FKApplicationDelegate <NSObject>

@required
- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (void)application:(FKApplication*)application presentViewController:(FKViewController*)viewController;

@optional
- (NSError *)application:(FKApplication *)application willPresentError:(NSError *)error;

- (void)applicationWillFinishLaunching:(NSNotification *)notification;

- (FKApplicationTerminateReply)applicationShouldTerminate:(FKApplication *)sender;
- (void)applicationWillTerminate:(NSNotification *)notification;

- (void)application:(FKApplication*)application didReceiveRequest:(NSDictionary*)userInfo;
- (void)application:(FKApplication*)application didPrepareResponse:(NSDictionary*)userInfo;
- (void)application:(FKApplication *)application didNotFindViewController:(NSDictionary *)userInfo;

- (NSString *)routeLookupURIForRequest:(FKHTTPRequest *)request;

@end