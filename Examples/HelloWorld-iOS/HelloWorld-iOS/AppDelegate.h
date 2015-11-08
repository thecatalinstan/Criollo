//
//  AppDelegate.h
//  HelloWorld-iOS
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Catalin Stan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CRHTTPServer;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) CRHTTPServer* server;

@end

