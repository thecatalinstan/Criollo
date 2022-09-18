//
//  CRRequest_Internal.h
//
//
//  Created by Cătălin Stan on 11/20/15.
//

#import <Criollo/CRHTTPVersion.h>
#import <Criollo/CRRequest.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const CRRequestHeaderNameSeparator;
FOUNDATION_EXPORT NSString * const CRRequestHeaderSeparator;
FOUNDATION_EXPORT NSString * const CRRequestHeaderArraySeparator;
FOUNDATION_EXPORT NSString * const CRRequestKeySeparator;
FOUNDATION_EXPORT NSString * const CRRequestValueSeparator;
FOUNDATION_EXPORT NSString * const CRRequestBoundaryParameter;
FOUNDATION_EXPORT NSString * const CRRequestBoundaryPrefix;

@interface CRRequest ()

@property (nonatomic, readonly, weak, nullable) CRConnection *connection;
@property (nonatomic, nullable) CRResponse *response;

@property (nonatomic, readwrite) NSDictionary<NSString *, NSString *> *env;

@property (nonatomic, readonly) BOOL shouldCloseConnection;

@property (nonatomic, nullable) NSMutableData *bufferedBodyData;
@property (nonatomic, nullable) NSMutableData *bufferedResponseData;

@property (nonatomic, readonly, nullable) NSString *multipartBoundary;
@property (nonatomic, readonly) NSData * multipartBoundaryPrefixData;
@property (nonatomic, readonly, nullable) NSString * multipartBoundaryPrefixedString;
@property (nonatomic, readonly, nullable) NSData * multipartBoundaryPrefixedData;

- (instancetype)initWithMethod:(CRHTTPMethod)method URL:(NSURL * _Nullable)URL version:(CRHTTPVersion)version connection:(CRConnection* _Nullable)connection env:(NSDictionary* _Nullable)env NS_DESIGNATED_INITIALIZER;

- (BOOL)appendData:(NSData *)data;
- (void)bufferBodyData:(NSData *)data;
- (void)bufferResponseData:(NSData *)data;

- (void)clearBodyParsingTargets;

- (BOOL)appendBodyData:(NSData *)data forKey:(NSString *)key;
- (BOOL)setFileHeader:(NSDictionary *)headerFields forKey:(NSString *)key;
- (BOOL)appendFileData:(NSData *)data forKey:(NSString *)key;

- (void)parseQueryString;
- (void)parseCookiesHeader;
- (void)parseRangeHeader;

- (void)setEnv:(NSString *)obj forKey:(NSString *)key;

- (void)setQuery:(NSString *)obj forKey:(NSString *)key;

- (BOOL)parseJSONBodyData:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (BOOL)parseMIMEBodyDataChunk:(NSData *)data error:(NSError *__autoreleasing  _Nullable * _Nullable)error;
- (BOOL)parseMultipartBodyDataChunk:(NSData *)data error:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (BOOL)parseURLEncodedBodyData:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (BOOL)parseBufferedBodyData:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
