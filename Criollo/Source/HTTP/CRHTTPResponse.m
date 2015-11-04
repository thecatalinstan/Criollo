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
    BOOL didBuildHeaders;
}

@end

@implementation CRHTTPResponse

- (BOOL)isChunked {
    return [[self valueForHTTPHeaderField:@"Transfer-encoding"] isEqualToString:@"chunked"];
}

- (BOOL)appendData:(NSData*)data {
    if ( !didBuildHeaders ) {
        [self buildHeaders];
    }

    BOOL result = YES;

    if ( self.isChunked ) {
        // Chunk size + CRLF
        result = result && [super appendData: [[NSString stringWithFormat:@"%lx", data.length] dataUsingEncoding:NSUTF8StringEncoding]];
        result = result && [super appendData: [CRConnection CRLFData]];

        // The actual data
        result = result && [super appendData:data];
        result = result && [super appendData: [CRConnection CRLFData]];
    } else {
        // Append the actual data;
        result = result && [super appendData:data];
    }

    return result;
}

- (void)buildHeaders {

    if ( didBuildHeaders ) {
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

    didBuildHeaders = YES;
}

- (void)writeDataToSocketWithTag:(long)tag {

    // Append end resonse footer
    if ( self.isChunked ) {
        [super appendData: [@"0" dataUsingEncoding:NSUTF8StringEncoding]];
        [super appendData:[CRConnection CRLFData]];
        [super appendData:[CRConnection CRLFData]];
    }

    CRHTTPServerConfiguration* config = (CRHTTPServerConfiguration*)self.connection.server.configuration;
    [self.connection.socket writeData:self.serializedData withTimeout:config.CRHTTPConnectionWriteBodyTimeout tag:tag];
}


@end
