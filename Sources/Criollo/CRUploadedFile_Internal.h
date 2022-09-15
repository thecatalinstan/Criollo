//
//  CRUploadedFile_Internal.h
//
//
//  Created by Cătălin Stan on 19/10/2016.
//

#import <Criollo/CRUploadedFile.h>

NS_ASSUME_NONNULL_BEGIN

@interface CRUploadedFile ()

- (instancetype)initWithName:(NSString *)name NS_DESIGNATED_INITIALIZER;

- (void)fetchAttributes;
- (void)fetchMimeType;

- (void)appendData:(NSData *)data;
- (void)finishWriting;

@end

NS_ASSUME_NONNULL_END
