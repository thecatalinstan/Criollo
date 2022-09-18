//
//  CRApplication.m
//
//
//  Created by Cătălin Stan on 4/24/13.
//

#import <Criollo/CRApplication.h>

NS_ASSUME_NONNULL_BEGIN

NSNotificationName const CRApplicationWillFinishLaunchingNotification = @"CRApplicationWillFinishLaunchingNotification";
NSNotificationName const CRApplicationDidFinishLaunchingNotification = @"CRApplicationDidFinishLaunchingNotification";
NSNotificationName const CRApplicationWillTerminateNotification = @"CRApplicationWillTerminateNotification";

CRApplication *CRApp;
static id<CRApplicationDelegate> CRAppDelegate;

@interface CRApplication ()

- (void)startRunLoop;
- (void)quit;

@end

NS_ASSUME_NONNULL_END

static void CRHandleSignal(int sig) {
    signal(sig, SIG_IGN);
    [CRApplication.sharedApplication terminate:nil];
    signal(sig, CRHandleSignal);
}

int CRApplicationMain(int argc, char *argv[], id<CRApplicationDelegate> delegate) {
    signal(SIGTERM, CRHandleSignal);
    signal(SIGINT, CRHandleSignal);
    signal(SIGQUIT, CRHandleSignal);
    signal(SIGTSTP, CRHandleSignal);
    
    CRAppDelegate = delegate;
    [[CRApplication sharedApplication] run];
    
    return EXIT_SUCCESS;
}

@implementation CRApplication

- (void)setDelegate:(id<CRApplicationDelegate>)delegate {
    NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
    
    if (_delegate) {
        [defaultCenter removeObserver:_delegate];
        _delegate = nil;
    }
    
    _delegate = delegate;
    
    if ([(id)_delegate respondsToSelector:@selector(applicationWillFinishLaunching:)]) {
        [defaultCenter addObserver:_delegate selector:@selector(applicationWillFinishLaunching:) name:CRApplicationWillFinishLaunchingNotification object:nil];
    }
    if ([(id)_delegate respondsToSelector:@selector(applicationDidFinishLaunching:)]) {
        [defaultCenter addObserver:_delegate selector:@selector(applicationDidFinishLaunching:) name:CRApplicationDidFinishLaunchingNotification object:nil];
    }
    if ([(id)_delegate respondsToSelector:@selector(applicationWillTerminate:)]) {
        [defaultCenter addObserver:_delegate selector:@selector(applicationWillTerminate:) name:CRApplicationWillTerminateNotification object:nil];
    }
}

#pragma mark - Initialization

+ (CRApplication *)sharedApplication {
	Class class;
	if(!CRApp) {
        if(!(class = NSBundle.mainBundle.principalClass)) {
			NSLog(@"Main bundle does not define an existing principal class: %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSPrincipalClass"]);
			class = self;
		}
        
		if(![class isSubclassOfClass:self.class]) {
			NSLog(@"Principal class (%@) of main bundle is not subclass of %@", NSStringFromClass(class), NSStringFromClass(self.class));
		}
        
        CRApp = [[class alloc] initWithDelegate:CRAppDelegate];
	}
	return CRApp;
}

- (instancetype)initWithDelegate:(id<CRApplicationDelegate>)delegate {
    self = [super init];
    if (self != nil) {
        self.delegate = delegate;
    }
    return self;
}

#pragma mark - Lifecycle

- (void)quit {
    [NSNotificationCenter.defaultCenter postNotificationName:CRApplicationWillTerminateNotification object:self];
    exit(EXIT_SUCCESS);
}

- (void)startRunLoop {
    NSDate *distantFuture = NSDate.distantFuture;
    NSRunLoop *mainRunLoop = NSRunLoop.mainRunLoop;
    NSRunLoopMode mode = NSDefaultRunLoopMode;
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:distantFuture.timeIntervalSinceNow target:self selector:@selector(stop:) userInfo:nil repeats:YES];
    [mainRunLoop addTimer:timer forMode:mode];

    while ([mainRunLoop runMode:mode beforeDate:distantFuture]);
}

- (void)terminate:(id)sender {
    [self performSelectorOnMainThread:@selector(stop:) withObject:nil waitUntilDone:YES];
    
    CRApplicationTerminateReply reply = CRTerminateNow;
    if ([(id)self.delegate respondsToSelector:@selector(applicationShouldTerminate:)]) {
        reply = [self.delegate applicationShouldTerminate:self];
    }
    
    switch (reply) {
        case CRTerminateCancel:
            [self startRunLoop];
            break;
            
        case CRTerminateLater:
            [self startRunLoop];
            break;
            
        case CRTerminateNow:
        default:
            [self quit];
            break;
    }
}

- (void)replyToApplicationShouldTerminate:(BOOL)shouldTerminate {
    [self performSelectorOnMainThread:@selector(stop:) withObject:nil waitUntilDone:YES];
    
    if (shouldTerminate) {
        [self quit];
    } else {
        [self startRunLoop];
    }
}

- (void)run {
    [self finishLaunching];
    [NSNotificationCenter.defaultCenter postNotificationName:CRApplicationDidFinishLaunchingNotification object:self];
    
    [self startRunLoop];
    
    [self terminate:nil];
}

- (void)stop:(id)sender {
    CFRunLoopStop(CFRunLoopGetMain());
}

- (void)finishLaunching {
	[NSNotificationCenter.defaultCenter postNotificationName:CRApplicationWillFinishLaunchingNotification object:self];
}

@end
