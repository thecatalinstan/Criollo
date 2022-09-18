//
//  CRResponse_Internal.h
//
//
//  Created by Cătălin Stan on 11/20/15.
//

#import <Criollo/CRResponse.h>

/// Initial size of the response body data object
FOUNDATION_EXPORT NSUInteger const CRResponseDataInitialCapacity;

NS_ASSUME_NONNULL_BEGIN

@interface CRResponse ()

@property (nonatomic, weak, nullable) CRConnection *connection;
@property (nonatomic, weak, nullable) CRRequest *request;
- (NSData *)serializeOutputObject:(id)obj error:(NSError * _Nullable __autoreleasing * _Nullable)error;

@property (nonatomic) NSUInteger proposedStatusCode;
@property (nonatomic, nullable) NSString* proposedStatusDescription;

@property BOOL alreadySentHeaders;
@property BOOL alreadyBuiltHeaders;
@property (readonly) BOOL finished;
@property (readonly) BOOL hasWrittenBodyData;

- (instancetype)initWithConnection:(CRConnection *)connection HTTPStatusCode:(NSUInteger)HTTPStatusCode description:(NSString * _Nullable)description version:(CRHTTPVersion)version NS_DESIGNATED_INITIALIZER;

- (void)writeData:(NSData *)data finish:(BOOL)flag;

- (void)buildStatusLine;
- (void)buildHeaders;

@end

NS_ASSUME_NONNULL_END
