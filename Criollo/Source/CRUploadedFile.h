//
//  CRUploadedFile.h
//  Criollo
//
//  Created by Cătălin Stan on 1/14/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

@interface CRUploadedFile : NSObject

@property (nonatomic, strong, nonnull) NSString * name;
@property (nonatomic, strong, nonnull) NSString * path;
@property (nonatomic, strong, nonnull) NSString * size;
@property (nonatomic, strong, nonnull) NSString * type;

@end
