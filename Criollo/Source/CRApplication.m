//
//  CRApplication.m
//  Criollo
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import "CRApplication.h"

NS_ASSUME_NONNULL_BEGIN

NSNotificationName const CRApplicationWillFinishLaunchingNotification = @"CRApplicationWillFinishLaunchingNotification";
NSNotificationName const CRApplicationDidFinishLaunchingNotification = @"CRApplicationDidFinishLaunchingNotification";
NSNotificationName const CRApplicationWillTerminateNotification = @"CRApplicationWillTerminateNotification";

static NSString* const CRApplicationRunLoopMode    = @"NSDefaultRunLoopMode";
static NSNotificationName const CRApplicationDidReceiveSignalNotification = @"CRApplicationDidReceiveSignal";

CRApplication* CRApp;

@interface CRApplication ()

@property (nonatomic, readwrite, weak) id<CRApplicationDelegate> delegate;

- (void)startRunLoop;
- (void)stopRunLoop;

- (void)quit;
- (void)cancelTermination;

@end

NS_ASSUME_NONNULL_END

void CRHandleSignal(int sig) {
    signal(sig, SIG_IGN);
    [CRApplication.sharedApplication terminate:nil];
    signal(sig, CRHandleSignal);
}

int CRApplicationMain(int argc, const char * argv[], id<CRApplicationDelegate> delegate) {
    signal(SIGTERM, CRHandleSignal);
    signal(SIGINT, CRHandleSignal);
    signal(SIGQUIT, CRHandleSignal);
    signal(SIGTSTP, CRHandleSignal);
    
    [[[CRApplication alloc] initWithDelegate:delegate] run];
            
    return EXIT_SUCCESS;
}

@implementation CRApplication

- (void)setDelegate:(id<CRApplicationDelegate>)delegate {
    if ( _delegate ) {
        [[NSNotificationCenter defaultCenter] removeObserver:_delegate];
        _delegate = nil;
    }
    
    _delegate = delegate;
    
    if ( [(id)_delegate respondsToSelector:@selector(applicationWillFinishLaunching:)] ) {
        [[NSNotificationCenter defaultCenter] addObserver:_delegate selector:@selector(applicationWillFinishLaunching:) name:CRApplicationWillFinishLaunchingNotification object:nil];
    }
    if ( [(id)_delegate respondsToSelector:@selector(applicationDidFinishLaunching:)] ) {
        [[NSNotificationCenter defaultCenter] addObserver:_delegate selector:@selector(applicationDidFinishLaunching:) name:CRApplicationDidFinishLaunchingNotification object:nil];
    }
    if ( [(id)_delegate respondsToSelector:@selector(applicationWillTerminate:)] ) {
        [[NSNotificationCenter defaultCenter] addObserver:_delegate selector:@selector(applicationWillTerminate:) name:CRApplicationWillTerminateNotification object:nil];
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
			NSLog(@"Principal class (%@) of main bundle is not subclass of %@", NSStringFromClass(class), NSStringFromClass(self.class) );
		}
        
		CRApp = [class new];
	}

	return CRApp;
}

- (instancetype)init {
    return [self initWithDelegate:nil];
}

- (instancetype)initWithDelegate:(id<CRApplicationDelegate>)delegate {
    self = [super init];
    if ( self != nil ) {
        self.delegate = delegate;
    }
    return self;
}

#pragma mark - Lifecycle

- (void)quit {
    [[NSNotificationCenter defaultCenter] postNotificationName:CRApplicationWillTerminateNotification object:self];
    exit(EXIT_SUCCESS);
}

- (void)cancelTermination {
    [self startRunLoop];
}

- (void)startRunLoop {
    [[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:[[NSDate distantFuture] timeIntervalSinceNow] target:self selector:@selector(stop) userInfo:nil repeats:YES] forMode:CRApplicationRunLoopMode];

    while ([[NSRunLoop mainRunLoop] runMode:CRApplicationRunLoopMode beforeDate:[NSDate distantFuture]] );
}

- (void)stopRunLoop {
    CFRunLoopStop(CFRunLoopGetMain());
}

- (void)terminate:(id)sender {
    [self performSelectorOnMainThread:@selector(stop:) withObject:nil waitUntilDone:YES];
    
    CRApplicationTerminateReply reply = CRTerminateNow;
    if ([(id)_delegate respondsToSelector:@selector(applicationShouldTerminate:)]) {
        reply = [_delegate applicationShouldTerminate:self];
    }
    
    switch (reply) {
        case CRTerminateCancel:
            [self cancelTermination];
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
        [self cancelTermination];
    }
}

- (void)run {
    [self finishLaunching];
    [NSNotificationCenter.defaultCenter postNotificationName:CRApplicationDidFinishLaunchingNotification object:self];
    
    [self startRunLoop];
    
    [self terminate:nil];
}

- (void)stop:(id)sender {
    [self stopRunLoop];
}

- (void)finishLaunching {
	[[NSNotificationCenter defaultCenter] postNotificationName:CRApplicationWillFinishLaunchingNotification object:self];
}

#pragma mark - Output

- (void)log:(NSString *)string {
    [self logFormat:string];
}

- (void)logFormat:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [self logFormat:format args:args];
    va_end(args);
}

- (void)logFormat:(NSString *)format args:(va_list)args {
    NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    [[NSFileHandle fileHandleWithStandardOutput] writeData: [[formattedString stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)logError:(NSString *)string {
    [self logErrorFormat:string];
}

- (void)logErrorFormat:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [self logErrorFormat:format args:args];
    va_end(args);
}

- (void)logErrorFormat:(NSString *)format args:(va_list)args {
    NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    [[NSFileHandle fileHandleWithStandardError] writeData: [[formattedString stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
