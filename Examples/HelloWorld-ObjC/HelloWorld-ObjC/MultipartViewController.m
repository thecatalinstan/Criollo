//
//  MultipartViewController.m
//  HelloWorld-ObjC
//
//  Created by Cătălin Stan on 2/9/16.
//  Copyright © 2016 Catalin Stan. All rights reserved.
//

#import "MultipartViewController.h"

@implementation MultipartViewController

- (void)viewDidLoad {
    
}

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {
    self.templateVariables[@"TITLE"] = NSStringFromClass(self.class);

    return [super presentViewControllerWithRequest:request response:response];
}


@end
