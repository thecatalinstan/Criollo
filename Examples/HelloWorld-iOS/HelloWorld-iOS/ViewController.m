//
//  ViewController.m
//  HelloWorld-iOS
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Catalin Stan. All rights reserved.
//

#import <CriolloiOS/CriolloiOS.h>
#import "AppDelegate.h"
#import "ViewController.h"
#include <ifaddrs.h>
#include <arpa/inet.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *logTextView;

- (NSDictionary*)linkTextAttributes;

@end

@implementation ViewController

- (NSDictionary*)linkTextAttributes {
    static NSDictionary* _linkTextAttributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _linkTextAttributes = @{
                                NSForegroundColorAttributeName: [UIColor whiteColor],
                                NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                                };
    });
    return _linkTextAttributes;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Eye-candy
    self.logTextView.backgroundColor = [UIColor blackColor];
    self.logTextView.text = nil;
    self.logTextView.attributedText = nil;
    self.logTextView.linkTextAttributes = self.linkTextAttributes;

    [self setNeedsStatusBarAppearanceUpdate];

    // Append message to the list
    [[NSNotificationCenter defaultCenter] addObserverForName:@"LogMessage" object:nil queue:nil  usingBlock:^(NSNotification * _Nonnull note) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAttributedString* attributedString = note.object;
            [self.logTextView.textStorage appendAttributedString:attributedString];
            [self.logTextView scrollRangeToVisible:NSMakeRange(self.logTextView.text.length, 0)];
        });
    }];

    NSError* serverError;
    AppDelegate* delegate = [UIApplication sharedApplication].delegate;
    CRHTTPServer* server = delegate.server;
    if ( [server startListeningOnPortNumber:PortNumber error:&serverError] ) {
        NSString* address;
        BOOL result = [self getIPAddress:&address];
        if ( !result ) {
            address = @"127.0.0.1";
        }
        [delegate logFormat:@"Started HTTP server at http://%@:%lu/", server.configuration.CRServerInterface.length == 0 ? address : server.configuration.CRServerInterface, server.configuration.CRServerPort];
    }

    if ( serverError != nil ) {
        [delegate logErrorFormat:@"%@\n%@", @"The HTTP server could be started.", serverError];
    }

}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// see: http://stackoverflow.com/questions/6807788/how-to-get-ip-address-of-iphone-programatically
- (BOOL)getIPAddress:(NSString**)address {
    BOOL result = NO;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    *address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    result = YES;
                } else if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"pdp_ip0"]) {
                    *address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    result = YES;
                }

            }
            temp_addr = temp_addr->ifa_next;
        }
    }

    freeifaddrs(interfaces);
    return result;
}

@end
