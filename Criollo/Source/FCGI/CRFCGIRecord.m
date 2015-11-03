//
//  CRFCGIRecord.m
//  Criollo
//
//  Created by Cătălin Stan on 10/30/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRFCGIRecord.h"

NSString* NSStringFromCRFCGIVersion(CRFCGIVersion version) {
    NSString* versionName;
    switch (version) {
        case CRFCGIVersion1:
            versionName = @"CRFCGIVersion1";
            break;
    }
    return versionName;
}

NSString* NSStringFromCRFCGIRecordType(CRFCGIRecordType recordType) {
    NSString* recordTypeName;
    switch (recordType) {
        case CRFCGIRecordTypeBeginRequest:
            recordTypeName = @"CRFCGIRecordTypeBeginRequest";
            break;
        case CRFCGIRecordTypeAbortRequest:
            recordTypeName = @"CRFCGIRecordTypeAbortRequest";
            break;
        case CRFCGIRecordTypeEndRequest:
            recordTypeName = @"CRFCGIRecordTypeEndRequest";
            break;
        case CRFCGIRecordTypeParams:
            recordTypeName = @"CRFCGIRecordTypeParams";
            break;
        case CRFCGIRecordTypeStdIn:
            recordTypeName = @"CRFCGIRecordTypeStdIn";
            break;
        case CRFCGIRecordTypeStdOut:
            recordTypeName = @"CRFCGIRecordTypeStdOut";
            break;
        case CRFCGIRecordTypeStdErr:
            recordTypeName = @"CRFCGIRecordTypeStdErr";
            break;
        case CRFCGIRecordTypeData:
            recordTypeName = @"CRFCGIRecordTypeData";
            break;
        case CRFCGIRecordTypeGetValues:
            recordTypeName = @"CRFCGIRecordTypeGetValues";
            break;
        case CRFCGIRecordTypeGetValuesResult:
            recordTypeName = @"CRFCGIRecordTypeGetValuesResult";
            break;
        case CRFCGIRecordTypeUnknown:
            recordTypeName = @"CRFCGIRecordTypeUnknown";
            break;
    }
    return recordTypeName;
}

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
            [data getBytes:&_version range:NSMakeRange(0, 1)];
            [data getBytes:&_type range:NSMakeRange(1, 1)];

            [data getBytes:&_requestID range:NSMakeRange(2, 2)];
            _requestID = CFSwapInt16BigToHost(_requestID);

            [data getBytes:&_contentLength range:NSMakeRange(4, 2)];
            _contentLength = CFSwapInt16BigToHost(_contentLength);

            [data getBytes:&_paddingLength range:NSMakeRange(6, 1)];

            _reserved = 0x00;
        }
    }
    return self;
}


@end
