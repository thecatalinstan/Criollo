//
//  CRFCGIResponse.m
//  Criollo
//
//  Created by Cătălin Stan on 10/30/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRFCGIResponse.h"
#import "CRApplication.h"
#import "CRFCGIServer.h"
#import "CRFCGIServerConfiguration.h"
#import "CRFCGIConnection.h"
#import "CRFCGIRequest.h"
#import "CRFCGIRecord.h"
#import "GCDAsyncSocket.h"

NSString* NSStringFromCRFCGIProtocolStatus(CRFCGIProtocolStatus protocolStatus) {
    NSString* protocolStatusName;
    switch (protocolStatus) {
        case CRFCGIProtocolStatusRequestComplete:
            protocolStatusName = @"CRFCGIProtocolStatusRequestComplete";
            break;

        case CRFCGIProtocolStatusCannotMultiplexConnection:
            protocolStatusName = @"CRFCGIProtocolStatusCannotMultiplexConnection";
            break;

        case CRFCGIProtocolStatusOverloaded:
            protocolStatusName = @"CRFCGIProtocolStatusOverloaded";
            break;

        case CRFCGIProtocolStatusUnknownRole:
            protocolStatusName = @"CRFCGIProtocolStatusUnknownRole";
            break;
    }
    return protocolStatusName;
}

@interface CRFCGIResponse () {
    BOOL _alreadySentHeaders;
}

- (void)sendEndResponseRecord:(BOOL)closeConnection;
- (void)writeFCGIData:(NSData *)data withTag:(long)tag;

@end

@implementation CRFCGIResponse

- (instancetype)initWithConnection:(CRConnection *)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString *)description version:(NSString *)version {
    self = [super initWithConnection:connection HTTPStatusCode:HTTPStatusCode description:description version:version];
    if ( self != nil ) {
        self.protocolStatus = CRFCGIProtocolStatusRequestComplete;
        self.applicationStatus = 0;
    }
    return self;
}

- (void)writeHeaders {
    if ( _alreadySentHeaders ) {
        return;
    }

    if ( [self valueForHTTPHeaderField:@"Content-Type"] == nil ) {
        [self setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    }

    [self setBody:nil];
    [self writeFCGIData:self.data withTag:CRFCGIConnectionSocketTagSendingResponse];

    _alreadySentHeaders = YES;
}

- (void)writeData:(NSData *)data finish:(BOOL)flag {

    [self writeHeaders];

    [self writeFCGIData:data withTag:CRFCGIConnectionSocketTagSendingResponse];

    if ( flag ) {
        [self finish];
    }
}

- (void)sendEndResponseRecord:(BOOL)closeConnection {

    CRFCGIServerConfiguration* config = (CRFCGIServerConfiguration*)self.connection.server.configuration;

    NSMutableData* recordData = [NSMutableData data];

    CRFCGIVersion version = CRFCGIVersion1;
    [recordData appendBytes:&version length:1];

    CRFCGIRecordType type = CRFCGIRecordTypeEndRequest;
    [recordData appendBytes:&type length:1];

    UInt16 requestID = CFSwapInt16HostToBig(((CRFCGIRequest*)self.connection.request).requestID);
    [recordData appendBytes:&requestID length:2];

    UInt16 contentLength = CFSwapInt16HostToBig(8);
    [recordData appendBytes:&contentLength length:2];

    UInt8 paddingLength = 0;
    [recordData appendBytes:&paddingLength length:1];

    UInt8 reserved = 0x00;
    [recordData appendBytes:&reserved length:1];

    CRFCGIApplicationStatus applicationStatus = CFSwapInt32HostToBig(self.applicationStatus);
    [recordData appendBytes:&applicationStatus length:4];

    CRFCGIProtocolStatus protocolStatus = self.protocolStatus;
    [recordData appendBytes:&protocolStatus length:1];

    // Pad the record to 8 bytes
    [recordData appendBytes:&reserved length:1];
    [recordData appendBytes:&reserved length:1];
    [recordData appendBytes:&reserved length:1];

    long tag = closeConnection ? CRConnectionSocketTagFinishSendingResponseAndClosing : CRConnectionSocketTagFinishSendingResponse;

    [self.connection.socket writeData:recordData withTimeout:config.CRFCGIConnectionWriteRecordTimeout tag:tag];
}

- (void)finish {
    [self writeHeaders];
    [self sendEndResponseRecord:NO];
}

- (void)end {
    [self writeHeaders];
    [self sendEndResponseRecord:YES];
}

- (void)writeFCGIData:(NSData *)data withTag:(long)tag {

    CRFCGIServerConfiguration* config = (CRFCGIServerConfiguration*)self.connection.server.configuration;

    NSUInteger offset = 0;

    do {
        NSUInteger chunkSize = data.length - offset > config.CRFCGIConnectionSocketWriteBuffer ? config.CRFCGIConnectionSocketWriteBuffer : data.length - offset;

        NSMutableData* recordData = [NSMutableData data];

        CRFCGIVersion version = CRFCGIVersion1;
        [recordData appendBytes:&version length:1];

        CRFCGIRecordType type = CRFCGIRecordTypeStdOut;
        [recordData appendBytes:&type length:1];

        UInt16 requestID = CFSwapInt16HostToBig(((CRFCGIRequest*)self.connection.request).requestID);
        [recordData appendBytes:&requestID length:2];

        UInt16 contentLength = CFSwapInt16HostToBig(chunkSize);
        [recordData appendBytes:&contentLength length:2];

        UInt8 paddingLength = 0;
        [recordData appendBytes:&paddingLength length:1];

        UInt8 reserved = 0x00;
        [recordData appendBytes:&reserved length:1];

        NSData* chunk = [NSData dataWithBytesNoCopy:((char *)data.bytes + offset) length:chunkSize freeWhenDone:NO];
        [recordData appendData:chunk];

        [self.connection.socket writeData:recordData withTimeout:config.CRFCGIConnectionWriteRecordTimeout tag:tag];
        
        offset += chunkSize;
        
    } while (offset < data.length);
    
}


@end
