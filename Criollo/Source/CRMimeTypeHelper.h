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

- (nonnull NSString *)mimeTypeForFileAtPath:(NSString * _Nonnull)path;

@end
