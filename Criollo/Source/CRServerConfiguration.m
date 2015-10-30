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

NSUInteger const CRConnectionDefaultInitialReadTimeout = 5;

NSUInteger const CRHTTPConnectionDefaultReadHeaderLineTimeout = 2;
NSUInteger const CRHTTPConnectionDefaultReadHeaderTimeout = 2;
NSUInteger const CRHTTPConnectionDefaultReadBodyTimeout = 2;
NSUInteger const CRHTTPConnectionDefaultWriteHeaderTimeout = 2;
NSUInteger const CRHTTPConnectionDefaultWriteBodyTimeout = 2;
NSUInteger const CRHTTPConnectionDefaultWriteGeneralTimeout = 5;

NSUInteger const CRRequestDefaultMaxHeaderLineLength = 1024;
NSUInteger const CRRequestDefaultMaxHeaderLength = 20 * 1024;

NSUInteger const CRRequestDefaultBodyBufferSize = 8 * 1024 * 1024;

NSUInteger const CRHTTPConnectionDefaultKeepAliveTimeout = 15;
NSUInteger const CRHTTPConnectionDefaultMaxKeepAliveConnections = 10;

NSUInteger const CRFCGIConnectionDefaultReadRecordTimeout = 5;

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

NSString* const CRHTTPConnectionKeepAliveTimeoutKey = @"CRHTTPConnectionKeepAliveTimeout";
NSString* const CRHTTPConnectionMaxKeepAliveConnectionsKey = @"CRHTTPConnectionMaxKeepAliveConnections";
NSString* const CRFCGIConnectionReadRecordTimeoutKey = @"CRFCGIConnectionReadRecordTimeout";


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

    if ( [mainBundle objectForInfoDictionaryKey:CRFCGIConnectionReadRecordTimeoutKey] ) {
        self.CRFCGIConnectionReadRecordTimeout = [[mainBundle objectForInfoDictionaryKey:CRFCGIConnectionReadRecordTimeoutKey] integerValue];
    } else {
        self.CRFCGIConnectionReadRecordTimeout = CRFCGIConnectionDefaultReadRecordTimeout;
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

    // Keep alive
    if ( [mainBundle objectForInfoDictionaryKey:CRHTTPConnectionKeepAliveTimeoutKey] ) {
        self.CRHTTPConnectionKeepAliveTimeout = [[mainBundle objectForInfoDictionaryKey:CRHTTPConnectionKeepAliveTimeoutKey] integerValue];
    } else {
        self.CRHTTPConnectionKeepAliveTimeout = CRHTTPConnectionDefaultKeepAliveTimeout;
    }
    if ( [mainBundle objectForInfoDictionaryKey:CRHTTPConnectionMaxKeepAliveConnectionsKey] ) {
        self.CRHTTPConnectionMaxKeepAliveConnections = [[mainBundle objectForInfoDictionaryKey:CRHTTPConnectionMaxKeepAliveConnectionsKey] integerValue];
    } else {
        self.CRHTTPConnectionMaxKeepAliveConnections = CRHTTPConnectionDefaultMaxKeepAliveConnections;
    }
}

@end
