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

- (nonnull instancetype)initWithNibNamed:(NSString * _Nonnull)nibName bundle:(NSBundle * _Nullable)bundle NS_DESIGNATED_INITIALIZER;

@end
