//
//  CRMessage_Internal.h
//
//
//  Created by Cătălin Stan on 11/20/15.
//

#import <Criollo/CRMessage.h>

NS_ASSUME_NONNULL_BEGIN

@interface CRMessage ()

@property (nonatomic, readonly) NSData* serializedData;
@property (nonatomic, strong) id message;
@property (nonatomic, readonly) BOOL headersComplete;

+ (NSArray<NSString *>*)acceptedHTTPMethods;

@end

NS_ASSUME_NONNULL_END
