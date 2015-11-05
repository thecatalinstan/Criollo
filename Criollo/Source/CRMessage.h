//
//  CRMessage.h
//  Criollo
//
//  Created by Cătălin Stan on 29/04/15.
//
//

#define CRHTTP10  ((NSString *)kCFHTTPVersion1_0)
#define CRHTTP11  ((NSString *)kCFHTTPVersion1_1)

@interface CRMessage : NSObject

@property (nonatomic, strong) id message;

@property (nonatomic, readonly) NSString* version;
@property (nonatomic, readonly) NSDictionary<NSString*, NSString*>* allHTTPHeaderFields;

@property (nonatomic, readonly) NSData* serializedData;
@property (nonatomic, strong) NSData* body;

- (NSString *)valueForHTTPHeaderField:(NSString *)HTTPHeaderField;

@end
