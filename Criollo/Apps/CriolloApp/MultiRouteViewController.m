//
//  MultiRouteViewController.m
//  HelloWorld-ObjC
//
//  Created by Cătălin Stan on 11/23/15.
//  Copyright © 2015 Catalin Stan. All rights reserved.
//

#import "MultiRouteViewController.h"
#import "APIController.h"
#import "HelloWorldViewController.h"

@implementation MultiRouteViewController

- (void)didLoad {
    [self addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response setValue:@"text/plain" forHTTPHeaderField:@"Content-type"];
        [response send:@"Hello :)"];
        completionHandler();
    } forPath:@"/hello"];

    [self addBlock:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
        [response setValue:@"text/plain" forHTTPHeaderField:@"Content-type"];
        [response send:NSStringFromCRHTTPMethod(request.method)];
        completionHandler();
    } forPath:@"/method"];

    [self addViewController:[HelloWorldViewController class] withNibName:nil bundle:nil forPath:@"/hello-c" HTTPMethod:CRHTTPMethodAll recursive:YES];
    [self addController:[APIController class] forPath:@"/api" HTTPMethod:CRHTTPMethodAll recursive:YES];
}

- (void)viewDidLoad {
    NSLog(@"%@", [self valueForKey:@"routes"]);
}

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {
    self.templateVariables[@"title"] = NSStringFromClass(self.class);

    NSMutableString* text = [NSMutableString string];
    [text appendString:@"<h3>Request Enviroment:</h3><pre>"];
    [request.env enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [text appendFormat:@"%@: %@\n", key, obj];
    }];
    [text appendString:@"</pre>"];
    self.templateVariables[@"text"] = text;

    return [super presentViewControllerWithRequest:request response:response];
}

@end
