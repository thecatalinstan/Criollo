//
//  CRStaticFileManager+Internal.h
//  Criollo
//
//  Created by Cătălin Stan on 10/05/2020.
//  Copyright © 2020 Cătălin Stan. All rights reserved.
//

#import "CRStaticFileManager.h"

@class CRRequestByteRange;

NS_ASSUME_NONNULL_BEGIN

@interface CRStaticFileManager ()

- (void)handleRequestForFileAtPath:(NSString *)path
                           options:(CRStaticFileServingOptions)options
                          fileName:(NSString *)fileName
                       contentType:(NSString *)contentType
                contentDisposition:(CRStaticFileContentDisposition)contentDisposition
                        attributes:(NSDictionary<NSFileAttributeKey, id> *)attributes
                           request:(CRRequest *)request
                          response:(CRResponse *)response
                        completion:(CRRouteCompletionBlock)completion;

- (void)handleError:(NSError *)error
            request:(CRRequest *)request
           response:(CRResponse *)response
         completion:(CRRouteCompletionBlock)completion;

- (BOOL)sendFileAtPath:(NSString *)path
             dataRange:(NSRange)dataRange
                cached:(BOOL)cached
              response:(CRResponse *)response
            completion:(CRRouteCompletionBlock)completion
                 error:(NSError *__autoreleasing *)error;

- (BOOL)dispatchFileAtPath:(NSString *)path
                      size:(unsigned long long)size
                 dataRange:(NSRange)dataRange
                   request:(CRRequest *)request
                  response:(CRResponse *)response
                completion:(CRRouteCompletionBlock)completion
                     error:(NSError *__autoreleasing *)error;

- (BOOL)canHandleFileType:(NSString *)fileType
                     path:(NSString *)path
                    error:(NSError *__autoreleasing *)error;

/// Determines the appropriate values for the HTTP headers relevant for the response:
/// @c Content-length, @c Content-range, @c Accept-Ranges, @c Content-Type and
/// @c Content-Disposition
- (NSDictionary<NSString *, NSString *> *)responseHeadersForByteRangeSet:(NSArray<CRRequestByteRange *> *)requestByteRangeSet
                                                                    path:(NSString *)path
                                                                fileName:(NSString *)fileName
                                                             contentType:(NSString *)contentType
                                                      contentDisposition:(CRStaticFileContentDisposition)contentDisposition
                                                                    size:(unsigned long long)size
                                                               bytesUnit:(NSString *)bytesUnit
                                                               dataRange:(NSRange *)dataRange
                                                                 partial:(BOOL *)partial
                                                                   error:(NSError *__autoreleasing *)error;

- (NSError *)errorWithCode:(NSUInteger)code
               description:(NSString *)description
                      path:(NSString *)path
           underlyingError:(NSError * _Nullable)underlyingError;

@end

NS_ASSUME_NONNULL_END
