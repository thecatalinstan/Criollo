//
//  CRNib.h
//  Criollo
//
//  Created by Cătălin Stan on 5/18/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN
@interface CRNib : NSObject

@property (nonatomic, strong, nullable, readonly) NSData *data;
@property (nonatomic, strong, readonly) NSString *name;

- (instancetype)initWithNibNamed:(NSString *)nibName bundle:(NSBundle * _Nullable)bundle NS_DESIGNATED_INITIALIZER;

@end
NS_ASSUME_NONNULL_END