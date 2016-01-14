//
//  CRResponse_Internal.h
//  Criollo
//
//  Created by Cătălin Stan on 11/20/15.
//  Copyright © 2015 Cătălin Stan. All rights reserved.
//

#import "CRResponse.h"

@class CRConnection;

@interface CRResponse ()

@property (nonatomic, weak) CRConnection *connection;

@property (nonatomic, assign) NSUInteger proposedStatusCode;
@property (nonatomic, strong, nullable) NSString* proposedStatusDescription;

@property (nonatomic, assign) BOOL alreadySentHeaders;
@property (nonatomic, assign) BOOL alreadyBuiltHeaders;
@property (nonatomic, readonly) BOOL finished;

- (nonnull instancetype)initWithConnection:(nullable CRConnection *)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode;
- (nonnull instancetype)initWithConnection:(nullable CRConnection *)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode description:(nullable NSString *)description;
- (nonnull instancetype)initWithConnection:(nullable CRConnection *)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode description:(nullable NSString *)description version:(nullable NSString *)version NS_DESIGNATED_INITIALIZER;

- (void)writeData:(nullable NSData*)data finish:(BOOL)flag;

- (void)buildStatusLine;
- (void)buildHeaders;

@end
