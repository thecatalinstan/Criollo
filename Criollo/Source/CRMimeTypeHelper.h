//
//  CRMimeTypeHelper.h
//  Criollo
//
//  Created by Cătălin Stan on 2/11/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "CRTypes.h"

@interface CRMimeTypeHelper : NSObject

+ (nonnull instancetype)sharedHelper;

- (nullable NSString *)mimeTypeForExtension:(NSString * _Nonnull)extension;
- (void)setMimeType:(NSString * _Nonnull)mimeType forExtension:(NSString * _Nonnull)extension;

- (nonnull NSString *)mimeTypeForFileAtPath:(NSString * _Nonnull)path;

@end
