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

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil prefix:(NSString * _Nullable)prefix {
    self  = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil prefix:prefix];
    if ( self != nil ) {
        [self add:@"/hello" block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
            [response setValue:@"text/plain" forHTTPHeaderField:@"Content-type"];
            [response send:@"Hello :)"];
            completionHandler();
        }];

        [self add:@"/method" block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
            [response setValue:@"text/plain" forHTTPHeaderField:@"Content-type"];
            [response send:NSStringFromCRHTTPMethod(request.method)];
            completionHandler();
        }];

        [self add:@"/hello-c" viewController:[HelloWorldViewController class] withNibName:nil bundle:nil];
        [self add:@"/api" controller:[APIController class]];

        // Public folders path
        [self mount:@"/pub" directoryAtPath:@"~" options:CRStaticDirectoryServingOptionsAutoIndex];

        // Static file
        [self mount:@"/file.txt" fileAtPath:@"/etc/hosts" options:CRStaticFileServingOptionsCache fileName:@"hosts" contentType:@"text/plain" contentDisposition:CRStaticFileContentDispositionInline];
        
        // Dispatch something asynchroneosly after a delay
        [self add:@"/async" block:^(CRRequest * _Nonnull request, CRResponse * _Nonnull response, CRRouteCompletionBlock  _Nonnull completionHandler) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [response send:@"Bla bla"];
                completionHandler();
            });
        }];
    }
    return self;
}

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {
    self.vars[@"title"] = NSStringFromClass(self.class);

    NSMutableString* text = [NSMutableString string];
    [text appendString:@"<h3>Request Enviroment:</h3><pre>"];
    [request.env enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [text appendFormat:@"%@: %@\n", key, obj];
    }];
    [text appendString:@"</pre>"];
    self.vars[@"text"] = text;

    return [super presentViewControllerWithRequest:request response:response];
}

@end
