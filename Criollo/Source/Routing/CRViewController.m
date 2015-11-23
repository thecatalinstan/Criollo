//
//  CRViewController.m
//  Criollo
//
//  Created by Cătălin Stan on 5/17/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "CRViewController.h"
#import "CRView.h"
#import "CRNib.h"
#import "CRRequest.h"
#import "CRResponse.h"

@interface CRViewController ()

- (void)loadView;
- (void)viewDidLoad;

@end

@implementation CRViewController

+ (NSString *)defaultNibName {
    return [self.className stringByReplacingOccurrencesOfString:@"Controller" withString:@""];
}

- (instancetype)init {
    return [self initWithNibName:nil bundle:nil];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super init];
    if ( self != nil ) {
        _nibName = nibNameOrNil;
        if ( self.nibName == nil ) {
            _nibName = [self.class defaultNibName];
        }
        _nibBundle = nibBundleOrNil;
        _templateVariables = [NSMutableDictionary dictionary];
        [self loadView];
    }
    return self;
}

- (void)loadView {
    CRNib *nib = [[CRNib alloc] initWithNibNamed:self.nibName bundle:self.nibBundle];

    NSString *contents = [NSString stringWithUTF8String:nib.data.bytes];
 
    // Determine the view class to use
    Class viewClass = NSClassFromString([self.className stringByReplacingOccurrencesOfString:@"Controller" withString:@""]);
	if ( viewClass == nil ) {
        viewClass = [CRView class];
    }

    CRView* view = [[viewClass alloc] initWithContents:contents];
    self.view = view;
    
    [self viewDidLoad];
}

- (void)viewDidLoad {
}

- (NSString *)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response {
    return [self.view render:self.templateVariables];
}

- (CRRouteBlock)routeBlock {
    return ^(CRRequest *request, CRResponse *response, CRRouteCompletionBlock completionHandler) {
        [response setValue:@"text/html; charset=utf-8" forHTTPHeaderField:@"Content-type"];
        NSString* output = [self presentViewControllerWithRequest:request response:response];
        if ( self.shouldFinishResponse ) {
            [response sendString:output];
        } else {
            [response writeString:output];
        }
        completionHandler();
    };
}

- (BOOL)shouldFinishResponse {
    return YES;
}

@end
