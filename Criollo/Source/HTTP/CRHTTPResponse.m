//
//  CRHTTPResponse.m
//  Criollo
//
//  Created by Cătălin Stan on 10/30/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRHTTPResponse.h"
#import "CRHTTPConnection.h"
#import "CRHTTPServer.h"
#import "CRHTTPServerConfiguration.h"
#import "GCDAsyncSocket.h"
#import "NSDate+RFC1123.h"

@interface CRHTTPResponse () {
    BOOL _alreadySentHeaders;
}

- (void)sendStatusLine:(BOOL)closeConnection;

@end

@implementation CRHTTPResponse

- (BOOL)isChunked {
    return [[self valueForHTTPHeaderField:@"Transfer-encoding"] isEqualToString:@"chunked"];
}

- (void)writeHeaders
{
    if ( _alreadySentHeaders ) {
        return;
    }

    CRHTTPServerConfiguration* config = (CRHTTPServerConfiguration*)self.connection.server.configuration;

    if ( [self valueForHTTPHeaderField:@"Date"] == nil ) {
        [self setValue:[NSDate date].rfc1123String forHTTPHeaderField:@"Date"];
    }

    if ( [self valueForHTTPHeaderField:@"Content-Type"] == nil ) {
        [self setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    }

    if ( [self valueForHTTPHeaderField:@"Connection"] == nil ) {
        NSString* connectionHeader = @"keep-alive";
        if ( [self.version isEqualToString:CRHTTP10] ) {
            connectionHeader = @"close";
        }
        [self setValue:connectionHeader forHTTPHeaderField:@"Connection"];
    }

    if ( [self valueForHTTPHeaderField:@"Content-length"] == nil ) {
        [self setValue:@"chunked" forHTTPHeaderField:@"Transfer-encoding"];
    }

    [self setBody:nil];
    [self.connection.socket writeData:self.data withTimeout:config.CRHTTPConnectionWriteHeaderTimeout tag:CRHTTPConnectionSocketTagSendingResponse];

    _alreadySentHeaders = YES;
}

- (void)writeData:(NSData *)data finish:(BOOL)flag
{
    [self writeHeaders];

    CRHTTPServerConfiguration* config = (CRHTTPServerConfiguration*)self.connection.server.configuration;

    if ( self.isChunked ) {
        NSMutableData* chunkedData = [NSMutableData data];

        // Chunk size + CRLF
        [chunkedData appendData: [[NSString stringWithFormat:@"%lx", data.length] dataUsingEncoding:NSUTF8StringEncoding]];
        [chunkedData appendData: [CRConnection CRLFData]];

        // The actual data
        [chunkedData appendData:data];
        [chunkedData appendData: [CRConnection CRLFData]];

        data = chunkedData;
    }

    [self.connection.socket writeData:data withTimeout:config.CRHTTPConnectionWriteBodyTimeout tag:CRHTTPConnectionSocketTagSendingResponse];
    if ( flag ) {
        [self finish];
    }
}

- (void)sendStatusLine:(BOOL)closeConnection
{
    CRHTTPServerConfiguration* config = (CRHTTPServerConfiguration*)self.connection.server.configuration;

    long tag = closeConnection ? CRConnectionSocketTagFinishSendingResponseAndClosing : CRConnectionSocketTagFinishSendingResponse;

    NSMutableData* statusData = [NSMutableData data];
    if ( self.isChunked ) {
        [statusData appendData: [@"0" dataUsingEncoding:NSUTF8StringEncoding]];
        [statusData appendData:[CRConnection CRLFData]];
    }
    [statusData appendData:[CRConnection CRLFData]];
    [self.connection.socket writeData:statusData withTimeout:config.CRHTTPConnectionWriteBodyTimeout tag:tag];
}

- (void)finish {
    [self writeHeaders];
    [self sendStatusLine:NO];
}

- (void)end {
    [self writeHeaders];
    [self sendStatusLine:YES];
}

@end
