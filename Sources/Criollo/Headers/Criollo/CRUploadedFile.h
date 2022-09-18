//
//  CRUploadedFile.h
//
//
//  Created by Cătălin Stan on 1/14/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CRUploadedFile : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSURL *temporaryFileURL;
@property (nonatomic, nullable) NSDictionary<NSFileAttributeKey, id> *attributes;
@property (nonatomic, nullable) NSString *mimeType;

@end

NS_ASSUME_NONNULL_END
