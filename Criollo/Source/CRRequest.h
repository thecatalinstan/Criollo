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
//#define CRRequestTypeXML                    @"application/xml"
#define CRRequestTypeURLEncoded             @"application/x-www-form-urlencoded"
#define CRRequestTypeMultipart              @"multipart/form-data"

// Errors
#define CRRequestErrorDomain                @"CRRequestErrorDomain"
//#define CRErrorRequestMalformedRequest      1001
//#define CRErrorRequestUnsupportedMethod     1002
#define CRRequestErrorMalformedBody         3001

@class CRResponse;

@interface CRRequest : CRMessage

@property (nonatomic, strong, nonnull) CRResponse *response;

@property (nonatomic, readonly, nonnull) NSURL *URL;
@property (nonatomic, readonly, nonnull) NSString *method;

@property (nonatomic, readonly, nonnull) NSDictionary<NSString *, NSString *> *env;
@property (nonatomic, readonly, nonnull) NSDictionary<NSString *, NSString *> *cookie;
@property (nonatomic, readonly, nonnull) NSDictionary<NSString *, NSString *> *query;
@property (nonatomic, readonly, nonnull) id body;

@end
