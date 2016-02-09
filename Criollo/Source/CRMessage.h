//
//  CRMessage.h
//  Criollo
//
//  Created by Cătălin Stan on 29/04/15.
//
//

// HTTP Versions
#define CRHTTP10  ((NSString *)kCFHTTPVersion1_0)
#define CRHTTP11  ((NSString *)kCFHTTPVersion1_1)

@interface CRMessage : NSObject

@property (nonatomic, readonly, nonnull) NSString* version;
@property (nonatomic, readonly, nonnull) NSDictionary<NSString*, NSString*>* allHTTPHeaderFields;

@property (nonatomic, copy, nullable) NSData* bodyData;

- (nullable NSString *)valueForHTTPHeaderField:(nonnull NSString *)HTTPHeaderField;

@end
