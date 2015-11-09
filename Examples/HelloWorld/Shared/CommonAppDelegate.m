//
//  CommonAppDelegate.m
//  HelloWorld
//
//  Created by Cătălin Stan on 11/9/15.
//
//

#include <ifaddrs.h>
#include <arpa/inet.h>

#import "CommonAppDelegate.h"
#import "CommonRequestHandler.h"

@interface CommonAppDelegate ()

// see: http://stackoverflow.com/questions/6807788/how-to-get-ip-address-of-iphone-programatically
- (BOOL)getIPAddress:(NSString**)address;

@end

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
    if ( [self.server startListeningOnPortNumber:PortNumber error:&serverError] ) {
        NSString* address;
        BOOL result = [self getIPAddress:&address];
        if ( !result ) {
            address = @"127.0.0.1";
        }
        NSURL* URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%d/", address, PortNumber]];
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
#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR
                } else if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"pdp_ip0"]) {
                    *address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    result = YES;
#endif
                }

            }
            temp_addr = temp_addr->ifa_next;
        }
    }

    freeifaddrs(interfaces);
    return result;
}


@end
