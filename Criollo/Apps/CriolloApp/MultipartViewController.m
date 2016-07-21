//
//  MultipartViewController.m
//  HelloWorld-ObjC
//
//  Created by Cătălin Stan on 2/9/16.
//  Copyright © 2016 Catalin Stan. All rights reserved.
//

#import "MultipartViewController.h"

@implementation MultipartViewController

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {
    self.vars[@"title"] = NSStringFromClass(self.class);
    self.vars[@"body"] = [NSString stringWithFormat:@"%@", request.body];
    return [super presentViewControllerWithRequest:request response:response];
}


@end
