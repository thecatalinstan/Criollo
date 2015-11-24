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
    self.templateVariables[@"TEXT"] = [NSString stringWithFormat:@"%@", request.query];
    return [super presentViewControllerWithRequest:request response:response];
}

@end
