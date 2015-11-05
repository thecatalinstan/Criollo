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

@interface CRFCGIResponse ()  {
    BOOL _alreadySentHeaders;
    BOOL _alreadyBuiltHeaders;
}

@property (nonatomic, readonly) NSData* endRequestRecordData;

- (NSData*)FCGIRecordDataWithContentData:(NSData *)data;

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

- (void)buildHeaders {
    if ( _alreadyBuiltHeaders ) {
        return;
    }

    if ( [self valueForHTTPHeaderField:@"Content-Type"] == nil ) {
        [self setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    }

    _alreadyBuiltHeaders = YES;
}

- (void)writeData:(NSData *)data finish:(BOOL)flag {

    CRFCGIServerConfiguration* config = (CRFCGIServerConfiguration*)self.connection.server.configuration;

    NSMutableData* dataToSend = [NSMutableData dataWithCapacity:1024];

    if ( !_alreadySentHeaders ) {
        [self buildHeaders];
        [self setBody:nil];
        NSData* headersSerializedData = self.serializedData;
        NSData* headerData = [self FCGIRecordDataWithContentData:[NSData dataWithBytesNoCopy:(void*)headersSerializedData.bytes length:headersSerializedData.length freeWhenDone:NO]];
        [dataToSend appendData:headerData];
        _alreadySentHeaders = YES;
    }

    // The actual data
    [dataToSend appendData:[self FCGIRecordDataWithContentData:data]];

    if ( flag ) {
        // End request record
        [dataToSend appendData:self.endRequestRecordData];
    }

    long tag = flag ? CRConnectionSocketTagFinishSendingResponse : CRConnectionSocketTagSendingResponse;
    [self.connection.socket writeData:dataToSend withTimeout:config.CRFCGIConnectionWriteRecordTimeout tag:tag];
}

- (void)finish {
    CRFCGIServerConfiguration* config = (CRFCGIServerConfiguration*)self.connection.server.configuration;

    NSMutableData* dataToSend = [NSMutableData dataWithCapacity:1024];

    if ( !_alreadySentHeaders ) {
        [self buildHeaders];
        [self setBody:nil];
        NSData* headersSerializedData = self.serializedData;
        NSData* headerData = [self FCGIRecordDataWithContentData:[NSData dataWithBytesNoCopy:(void*)headersSerializedData.bytes length:headersSerializedData.length freeWhenDone:NO]];
        [dataToSend appendData:headerData];
        _alreadySentHeaders = YES;
    }

    // End request record
    [dataToSend appendData:self.endRequestRecordData];

    [self.connection.socket writeData:dataToSend withTimeout:config.CRFCGIConnectionWriteRecordTimeout tag:CRConnectionSocketTagFinishSendingResponse];
}

- (NSData*)FCGIRecordDataWithContentData:(NSData *)data {

    CRFCGIServerConfiguration* config = (CRFCGIServerConfiguration*)self.connection.server.configuration;

    NSMutableData* recordData = [NSMutableData dataWithCapacity:config.CRFCGIConnectionSocketWriteBuffer];
    NSUInteger offset = 0;

    do {
        NSUInteger chunkSize = data.length - offset > config.CRFCGIConnectionSocketWriteBuffer ? config.CRFCGIConnectionSocketWriteBuffer : data.length - offset;


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

        offset += chunkSize;
        
    } while (offset < data.length);

    return recordData;
    
}

- (NSData*)endRequestRecordData {

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

    return recordData;
}


@end
