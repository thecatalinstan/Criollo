//
//  CRUploadedFile.h
//  Criollo
//
//  Created by Cătălin Stan on 1/14/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN
@interface CRUploadedFile : NSObject

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * path;
@property (nonatomic, strong) NSString * size;
@property (nonatomic, strong) NSString * type;

@end
NS_ASSUME_NONNULL_END