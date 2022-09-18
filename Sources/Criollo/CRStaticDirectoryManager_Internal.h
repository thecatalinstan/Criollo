//
//  CRStaticDirectoryManager_Internal.h
//
//
//  Created by Cătălin Stan on 14/05/2020.
//

#import <Criollo/CRStaticDirectoryManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface CRStaticDirectoryManager ()

- (void)handleRequest:(CRRequest *)request response:(CRResponse *)response completion:(dispatch_block_t)completion;
- (BOOL)generateIndexForPath:(NSString *)absolurePath requestedPath:(NSString *)requestedPath relativePath:(NSString *)relativePath response:(CRResponse *)response completion:(dispatch_block_t)completion error:(NSError *__autoreleasing *)error;

- (void)handleError:(NSError *)error request:(CRRequest *)request response:(CRResponse *)response completion:(dispatch_block_t)completion;
- (NSError *)errorWithCode:(NSUInteger)code description:(NSString *)description underlyingError:(NSError * _Nullable)underlyingError;
    
@end

NS_ASSUME_NONNULL_END
