//
//  AppDelegate.m
//  HelloWorld-tvOS
//
//  Created by Cătălin Stan on 23/10/2017.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

        [self setupServer];
        
        __weak AppDelegate* waakSelf = self;
        
        // Ablock that creates a screenshot and sends it to the clinet
        [self.server get:@"/screenshot" block:^(CRRequest *request, CRResponse *response, CRRouteCompletionBlock completionHandler) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                UIView* hostView = waakSelf.window.rootViewController.view;
                
                UIGraphicsBeginImageContextWithOptions(hostView.bounds.size, hostView.opaque, 0.0);
                [hostView.layer renderInContext:UIGraphicsGetCurrentContext()];
                UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                NSData* imageData = UIImagePNGRepresentation(img);
                [response setValue:@"image/png" forHTTPHeaderField:@"Content-type"];
                [response setValue:@(imageData.length).stringValue forHTTPHeaderField:@"Content-Length"];
                [response sendData:imageData];
                
                completionHandler();
            });
        }];
        
        return YES;
    }
    
    - (void)applicationWillTerminate:(UIApplication *)application {
        if (self.isConnected) {
            [self stopListening:nil];
        }
    }
    
#pragma mark - Logging
    
    - (NSDictionary *)logTextAtributes {
        static NSDictionary* _logTextAtributes;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSMutableDictionary* tempDictionary = [NSMutableDictionary dictionaryWithDictionary:super.logDebugAtributes];
            tempDictionary[NSFontAttributeName] = [UIFont systemFontOfSize:16.f];
            tempDictionary[NSForegroundColorAttributeName] = [UIColor lightGrayColor];
            _logTextAtributes = tempDictionary.copy;
        });
        return _logTextAtributes;
    }
    
    - (NSDictionary *)logDebugAtributes {
        static  NSDictionary* _logDebugAtributes;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSMutableDictionary* tempDictionary = [NSMutableDictionary dictionaryWithDictionary:super.logDebugAtributes];
            tempDictionary[NSFontAttributeName] = [UIFont systemFontOfSize:16.f];
            tempDictionary[NSForegroundColorAttributeName] = [UIColor grayColor];
            _logDebugAtributes = tempDictionary.copy;
        });
        return _logDebugAtributes;
    }
    
    - (NSDictionary *)logErrorAtributes {
        static NSDictionary* _logErrorAtributes;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSMutableDictionary* tempDictionary = [NSMutableDictionary dictionaryWithDictionary:super.logDebugAtributes];
            tempDictionary[NSFontAttributeName] = [UIFont systemFontOfSize:16.f];
            tempDictionary[NSForegroundColorAttributeName] = [UIColor redColor];
            _logErrorAtributes = tempDictionary.copy;
        });
        return _logErrorAtributes;
    }
    
    - (NSDictionary *)linkTextAttributes {
        __block NSDictionary* _linkTextAttributes;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSMutableDictionary* tempDictionary = [NSMutableDictionary dictionaryWithDictionary:super.linkTextAttributes];
            tempDictionary[NSForegroundColorAttributeName] = [UIColor whiteColor];
            _linkTextAttributes = tempDictionary.copy;
        });
        return _linkTextAttributes;
    }
    
    
    @end

