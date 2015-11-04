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
    BOOL didBuildHeaders;
}

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

- (BOOL)appendData:(NSData*)data {
    if ( !didBuildHeaders ) {
        [self buildHeaders];
    }

    BOOL result = YES;
    result = result && [super appendData:data];
    return result;
}

- (void)buildHeaders {
    if ( didBuildHeaders ) {
        return;
    }

    if ( [self valueForHTTPHeaderField:@"Content-Type"] == nil ) {
        [self setValue:@"text/plain; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    }

    didBuildHeaders = YES;
}

- (void)writeDataToSocketWithTag:(long)tag {

    NSData* responseData = self.serializedData;
    NSMutableData* recordData = [NSMutableData data];
    CRFCGIServerConfiguration* config = (CRFCGIServerConfiguration*)self.connection.server.configuration;

    NSUInteger offset = 0;
    do {
        NSUInteger chunkSize = responseData.length - offset > config.CRFCGIConnectionSocketWriteBuffer ? config.CRFCGIConnectionSocketWriteBuffer : responseData.length - offset;

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

        NSData* chunk = [NSData dataWithBytesNoCopy:((char *)responseData.bytes + offset) length:chunkSize freeWhenDone:NO];
        [recordData appendData:chunk];

        offset += chunkSize;
        
    } while (offset < responseData.length);

    // Append the end request record
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

    [self.connection.socket writeData:recordData withTimeout:config.CRFCGIConnectionWriteRecordTimeout tag:tag];
}


@end
