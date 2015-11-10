//
//  AppDelegate.m
//  HelloWorld-iOS
//
//  Created by Cătălin Stan on 11/9/15.
//
//

#import "AppDelegate.h"

//// Ablock that creates a screenshot and sends it to the clinet
//CRRouteHandlerBlock screenshotBlock = ^(CRRequest *request, CRResponse *response, void (^completionHandler)()) {
//
//    UIView* hostView = self.window.rootViewController.view;
//
//    UIGraphicsBeginImageContextWithOptions(hostView.bounds.size, hostView.opaque, 0.0);
//    [hostView.layer renderInContext:UIGraphicsGetCurrentContext()];
//    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//
//    NSData* imageData = UIImagePNGRepresentation(img);
//    [response setValue:@"image/png" forHTTPHeaderField:@"Content-type"];
//    [response setValue:@(imageData.length).stringValue forHTTPHeaderField:@"Content-Length"];
//    [response sendData:imageData];
//
//    completionHandler();
//};

//NSFontAttributeName: [UIFont systemFontOfSize:[UIFont systemFontSize]],
//NSForegroundColorAttributeName: [UIColor lightGrayColor],

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"TARGET_IPHONE_SIMULATOR: %d", TARGET_IPHONE_SIMULATOR);
    NSLog(@"TARGET_OS_IPHONE: %d", TARGET_OS_IPHONE);
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
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

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
