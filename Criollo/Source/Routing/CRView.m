//
//  CRView.m
//  Criollo
//
//  Created by Cătălin Stan on 5/17/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "CRView.h"

#define CRViewVariableFormat @"{{%@}}"

@interface CRView ()

@end

@implementation CRView

- (instancetype)init {
    return [self initWithContents:nil];
}

- (instancetype)initWithContents:(NSString *)contents {
    self = [super init];
    if ( self != nil ) {
        _contents = contents == nil ? @"" : contents;
    }
    return self;
}

- (NSString *)render:(NSDictionary<NSString*, NSString*> *)templateVariables {
    if ( templateVariables == nil ) {
        return self.contents;
    } else {
        NSLog(@"%@", templateVariables);
        NSMutableString* mutableContents = self.contents.mutableCopy;
        [templateVariables enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            if ( obj == nil || ![obj isKindOfClass:[NSString class]] ) {
                return;
            }
            [mutableContents replaceOccurrencesOfString:[NSString stringWithFormat:CRViewVariableFormat, key] withString:obj options:0 range:NSMakeRange(0, mutableContents.length)];
            NSLog(@"%@", mutableContents);
        }];
        return mutableContents;
    }
}

@end
