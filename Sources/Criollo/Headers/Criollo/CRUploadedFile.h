//
//  CRUploadedFile.h
//
//
//  Created by Cătălin Stan on 1/14/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CRUploadedFile : NSObject

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSURL * temporaryFileURL;
@property (nonatomic, strong, nullable) NSDictionary<NSFileAttributeKey,id> * attributes;
@property (nonatomic, strong, nullable) NSString * mimeType;

@end

NS_ASSUME_NONNULL_END
