//
//  CRRequest.h
//  Criollo
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "CRMessage.h"

// Mime types of the requests we support body parsing for
#define CRRequestTypeJSON                   @"application/json"
#define CRRequestTypeURLEncoded             @"application/x-www-form-urlencoded"
#define CRRequestTypeMultipart              @"multipart/form-data"

// Errors
#define CRRequestErrorDomain                @"CRRequestErrorDomain"
//#define CRErrorRequestMalformedRequest      1001
//#define CRErrorRequestUnsupportedMethod     1002
#define CRRequestErrorMalformedBody         3001

@class CRResponse, CRUploadedFile, CRConnection, CRRequestRange;

NS_ASSUME_NONNULL_BEGIN
@interface CRRequest : CRMessage

@property (nonatomic, weak) CRConnection *connection;
@property (nonatomic, strong) CRResponse * response;

@property (nonatomic, readonly) NSURL * URL;
@property (nonatomic, readonly) NSString * method;


@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> * env;
@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> * cookies;
@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> * query;
@property (nonatomic, readonly) id body;
@property (nonatomic, readonly) NSDictionary<NSString *, CRUploadedFile *> * files;

@property (nonatomic, readonly, nullable) CRRequestRange * range;

@end

NS_ASSUME_NONNULL_END