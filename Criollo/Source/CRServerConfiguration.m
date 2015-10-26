//
//  CRServerConfiguration.m
//  Criollo
//
//  Created by Cătălin Stan on 10/25/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRServerConfiguration.h"

// Defaults
NSString* const CRServerDefaultInterface = @"";
NSUInteger const CRServerDefaultPort = 10781;

NSUInteger const CRConnectionDefaultInitialReadTimeout = 30;
NSUInteger const CRHTTPConnectionDefaultReadHeaderLineTimeout = 30;
NSUInteger const CRHTTPConnectionDefaultReadHeaderTimeout = 30;
NSUInteger const CRHTTPConnectionDefaultReadBodyTimeout = 30;
NSUInteger const CRHTTPConnectionDefaultWriteHeaderTimeout = 30;
NSUInteger const CRHTTPConnectionDefaultWriteBodyTimeout = 0;
NSUInteger const CRHTTPConnectionDefaultWriteGeneralTimeout = 30;

NSUInteger const CRRequestDefaultMaxHeaderLineLength = 1024;
NSUInteger const CRRequestDefaultMaxHeaderLength = 10 * 1024;
NSUInteger const CRRequestDefaultBodyBufferSize = 1024 * 1024;

// Keys
NSString* const CRServerInterfaceKey = @"CRServerInterface";
NSString* const CRServerPortKey = @"CRServerPort";

NSString* const CRConnectionInitialReadTimeoutKey = @"CRConnectionInitialReadTimeout";
NSString* const CRHTTPConnectionReadHeaderLineTimeoutKey = @"CRHTTPConnectionReadHeaderLineTimeout";
NSString* const CRHTTPConnectionReadHeaderTimeoutKey = @"CRHTTPConnectionReadHeaderTimeout";
NSString* const CRHTTPConnectionReadBodyTimeoutKey = @"CRHTTPConnectionReadBodyTimeout";
NSString* const CRHTTPConnectionWriteHeaderTimeoutKey = @"CRHTTPConnectionWriteHeaderTimeout";
NSString* const CRHTTPConnectionWriteBodyTimeoutKey = @"CRHTTPConnectionWriteBodyTimeout";
NSString* const CRHTTPConnectionWriteGeneralTimeoutKey = @"CRHTTPConnectionWriteGeneralTimeout";

NSString* const CRRequestMaxHeaderLineLengthKey = @"CRRequestMaxHeaderLineLength";
NSString* const CRRequestMaxHeaderLengthKey = @"CRRequestMaxHeaderLength";
NSString* const CRRequestBodyBufferSizeKey = @"CRRequestBodyBufferSize";



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
    } else {
        self.CRConnectionInitialReadTimeout = CRConnectionDefaultInitialReadTimeout;
    }
    if ( [mainBundle objectForInfoDictionaryKey:CRHTTPConnectionReadHeaderLineTimeoutKey] ) {
        self.CRHTTPConnectionReadHeaderLineTimeout = [[mainBundle objectForInfoDictionaryKey:CRHTTPConnectionReadHeaderLineTimeoutKey] integerValue];
    } else {
        self.CRHTTPConnectionReadHeaderLineTimeout = CRHTTPConnectionDefaultReadHeaderLineTimeout;
    }
    if ( [mainBundle objectForInfoDictionaryKey:CRHTTPConnectionReadHeaderTimeoutKey] ) {
        self.CRHTTPConnectionReadHeaderTimeout = [[mainBundle objectForInfoDictionaryKey:CRHTTPConnectionReadHeaderTimeoutKey] integerValue];
    } else {
        self.CRHTTPConnectionReadHeaderTimeout = CRHTTPConnectionDefaultReadHeaderTimeout;
    }
    if ( [mainBundle objectForInfoDictionaryKey:CRHTTPConnectionReadBodyTimeoutKey] ) {
        self.CRHTTPConnectionReadBodyTimeout = [[mainBundle objectForInfoDictionaryKey:CRHTTPConnectionReadBodyTimeoutKey] integerValue];
    } else {
        self.CRHTTPConnectionReadBodyTimeout = CRHTTPConnectionDefaultReadBodyTimeout;
    }
    if ( [mainBundle objectForInfoDictionaryKey:CRHTTPConnectionWriteHeaderTimeoutKey] ) {
        self.CRHTTPConnectionWriteHeaderTimeout = [[mainBundle objectForInfoDictionaryKey:CRHTTPConnectionWriteHeaderTimeoutKey] integerValue];
    } else {
        self.CRHTTPConnectionWriteHeaderTimeout = CRHTTPConnectionDefaultWriteHeaderTimeout;
    }
    if ( [mainBundle objectForInfoDictionaryKey:CRHTTPConnectionWriteBodyTimeoutKey] ) {
        self.CRHTTPConnectionWriteBodyTimeout = [[mainBundle objectForInfoDictionaryKey:CRHTTPConnectionWriteBodyTimeoutKey] integerValue];
    } else {
        self.CRHTTPConnectionWriteBodyTimeout = CRHTTPConnectionDefaultWriteBodyTimeout;
    }
    if ( [mainBundle objectForInfoDictionaryKey:CRHTTPConnectionWriteGeneralTimeoutKey] ) {
        self.CRHTTPConnectionWriteGeneralTimeout = [[mainBundle objectForInfoDictionaryKey:CRHTTPConnectionWriteGeneralTimeoutKey] integerValue];
    } else {
        self.CRHTTPConnectionWriteGeneralTimeout = CRHTTPConnectionDefaultWriteGeneralTimeout;
    }

    // Limits
    if ( [mainBundle objectForInfoDictionaryKey:CRRequestMaxHeaderLineLengthKey] ) {
        self.CRRequestMaxHeaderLineLength = [[mainBundle objectForInfoDictionaryKey:CRRequestMaxHeaderLineLengthKey] integerValue];
    } else {
        self.CRRequestMaxHeaderLineLength = CRRequestDefaultMaxHeaderLineLength;
    }
    if ( [mainBundle objectForInfoDictionaryKey:CRRequestMaxHeaderLengthKey] ) {
        self.CRRequestMaxHeaderLength = [[mainBundle objectForInfoDictionaryKey:CRRequestMaxHeaderLengthKey] integerValue];
    } else {
        self.CRRequestMaxHeaderLength = CRRequestDefaultMaxHeaderLength;
    }

    // Buffers
    if ( [mainBundle objectForInfoDictionaryKey:CRRequestBodyBufferSizeKey] ) {
        self.CRRequestBodyBufferSize = [[mainBundle objectForInfoDictionaryKey:CRRequestBodyBufferSizeKey] integerValue];
    } else {
        self.CRRequestBodyBufferSize = CRRequestDefaultBodyBufferSize;
    }
}

@end
