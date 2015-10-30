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
#import "CRServerConfiguration.h"
#import "GCDAsyncSocket.h"

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

    //    if ( [self valueForHTTPHeaderField:@"Date"] == nil ) {
    //        [self setValue:[[NSDate date] rfc1123String] forHTTPHeaderField:@"Date"];
    //    }

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
    [self.connection.socket writeData:self.data withTimeout:self.connection.server.configuration.CRHTTPConnectionWriteHeaderTimeout tag:CRHTTPConnectionSocketTagSendingResponse];

    _alreadySentHeaders = YES;
}

- (void)writeData:(NSData *)data closeConnection:(BOOL)flag
{
    [self writeHeaders];
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

    long tag = flag ? CRHTTPConnectionSocketTagFinishSendingResponseAndClosing : CRHTTPConnectionSocketTagFinishSendingResponse;
    [self.connection.socket writeData:data withTimeout:self.connection.server.configuration.CRHTTPConnectionWriteBodyTimeout tag:tag];
}

- (void)sendStatusLine:(BOOL)closeConnection
{
    long tag = closeConnection ? CRHTTPConnectionSocketTagFinishSendingResponseAndClosing : CRHTTPConnectionSocketTagFinishSendingResponse;

    NSMutableData* statusData = [NSMutableData data];
    if ( self.isChunked ) {
        [statusData appendData: [@"0" dataUsingEncoding:NSUTF8StringEncoding]];
        [statusData appendData:[CRConnection CRLFData]];
    }
    [statusData appendData:[CRConnection CRLFData]];
    [self.connection.socket writeData:statusData withTimeout:self.connection.server.configuration.CRHTTPConnectionWriteBodyTimeout tag:tag];
}

- (void)finish {
    [self sendStatusLine:NO];
}

- (void)end {
    [self sendStatusLine:YES];
}

@end
