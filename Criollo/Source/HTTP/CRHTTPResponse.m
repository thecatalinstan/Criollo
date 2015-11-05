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
    BOOL _alreadyBuiltHeaders;
}

@end

@implementation CRHTTPResponse

- (BOOL)isChunked {
    return [[self valueForHTTPHeaderField:@"Transfer-encoding"] isEqualToString:@"chunked"];
}

- (void)buildHeaders
{
    if ( _alreadyBuiltHeaders ) {
        return;
    }

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

    _alreadyBuiltHeaders = YES;
}

- (void)writeData:(NSData *)data finish:(BOOL)flag
{
    CRHTTPServerConfiguration* config = (CRHTTPServerConfiguration*)self.connection.server.configuration;

    NSMutableData* dataToSend = [NSMutableData dataWithCapacity:1024];

    if ( !_alreadySentHeaders ) {
        [self buildHeaders];
        [self setBody:nil];
        NSData* headersSerializedData = self.serializedData;
        NSData* headerData = [NSData dataWithBytesNoCopy:(void*)headersSerializedData.bytes length:headersSerializedData.length freeWhenDone:NO];
        [dataToSend appendData:headerData];
        _alreadySentHeaders = YES;
    }

    if ( self.isChunked ) {
        // Chunk size + CRLF
        [dataToSend appendData: [[NSString stringWithFormat:@"%lx", data.length] dataUsingEncoding:NSUTF8StringEncoding]];
        [dataToSend appendData: [CRConnection CRLFData]];
    }

    // The actual data
    [dataToSend appendData:data];
	
    if ( self.isChunked ) {
				// Chunk termination
        [dataToSend appendData: [CRConnection CRLFData]];
    }

    if ( flag && self.isChunked ) {
        [dataToSend appendData: [@"0" dataUsingEncoding:NSUTF8StringEncoding]];
        [dataToSend appendData:[CRConnection CRLFCRLFData]];
    }

    long tag = flag ? CRConnectionSocketTagFinishSendingResponse : CRConnectionSocketTagSendingResponse;
    [self.connection.socket writeData:dataToSend withTimeout:config.CRHTTPConnectionWriteBodyTimeout tag:tag];
}

- (void)finish {
    CRHTTPServerConfiguration* config = (CRHTTPServerConfiguration*)self.connection.server.configuration;

    NSMutableData* dataToSend = [NSMutableData dataWithCapacity:1024];

    if ( !_alreadySentHeaders ) {
        [self buildHeaders];
        [self setBody:nil];
        NSData* headersSerializedData = self.serializedData;
        NSData* headerData = [NSMutableData dataWithBytesNoCopy:(void*)headersSerializedData.bytes length:headersSerializedData.length freeWhenDone:NO];
        [dataToSend appendData:headerData];
        _alreadySentHeaders = YES;
    }

    if ( self.isChunked ) {
        [dataToSend appendData: [@"0\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    } else {
        [dataToSend appendData: [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }

    [self.connection.socket writeData:dataToSend withTimeout:config.CRHTTPConnectionWriteBodyTimeout tag:CRConnectionSocketTagFinishSendingResponse];
}


@end