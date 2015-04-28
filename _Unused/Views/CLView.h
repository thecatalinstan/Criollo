//
//  CLView.h
//  Criollo
//
//  Created by Cătălin Stan on 5/17/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CLView : NSObject {
    NSString* _templateText;
}

@property (nonatomic, readonly, retain) NSString* templateText;

- (instancetype)initWithTemplateText:(NSString *)templateText;
- render:(NSDictionary*)variables;

@end
