//
//  CRServerConfiguration.m
//  Criollo
//
//  Created by Cătălin Stan on 10/25/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRServerConfiguration.h"

NSString* const CRServerDefaultInterface = @"";
NSUInteger const CRServerDefaultPort = 10781;

NSUInteger const CRConnectionDefaultInitialReadTimeout = 30;

NSString* const CRServerInterfaceKey = @"CRServerInterface";
NSString* const CRServerPortKey = @"CRServerPort";

NSString* const CRConnectionInitialReadTimeoutKey = @"CRConnectionInitialReadTimeout";

@interface CRServerConfiguration ()

- (void)readConfiguration;

@end

@implementation CRServerConfiguration

- (instancetype) init {
    self = [super init];
    if ( self != nil ) {
        self.CRServerInterface = CRServerDefaultInterface;
        self.CRServerPort = CRServerDefaultPort;
        self.CRConnectionInitialReadTimeout = CRConnectionDefaultInitialReadTimeout;
        [self readConfiguration];
    }
    return self;
}

- (void)readConfiguration {
    NSBundle* mainBundle = [NSBundle mainBundle];

    NSUserDefaults *args = [NSUserDefaults standardUserDefaults];

    // Interface
    NSString* interface = [args stringForKey:@"i"];
    if ( interface.length == 0 ) {
        interface = [args stringForKey:@"interface"];
        if (interface.length == 0 && [mainBundle objectForInfoDictionaryKey:CRServerInterfaceKey] ) {
            interface = [mainBundle objectForInfoDictionaryKey:CRServerInterfaceKey];
        }
    }
    if (interface.length != 0) {
        self.CRServerInterface = interface;
    }

    // Port
    NSUInteger portNumber = [args integerForKey:@"p"];
    if ( portNumber == 0 ) {
        portNumber = [args integerForKey:@"port"];
        if ( portNumber == 0 && [mainBundle objectForInfoDictionaryKey:CRServerPortKey] ) {
            portNumber = [[mainBundle objectForInfoDictionaryKey:CRServerPortKey] integerValue];
        }
    }
    if ( portNumber != 0 ) {
        self.CRServerPort = portNumber;
    }

    // Timeouts
    if ( [mainBundle objectForInfoDictionaryKey:CRConnectionInitialReadTimeoutKey] ) {
        self.CRConnectionInitialReadTimeout = [[mainBundle objectForInfoDictionaryKey:CRConnectionInitialReadTimeoutKey] integerValue];
    }
}

@end
