//
//  CRMessage.h
//  Criollo
//
//  Created by Cătălin Stan on 29/04/15.
//
//

// HTTP Versions
#define CRHTTPVersion1_0                    ((NSString *)kCFHTTPVersion1_0)
#define CRHTTPVersion1_1                    ((NSString *)kCFHTTPVersion1_1)

// HTTP Methods
#define CRHTTPMethodGET                     @"GET"
#define CRHTTPMethodPOST                    @"POST"
#define CRHTTPMethodPUT                     @"PUT"
#define CRHTTPMethodDELETE                  @"DELETE"
#define CRHTTPMethodPATCH                   @"PATCH"
#define CRHTTPMethodOPTIONS                 @"OPTIONS"

#define CRHTTPAllMethods                    @[CRHTTPMethodGET, CRHTTPMethodPOST, CRHTTPMethodPUT, CRHTTPMethodDELETE, CRHTTPMethodPATCH, CRHTTPMethodOPTIONS]


@interface CRMessage : NSObject

@property (nonatomic, readonly, nonnull) NSString* version;
@property (nonatomic, readonly, nonnull) NSDictionary<NSString*, NSString*>* allHTTPHeaderFields;

@property (nonatomic, copy, nullable) NSData* bodyData;

- (nullable NSString *)valueForHTTPHeaderField:(nonnull NSString *)HTTPHeaderField;

@end
