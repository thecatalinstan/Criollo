//
//  CRHTTPServerConfiguration.m
//  Criollo
//
//  Created by Cătălin Stan on 10/30/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRHTTPServerConfiguration.h"

// Defaults
NSUInteger const CRHTTPConnectionDefaultReadHeaderLineTimeout = 2;
NSUInteger const CRHTTPConnectionDefaultReadHeaderTimeout = 2;
NSUInteger const CRHTTPConnectionDefaultReadBodyTimeout = 2;
NSUInteger const CRHTTPConnectionDefaultWriteHeaderTimeout = 2;
NSUInteger const CRHTTPConnectionDefaultWriteBodyTimeout = 2;
NSUInteger const CRHTTPConnectionDefaultWriteGeneralTimeout = 5;
NSUInteger const CRRequestDefaultMaxHeaderLineLength = 1024;
NSUInteger const CRRequestDefaultMaxHeaderLength = 20 * 1024;
NSUInteger const CRRequestDefaultBodyBufferSize = 8 * 1024 * 1024;

// Keys
NSString* const CRHTTPConnectionReadHeaderLineTimeoutKey = @"CRHTTPConnectionReadHeaderLineTimeout";
NSString* const CRHTTPConnectionReadHeaderTimeoutKey = @"CRHTTPConnectionReadHeaderTimeout";
NSString* const CRHTTPConnectionReadBodyTimeoutKey = @"CRHTTPConnectionReadBodyTimeout";
NSString* const CRHTTPConnectionWriteHeaderTimeoutKey = @"CRHTTPConnectionWriteHeaderTimeout";
NSString* const CRHTTPConnectionWriteBodyTimeoutKey = @"CRHTTPConnectionWriteBodyTimeout";
NSString* const CRHTTPConnectionWriteGeneralTimeoutKey = @"CRHTTPConnectionWriteGeneralTimeout";
NSString* const CRRequestMaxHeaderLineLengthKey = @"CRRequestMaxHeaderLineLength";
NSString* const CRRequestMaxHeaderLengthKey = @"CRRequestMaxHeaderLength";
NSString* const CRRequestBodyBufferSizeKey = @"CRRequestBodyBufferSize";

@implementation CRHTTPServerConfiguration

- (void)readConfiguration {
    [super readConfiguration];

    NSBundle* mainBundle = [NSBundle mainBundle];

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
