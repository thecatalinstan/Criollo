//
//  CRHTTPResponse.m
//  Criollo
//
//  Created by Cătălin Stan on 10/30/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRHTTPResponse.h"

#import <Criollo/CRHTTPServer.h>

#import "CocoaAsyncSocket.h"
#import "CRConnection_Internal.h"
#import "CRHTTPConnection.h"
#import "CRHTTPServerConfiguration.h"
#import "CRMessage_Internal.h"
#import "CRResponse_Internal.h"
#import "NSData+CRLF.h"
#import "NSDate+RFC1123.h"

@interface CRHTTPResponse ()

- (nonnull NSMutableData *)initialResponseData;

@end

@implementation CRHTTPResponse

- (BOOL)isChunked {
    return [[self valueForHTTPHeaderField:@"Transfer-encoding"] isEqualToString:@"chunked"];
}

- (void)buildHeaders {
    if ( self.alreadyBuiltHeaders ) {
        return;
    }

    [self buildStatusLine];

    if ( [self valueForHTTPHeaderField:@"Date"] == nil ) {
        [self setValue:[NSDate date].rfc1123String forHTTPHeaderField:@"Date"];
    }

    if ( [self valueForHTTPHeaderField:@"Content-Type"] == nil ) {
        [self setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    }

    if ( [self valueForHTTPHeaderField:@"Connection"] == nil ) {
        NSString* connectionSpec = @"keep-alive";
        if ( self.version == CRHTTPVersion1_0 ) {
            connectionSpec = @"close";
        }
        [self setValue:connectionSpec forHTTPHeaderField:@"Connection"];
    }

    if ( [self valueForHTTPHeaderField:@"Content-length"] == nil ) {
        [self setValue:@"chunked" forHTTPHeaderField:@"Transfer-encoding"];
    }

    [super buildHeaders];

    self.alreadyBuiltHeaders = YES;
}

- (void)writeData:(NSData *)data finish:(BOOL)flag {
    if ( self.finished ) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Response is already finished" userInfo:nil];
    }

    NSMutableData* dataToSend = [self initialResponseData];

    if ( self.isChunked ) {
        // Chunk size + CRLF
        [dataToSend appendData:[[NSString stringWithFormat:@"%lx", (unsigned long)data.length] dataUsingEncoding:NSUTF8StringEncoding]];
        [dataToSend appendData:NSData.CRLF];
    }

    // The actual data
    [dataToSend appendData:data];
	
    if ( self.isChunked ) {
        // Chunk termination
        [dataToSend appendData: NSData.CRLF];
    }

    if ( flag && self.isChunked ) {
        [dataToSend appendData: [@"0" dataUsingEncoding:NSUTF8StringEncoding]];
        [dataToSend appendData:NSData.CRLFCRLF];
    }

    [super writeData:dataToSend finish:flag];
}

- (void)finish {
    [super finish];

    NSMutableData* dataToSend = [self initialResponseData];
    NSData *terminator;
    if (self.isChunked) {
        terminator = NSData.zeroCRLFCRLF;
    } else {
        terminator = NSData.CRLF;
    }
    [dataToSend appendData:terminator];
    
    [self.connection sendData:dataToSend request:self.request];
}

//TODO: Move to CRResponse
- (NSMutableData*)initialResponseData {
    NSMutableData* dataToSend = [NSMutableData dataWithCapacity:CRResponseDataInitialCapacity];

    if ( !self.alreadySentHeaders ) {
        [self buildHeaders];
        self.bodyData = nil;
        NSData* headersSerializedData = self.serializedData;
        NSData* headerData = [NSMutableData dataWithBytesNoCopy:(void*)headersSerializedData.bytes length:headersSerializedData.length freeWhenDone:NO];
        [dataToSend appendData:headerData];
        self.alreadySentHeaders = YES;
    }

    return dataToSend;
}


@end
