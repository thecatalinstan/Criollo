//
//  CRStaticFileManager+Internal.h
//  Criollo
//
//  Created by Cătălin Stan on 10/05/2020.
//  Copyright © 2020 Cătălin Stan. All rights reserved.
//

#import <Criollo/CRStaticFileManager.h>

@class CRRequestRange;

NS_ASSUME_NONNULL_BEGIN

@interface CRStaticFileManager ()

- (void)handleRequest:(CRRequest *)request response:(CRResponse *)response completion:(CRRouteCompletionBlock)completion;
- (BOOL)sendFileDataRange:(NSRange)dataRange partial:(BOOL)partial response:(CRResponse *)response completion:(CRRouteCompletionBlock)completion error:(NSError *__autoreleasing *)error;
- (BOOL)dispatchDataRange:(NSRange)dataRange partial:(BOOL)partial request:(CRRequest *)request response:(CRResponse *)response completion:(CRRouteCompletionBlock)completion error:(NSError *__autoreleasing *)error;

- (void)handleError:(NSError *)error request:(CRRequest *)request response:(CRResponse *)response completion:(CRRouteCompletionBlock)completion;

- (BOOL)canHandleFileType:(NSString *)fileType error:(NSError *__autoreleasing *)error;
- (NSDictionary<NSString *, NSString *> *)responseHeadersForRange:(CRRequestRange *)range dataRange:(NSRange *)dataRange partial:(BOOL *)partial error:(NSError *__autoreleasing *)error;

- (NSError *)errorWithErrNum:(int)errnum;
- (NSError *)errorWithCode:(NSUInteger)code description:(NSString *)description underlyingError:(NSError * _Nullable)underlyingError;

@end

NS_ASSUME_NONNULL_END
