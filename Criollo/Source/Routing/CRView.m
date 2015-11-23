//
//  CRView.m
//  Criollo
//
//  Created by Cătălin Stan on 5/17/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "CRView.h"

#define CRViewVariableFormat @"[%@]"

@interface CRView ()

@property (nonatomic, strong, nonnull) NSMutableString* mutableContents;

@end

@implementation CRView

- (instancetype)init {
    return [self initWithContents:nil];
}

- (instancetype)initWithContents:(NSString *)contents {
    self = [super init];
    if ( self != nil ) {
        _contents = contents == nil ? @"" : contents;
        _mutableContents = _contents.mutableCopy;
    }
    return self;
}

- (NSString *)render:(NSDictionary<NSString*, NSString*> *)templateVariables {
    if ( templateVariables == nil ) {
        return self.contents;
    } else {
        [templateVariables enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [self.mutableContents replaceOccurrencesOfString:[NSString stringWithFormat:CRViewVariableFormat, key] withString:obj options:0 range:NSMakeRange(0, self.mutableContents.length)];
        }];
        return self.mutableContents;
    }
}

@end
