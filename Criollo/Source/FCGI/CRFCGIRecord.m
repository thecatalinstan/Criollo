//
//  CRFCGIRecord.m
//  Criollo
//
//  Created by Cătălin Stan on 10/30/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRFCGIRecord.h"

@interface CRFCGIRecord ()

@property (nonatomic, readonly, copy) NSData *headerProtocolData;

@end

@implementation CRFCGIRecord

+ (instancetype)recordWithHeaderData:(NSData *)headerData {
    return [[CRFCGIRecord alloc] initWithHeaderData:headerData];
}

- (instancetype)init {
    return [self initWithHeaderData:nil];
}

- (instancetype)initWithHeaderData:(NSData *)data {
    self = [super init];
    if ( self != nil ) {
        if ( data != nil ) {
            self.version = (CRFCGIVersion) [data subdataWithRange:NSMakeRange(0, 1)].bytes;
            self.type = (CRFCGIRecordType) [data subdataWithRange:NSMakeRange(1, 1)].bytes;
            self.requestID = CFSwapInt16BigToHost( (UInt16) [data subdataWithRange:NSMakeRange(2, 2)].bytes);
            self.contentLength = CFSwapInt16BigToHost( (UInt16) [data subdataWithRange:NSMakeRange(4, 2)].bytes);
            self.paddingLength = (UInt8) [data subdataWithRange:NSMakeRange(6, 1)].bytes;
            self.reserved = 0x00;
        }
    }
    return self;
}

- (void)processContentData:(NSData *)data {

}

@end
