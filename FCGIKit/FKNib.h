//
//  FCGIKitNib.h
//  FCGIKit
//
//  Created by Cătălin Stan on 5/18/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FKNib : NSObject {
    NSBundle* bundle;
    
    NSData* _data;
    NSString* _name;
}

@property (nonatomic, retain) NSData* data;
@property (nonatomic, retain) NSString* name;

- (instancetype)initWithNibNamed:(NSString *)nibName bundle:(NSBundle *)bundle;

- (NSString*)stringUsingEncoding:(NSStringEncoding)encoding;

+ (void)cacheNibNames:(NSArray*)nibNames bundle:(NSBundle*)nibBundle;

+ (FKNib *)cachedNibForNibName:(NSString*)nibName;
+ (void)cacheNib:(FKNib *)nib forNibName:(NSString*)nibName;
@end
