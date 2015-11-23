//
//  CRNib.h
//  Criollo
//
//  Created by Cătălin Stan on 5/18/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

@interface CRNib : NSObject

@property (nonatomic, strong, nullable, readonly) NSData *data;
@property (nonatomic, strong, nonnull, readonly) NSString *name;

- (nonnull instancetype)initWithNibNamed:(nonnull NSString *)nibName bundle:(nullable NSBundle *)bundle NS_DESIGNATED_INITIALIZER;

@end
