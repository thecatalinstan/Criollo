//
//  HelloWorldViewController.m
//  HelloWorld-ObjC
//
//  Created by Cătălin Stan on 11/23/15.
//  Copyright © 2015 Catalin Stan. All rights reserved.
//

#import "HelloWorldViewController.h"

@implementation HelloWorldViewController

- (void)viewDidLoad {
}

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {
    self.templateVariables[@"TITLE"] = NSStringFromClass(self.class);

    NSMutableString* text = [NSMutableString string];
    [text appendString:@"<h3>Request Enviroment:</h3><pre>"];
    [request.env enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [text appendFormat:@"%@: %@\n", key, obj];
    }];
    [text appendString:@"</pre>"];
    self.templateVariables[@"TEXT"] = text;

    return [super presentViewControllerWithRequest:request response:response];
}

@end
