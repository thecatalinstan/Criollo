//
//  CRFCGIServerConfiguration.m
//  Criollo
//
//  Created by Cătălin Stan on 10/30/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRFCGIServerConfiguration.h"

// Defaults
NSUInteger const CRFCGIConnectionDefaultReadRecordTimeout = 5;

// Keys
NSString* const CRFCGIConnectionReadRecordTimeoutKey = @"CRFCGIConnectionReadRecordTimeout";

@implementation CRFCGIServerConfiguration

- (void)readConfiguration {

    [super readConfiguration];

    NSBundle* mainBundle = [NSBundle mainBundle];

    if ( [mainBundle objectForInfoDictionaryKey:CRFCGIConnectionReadRecordTimeoutKey] ) {
        self.CRFCGIConnectionReadRecordTimeout = [[mainBundle objectForInfoDictionaryKey:CRFCGIConnectionReadRecordTimeoutKey] integerValue];
    } else {
        self.CRFCGIConnectionReadRecordTimeout = CRFCGIConnectionDefaultReadRecordTimeout;
    }

}


@end
