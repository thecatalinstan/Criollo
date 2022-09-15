//
//  CRResponse.h
//
//
//  Created by Cătălin Stan on 3/30/14.
//

#import <Criollo/CRMessage.h>

@class CRRequest, CRConnection;

NS_ASSUME_NONNULL_BEGIN

@interface CRResponse : CRMessage

@property (nonatomic, weak, nullable) CRConnection *connection;
@property (nonatomic, weak, nullable) CRRequest *request;

@property (nonatomic, readonly) NSUInteger statusCode;
@property (nonatomic, strong, readonly, nullable) NSString* statusDescription;

- (void)setStatusCode:(NSUInteger)statusCode description:(NSString * _Nullable)description;

- (void)setAllHTTPHeaderFields:(NSDictionary<NSString *, NSString *> *)headerFields;
- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)HTTPHeaderField;
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)HTTPHeaderField;

- (void)setCookie:(NSHTTPCookie *)cookie;
- (NSHTTPCookie *)setCookie:(NSString *)name value:(NSString *)value path:(NSString *)path expires:(NSDate * _Nullable)expires domain:(NSString * _Nullable)domain secure:(BOOL)secure;

- (NSData *)serializeOutputObject:(id)obj error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (void)write:(id)obj;
- (void)writeData:(NSData *)data;
- (void)writeString:(NSString *)string;
- (void)writeFormat:(NSString *)format, ...;
- (void)writeFormat:(NSString *)format args:(va_list)args;

- (void)send:(id)obj;
- (void)sendData:(NSData *)data;
- (void)sendString:(NSString *)string;
- (void)sendFormat:(NSString *)format, ...;
- (void)sendFormat:(NSString *)format args:(va_list)args;

- (void)redirectToURL:(NSURL *)URL;
- (void)redirectToURL:(NSURL *)URL statusCode:(NSUInteger)statusCode;
- (void)redirectToURL:(NSURL *)URL statusCode:(NSUInteger)statusCode finish:(BOOL)finish;

- (void)redirectToLocation:(NSString *)location;
- (void)redirectToLocation:(NSString *)location statusCode:(NSUInteger)statusCode;
- (void)redirectToLocation:(NSString *)location statusCode:(NSUInteger)statusCode finish:(BOOL)finish;

- (void)finish;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
