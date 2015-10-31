//
//  CRFCGIRecord.h
//  Criollo
//
//  Created by Cătălin Stan on 10/30/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#define CRFCGIRecordHeaderLength 8

typedef NS_ENUM(UInt8, CRFCGIVersion) {
    CRFCGIVersion1 = 1
};

typedef NS_ENUM(UInt8, CRFCGIRecordType) {
    CRFCGIRecordTypeBeginRequest = 1,
    CRFCGIRecordTypeAbortRequest = 2,
    CRFCGIRecordTypeEndRequest = 3,
    CRFCGIRecordTypeParams = 4,
    CRFCGIRecordTypeStdIn = 5,
    CRFCGIRecordTypeStdOut = 6,
    CRFCGIRecordTypeStdErr = 7,
    CRFCGIRecordTypeData = 8,
    CRFCGIRecordTypeGetValues = 9,
    CRFCGIRecordTypeGetValuesResult = 10,
    CRFCGIRecordTypeUnknown = 11
};

extern NSString* NSStringFromCRFCGIVersion(CRFCGIVersion version);
extern NSString* NSStringFromCRFCGIRecordType(CRFCGIRecordType recordType);

@interface CRFCGIRecord : NSObject

@property (nonatomic, assign) CRFCGIVersion version;
@property (nonatomic, assign) CRFCGIRecordType type;
@property (nonatomic, assign) UInt16 requestID;
@property (nonatomic, assign) UInt16 contentLength;
@property (nonatomic, assign) UInt8 paddingLength;
@property (nonatomic, assign) UInt8 reserved;
@property (nonatomic, strong) NSData* contentData;
@property (nonatomic, strong) NSData* paddingData;

+ (CRFCGIRecord*)recordWithHeaderData:(NSData*)data;

- (instancetype)initWithHeaderData:(NSData*)data NS_DESIGNATED_INITIALIZER;

@end
