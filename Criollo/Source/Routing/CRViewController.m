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

@property (nonatomic, readonly, strong, nonnull) NSMutableDictionary<NSString*, CRNib*> *nibCache;
@property (nonatomic, readonly, strong, nonnull) NSMutableDictionary<NSString*, CRView*> *viewCache;
@property (nonatomic, readonly, strong, nonnull) dispatch_queue_t isolationQueue;

- (void)loadView;

@end

@implementation CRViewController

- (NSMutableDictionary<NSString*, CRNib*>*)nibCache {
    static NSMutableDictionary<NSString*, CRNib*>* nibCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nibCache = [NSMutableDictionary dictionary];
    });
    return nibCache;
}

- (NSMutableDictionary<NSString*, CRView*>*)viewCache {
    static NSMutableDictionary<NSString*, CRView*>* viewCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        viewCache = [NSMutableDictionary dictionary];
    });
    return viewCache;
}

- (dispatch_queue_t)isolationQueue {
    static dispatch_queue_t isolationQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isolationQueue = dispatch_queue_create([[NSStringFromClass(self.class) stringByAppendingPathExtension:@"IsolationQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(isolationQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
    });
    return isolationQueue;
}

- (instancetype)init {
    return [self initWithNibName:nil bundle:nil];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super init];
    if ( self != nil ) {
        _nibName = nibNameOrNil;
        if ( self.nibName == nil ) {
            _nibName = NSStringFromClass(self.class);
        }
        _nibBundle = nibBundleOrNil;
        if ( self.nibBundle == nil ) {
            _nibBundle = [NSBundle mainBundle];
        }
        _templateVariables = [NSMutableDictionary dictionary];
        [self loadView];
    }
    return self;
}

- (void)loadView {
    CRView* view;

    NSString* viewCacheKey = [NSString stringWithFormat:@"%@/%@@%@", self.nibBundle.bundleIdentifier, self.nibName, NSStringFromClass(self.class)];

    if ( self.viewCache[viewCacheKey] != nil ) {

        view = self.viewCache[viewCacheKey];

    } else {

        NSString* nibCacheKey = [NSString stringWithFormat:@"%@/%@", self.nibBundle.bundleIdentifier, self.nibName];
        CRNib *nib;
        if ( self.nibCache[nibCacheKey] != nil ) {
            nib = self.nibCache[nibCacheKey];
        } else {
            nib = [[CRNib alloc] initWithNibNamed:self.nibName bundle:self.nibBundle];
            dispatch_async(self.isolationQueue, ^{
                self.nibCache[nibCacheKey] = nib;
            });
        }

        NSString *contents = [NSString stringWithUTF8String:nib.data.bytes];

        // Determine the view class to use
        Class viewClass = NSClassFromString([NSStringFromClass(self.class) stringByReplacingOccurrencesOfString:@"Controller" withString:@""]);
        if ( viewClass == nil ) {
            viewClass = [CRView class];
        }

        view = [[viewClass alloc] initWithContents:contents];
        dispatch_async(self.isolationQueue, ^{
            self.viewCache[viewCacheKey] = view;
        });
    }

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
