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

NS_ASSUME_NONNULL_BEGIN
@interface CRViewController ()

@property (nonatomic, readonly, strong) NSMutableDictionary<NSString*, CRNib*> *nibCache;
@property (nonatomic, readonly, strong) NSMutableDictionary<NSString*, CRView*> *viewCache;
@property (nonatomic, readonly, strong) dispatch_queue_t isolationQueue;

- (void)loadView;

@end
NS_ASSUME_NONNULL_END

@implementation CRViewController

static const NSMutableDictionary<NSString *, CRNib *> * nibCache;
static const NSMutableDictionary<NSString *, CRView *> * viewCache;
static dispatch_queue_t isolationQueue;

+ (void)initialize {
    nibCache = [NSMutableDictionary dictionary];
    viewCache = [NSMutableDictionary dictionary];
    isolationQueue = dispatch_queue_create([[NSStringFromClass(self.class) stringByAppendingPathExtension:@"IsolationQueue"] cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(isolationQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
}

- (NSMutableDictionary<NSString*, CRNib*>*)nibCache {
    return nibCache;
}

- (NSMutableDictionary<NSString*, CRView*>*)viewCache {
    return viewCache;
}

- (dispatch_queue_t)isolationQueue {
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
//        if ( ![response valueForHTTPHeaderField:@"Content-Length"] ) {
//            [response setValue:@(output.length).stringValue forHTTPHeaderField:@"Content-Length"];
//        }

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
