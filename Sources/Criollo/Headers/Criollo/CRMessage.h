//
//  CRMessage.h
//
//
//  Created by Cătălin Stan on 29/04/15.
//
//

#import <Criollo/CRHTTPVersion.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CRMessage : NSObject

@property (nonatomic, readonly) CRHTTPVersion version;
@property (nonatomic, readonly) NSDictionary<NSString*, NSString*> *allHTTPHeaderFields;

@property (nonatomic, copy, nullable) NSData* bodyData;

- (nullable NSString *)valueForHTTPHeaderField:(NSString *)HTTPHeaderField;

@end

NS_ASSUME_NONNULL_END
