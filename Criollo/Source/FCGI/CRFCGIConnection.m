//
//  CRFCGIConnection.m
//  Criollo
//
//  Created by Cătălin Stan on 10/25/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRFCGIConnection.h"
#import "GCDAsyncSocket.h"
#import "CRApplication.h"
#import "CRServer.h"
#import "CRServerConfiguration.h"
#import "CRRequest.h"
#import "CRResponse.h"

@implementation CRFCGIConnection

#pragma mark - Data

- (void)startReading {
    // Read the first request header
    NSUInteger timeout = (didPerformInitialRead ? self.server.configuration.CRHTTPConnectionKeepAliveTimeout : self.server.configuration.CRConnectionInitialReadTimeout) + self.server.configuration.CRHTTPConnectionReadHeaderLineTimeout;
    [self.socket readDataToData:[CRConnection CRLFData] withTimeout:timeout maxLength:self.server.configuration.CRRequestMaxHeaderLineLength tag:CRSocketTagBeginReadingRequest];

    [newSocket readDataToLength:FCGIRecordFixedLengthPartLength withTimeout:FCGITimeout tag:FCGIRecordAwaitingHeaderTag];
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag {
    NSLog(@"%s %lu bytes", __PRETTY_FUNCTION__, data.length);
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

@end
