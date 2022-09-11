//
//  CRNib.m
//  Criollo
//
//  Created by Cătălin Stan on 5/18/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Criollo/CRNib.h>

static NSString * const CRNibExtension = @"html";

@implementation CRNib

- (instancetype)init {
    return [self initWithNibNamed:@"" bundle:nil];
}

- (instancetype)initWithNibNamed:(NSString *)nibName bundle:(NSBundle *)bundle {
    self = [super init];
    if ( self != nil ) {
        _name = nibName;

        if ( bundle == nil ) {
            bundle = [NSBundle mainBundle];
        }
        
        NSString* path = [bundle pathForResource:self.name ofType:CRNibExtension];
        if ( path != nil ) {
            NSError * nibLoadError;
            _data = [NSData dataWithContentsOfFile:path options:NSDataReadingMapped error:&nibLoadError];
        }
        if ( _data == nil ) {
            _data = [NSData data];
        }
    }
    return self;
}

@end
