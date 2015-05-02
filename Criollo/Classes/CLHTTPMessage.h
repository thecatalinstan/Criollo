//
//  CLHTTPMessage.h
//  Criollo
//
//  Created by Cătălin Stan on 29/04/15.
//
//

#define CLHTTP10  ((NSString *)kCFHTTPVersion1_0)
#define CLHTTP11  ((NSString *)kCFHTTPVersion1_1)

@interface CLHTTPMessage : NSObject

@property (nonatomic, assign) CFHTTPMessageRef message;

@property (nonatomic, readonly) NSString* version;
@property (nonatomic, readonly) NSURL* URL;
@property (nonatomic, readonly) NSDictionary* allHTTPHeaderFields;

@property (nonatomic, readonly) NSData* data;
@property (nonatomic, strong) NSData* body;

- (NSString *)valueForHTTPHeaderField:(NSString *)HTTPHeaderField;

@end
