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

@interface CRRequest : CRMessage

@property (nonatomic, weak) CRConnection *connection;
@property (nonatomic, strong, nonnull) CRResponse * response;

@property (nonatomic, readonly, nonnull) NSURL * URL;
@property (nonatomic, readonly, nonnull) NSString * method;


@property (nonatomic, readonly, nonnull) NSDictionary<NSString *, NSString *> * env;
@property (nonatomic, readonly, nonnull) NSDictionary<NSString *, NSString *> * cookies;
@property (nonatomic, readonly, nonnull) NSDictionary<NSString *, NSString *> * query;
@property (nonatomic, readonly, nonnull) id body;
@property (nonatomic, readonly, nonnull) NSDictionary<NSString *, CRUploadedFile *> * files;

@property (nonatomic, readonly, nullable) CRRequestRange * range;

@end
