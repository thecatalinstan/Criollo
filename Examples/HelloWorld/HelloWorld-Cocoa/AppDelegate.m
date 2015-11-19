//
//  AppDelegate.m
//  HelloWorld-Cocoa
//
//  Created by Cătălin Stan on 11/9/15.
//
//

#import "AppDelegate.h"
#import "WindowController.h"

@interface AppDelegate ()

@property (nonatomic, strong) WindowController* windowController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self setupServer];

    __weak AppDelegate* weakSelf = self;
    // A block that creates a screenshot and sends it to the clinet
    [self.server addBlock:^(CRRequest *request, CRResponse *response, void (^completionHandler)()) {
        NSMutableData* imageData = [NSMutableData data];

        CGImageRef windowImage = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionOnScreenOnly, (CGWindowID)weakSelf.windowController.window.windowNumber, kCGWindowImageBestResolution);
        CGImageDestinationRef destination =  CGImageDestinationCreateWithData((CFMutableDataRef)imageData, kUTTypePNG, 1, NULL);
        CGImageDestinationAddImage(destination, windowImage, nil);
        CGImageDestinationFinalize(destination);

        CFRelease(destination);
        CFRelease(windowImage);

        [response setValue:@"image/png" forHTTPHeaderField:@"Content-type"];
        [response setValue:@(imageData.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [response sendData:imageData];

        completionHandler();
    } forPath:@"/screenshot" HTTPMethod:@"GET"];

    self.windowController = [[WindowController alloc] initWithWindowNibName:@"WindowController"];
    [self.windowController showWindow:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    if (self.isConnected) {
        [self stopListening:nil];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

#pragma mark - Logging

- (NSDictionary *)logTextAtributes {
    static NSDictionary* _logTextAtributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary* tempDictionary = [NSMutableDictionary dictionaryWithDictionary:super.logDebugAtributes];
        tempDictionary[NSFontAttributeName] = [NSFont systemFontOfSize:[NSFont systemFontSize]];
        tempDictionary[NSForegroundColorAttributeName] = [NSColor lightGrayColor];
        _logTextAtributes = tempDictionary.copy;
    });
    return _logTextAtributes;
}

- (NSDictionary *)logDebugAtributes {
    static  NSDictionary* _logDebugAtributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary* tempDictionary = [NSMutableDictionary dictionaryWithDictionary:super.logDebugAtributes];
        tempDictionary[NSFontAttributeName] = [NSFont systemFontOfSize:[NSFont systemFontSize]];
        tempDictionary[NSForegroundColorAttributeName] = [NSColor grayColor];
        _logDebugAtributes = tempDictionary.copy;
    });
    return _logDebugAtributes;
}

- (NSDictionary *)logErrorAtributes {
    static NSDictionary* _logErrorAtributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary* tempDictionary = [NSMutableDictionary dictionaryWithDictionary:super.logDebugAtributes];
        tempDictionary[NSFontAttributeName] = [NSFont systemFontOfSize:[NSFont systemFontSize]];
        tempDictionary[NSForegroundColorAttributeName] = [NSColor redColor];
        _logErrorAtributes = tempDictionary.copy;
    });
    return _logErrorAtributes;
}

- (NSDictionary *)linkTextAttributes {
    __block NSDictionary* _linkTextAttributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary* tempDictionary = [NSMutableDictionary dictionaryWithDictionary:super.linkTextAttributes];
        tempDictionary[NSForegroundColorAttributeName] = [NSColor whiteColor];
        _linkTextAttributes = tempDictionary.copy;
    });
    return _linkTextAttributes;
}


@end
