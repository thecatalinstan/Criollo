//
//  CRMimeTypeHelper.h
//
//
//  Created by Cătălin Stan on 2/11/16.
//

#import <Foundation/Foundation.h>
#import <Criollo/CRTypes.h>

NS_ASSUME_NONNULL_BEGIN

@interface CRMimeTypeHelper : NSObject

// TODO: convert to class property
+ (instancetype)sharedHelper;

- (nullable NSString *)mimeTypeForExtension:(NSString *)extension;
- (void)setMimeType:(NSString *)mimeType forExtension:(NSString *)extension;

- (NSString *)mimeTypeForFileAtPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
