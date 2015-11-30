//
//  CRRequest.h
//  Criollo
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "CRMessage.h"

#define CRErrorRequestMalformedRequest      3001
#define CRErrorRequestUnsupportedMethod     3002

@class CRResponse;

@interface CRRequest : CRMessage

@property (nonatomic, strong, nonnull) CRResponse *response;

@property (nonatomic, readonly, nonnull) NSURL *URL;
@property (nonatomic, readonly, nonnull) NSString *method;
@property (nonatomic, readonly, nonnull) NSDictionary<NSString *, NSString *> *env;
@property (nonatomic, readonly, nonnull) NSDictionary<NSString *, NSString *> *cookie;
@property (nonatomic, readonly, nonnull) NSDictionary<NSString *, NSString *> *query;

@end
