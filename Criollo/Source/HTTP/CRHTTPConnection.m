//
//  CRHTTPConnection.m
//  Criollo
//
//  Created by Cătălin Stan on 10/25/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRHTTPConnection.h"
#import "GCDAsyncSocket.h"
#import "CRServer.h"
#import "CRServerConfiguration.h"

#define CRSocketTagBeginReadingRequest                  10
#define CRSocketTagReadingRequestHeader                 11
#define CRSocketTagReadingRequestBody                   12

#define CRSocketTagSendingResponse                      20
#define CRSocketTagSendingResponseHeaders               21
#define CRSocketTagSendingResponseBody                  22

#define CRSocketTagFinishSendingResponse                90
#define CRSocketTagFinishSendingResponseAndClosing      91

@implementation CRHTTPConnection

#pragma mark - Data

- (void)startReading {
//    [self.socket readDataToData:[CRConnection CRLFCRLFData] withTimeout:self.server.configuration.CRConnectionInitialReadTimeout maxLength:self.server.configuration.CRRequestMaxHeaderLineLength tag:CRSocketTagBeginReadingRequest];
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag {
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
}

@end
