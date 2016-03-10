//
//  CRMessage.h
//  Criollo
//
//  Created by Cătălin Stan on 29/04/15.
//
//

#import "CRTypes.h"

// HTTP Versions
#define CRHTTPVersion1_0                    ((NSString *)kCFHTTPVersion1_0)
#define CRHTTPVersion1_1                    ((NSString *)kCFHTTPVersion1_1)

// HTTP Methods

#define CRHTTPAllMethods                    @[CRHTTPMethodGET, CRHTTPMethodPOST, CRHTTPMethodPUT, CRHTTPMethodDELETE, CRHTTPMethodPATCH, CRHTTPMethodOPTIONS]

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * NSStringFromCRHTTPMethod(CRHTTPMethod HTTPMethod);
FOUNDATION_EXPORT CRHTTPMethod CRHTTMethodMake(NSString * HTTPMethodName);

@interface CRMessage : NSObject

@property (nonatomic, readonly) NSString* version;
@property (nonatomic, readonly) NSDictionary<NSString*, NSString*>* allHTTPHeaderFields;

@property (nonatomic, copy, nullable) NSData* bodyData;

- (nullable NSString *)valueForHTTPHeaderField:(NSString *)HTTPHeaderField;

@end

NS_ASSUME_NONNULL_END