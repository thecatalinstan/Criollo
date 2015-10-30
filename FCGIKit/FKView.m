//
//  FCGIKitView.m
//  FCGIKit
//
//  Created by Cătălin Stan on 5/17/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "FKView.h"

@implementation FKView

@synthesize templateText = _templateText;

- (instancetype)initWithTemplateText:(NSString *)templateText
{
    self = [self init];
    if ( self != nil ) {
        _templateText = templateText;
    }
    return self;
}

- (id)render:(NSDictionary*)variables
{    
    return self.templateText;
}

@end
