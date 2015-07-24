//
//  CRHTTPRequest.h
//  Criollo
//
//  Created by Cătălin Stan on 3/30/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Criollo/CRHTTPMessage.h>

@interface CRHTTPRequest : CRHTTPMessage

@property (nonatomic, readonly) NSURL* URL;
@property (atomic, readonly) NSString* method;
@property (atomic, readonly) BOOL headerComplete;

- (instancetype)initWithMethod:(NSString *)method URL:(NSURL *)URL version:(NSString *)version NS_DESIGNATED_INITIALIZER;

- (BOOL)appendData:(NSData *)data;

@end
