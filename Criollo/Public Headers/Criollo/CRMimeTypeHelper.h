//
//  CRMimeTypeHelper.h
//  Criollo
//
//  Created by Cătălin Stan on 2/11/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
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
