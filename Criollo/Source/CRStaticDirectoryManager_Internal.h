//
//  CRStaticDirectoryManager_Internal.h
//  Criollo macOS
//
//  Created by Cătălin Stan on 14/05/2020.
//  Copyright © 2020 Cătălin Stan. All rights reserved.
//

#import <Criollo/CRStaticDirectoryManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface CRStaticDirectoryManager ()

- (void)handleRequest:(CRRequest *)request response:(CRResponse *)response completion:(CRRouteCompletionBlock)completion;
- (BOOL)generateIndexForPath:(NSString *)absolurePath requestedPath:(NSString *)requestedPath relativePath:(NSString *)relativePath response:(CRResponse *)response completion:(CRRouteCompletionBlock)completion error:(NSError *__autoreleasing *)error;

- (void)handleError:(NSError *)error request:(CRRequest *)request response:(CRResponse *)response completion:(CRRouteCompletionBlock)completion;
- (NSError *)errorWithCode:(NSUInteger)code description:(NSString *)description underlyingError:(NSError * _Nullable)underlyingError;
    
@end

NS_ASSUME_NONNULL_END
