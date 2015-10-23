//
//  CRApplication.m
//  Criollo
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import <Criollo/CRApplication.h>


NSUInteger const CRErrorNone = 0;
NSUInteger const CRErrorSigTERM = 1007;

NSString* const CRApplicationRunLoopMode = @"NSDefaultRunLoopMode";

NSString* const CRApplicationWillFinishLaunchingNotification = @"CRApplicationWillFinishLaunchingNotification";
NSString* const CRApplicationDidFinishLaunchingNotification = @"CRApplicationDidFinishLaunchingNotification";
NSString* const CRApplicationWillTerminateNotification = @"CRApplicationWillTerminateNotification";

@class CRApplication;
CRApplication* CRApp;

static void installSIGTERMHandler(void) {
    static dispatch_once_t   sOnceToken;
    static dispatch_source_t sSignalSource;

    dispatch_once(&sOnceToken, ^{
        signal(SIGTERM, SIG_IGN);

        sSignalSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGTERM, 0, dispatch_get_main_queue());
        assert(sSignalSource != NULL);

        dispatch_source_set_event_handler(sSignalSource, ^{
            assert([NSThread isMainThread]);
            [CRApp logErrorFormat: @"Got SIGTERM."];
            [CRApp terminate:nil];
        });

        dispatch_resume(sSignalSource);
    });
}

int CRApplicationMain(int argc, char * const argv[], id<CRApplicationDelegate> delegate) {
    @autoreleasepool {
        installSIGTERMHandler();
        CRApplication* app = [[CRApplication alloc] initWithDelegate:delegate];
        [app run];
    }
    return EXIT_SUCCESS;
}


@interface CRApplication () {
    __strong id<CRApplicationDelegate> _delegate;

    BOOL shouldKeepRunning;
    BOOL firstRunCompleted;

    BOOL waitingOnTerminateLaterReply;
    NSTimer* waitingOnTerminateLaterReplyTimer;

    CFRunLoopObserverRef mainRunLoopObserver;
}

- (void)startRunLoop;
- (void)stopRunLoop;

- (void)quit;
- (void)cancelTermination;

- (void)waitingOnTerminateLaterReplyTimerCallback;

@end

@implementation CRApplication

#pragma mark - Properties

- (id<CRApplicationDelegate>) delegate {
    return _delegate;
}

- (void)setDelegate:(id<CRApplicationDelegate>)delegate {
    if ( _delegate ) {
        [[NSNotificationCenter defaultCenter] removeObserver:_delegate];
        _delegate = nil;
    }
    
    _delegate = delegate;
    
    if ( [_delegate respondsToSelector:@selector(applicationWillFinishLaunching:)] ) {
        [[NSNotificationCenter defaultCenter] addObserver:_delegate selector:@selector(applicationWillFinishLaunching:) name:CRApplicationWillFinishLaunchingNotification object:nil];
    }
    if ( [_delegate respondsToSelector:@selector(applicationDidFinishLaunching:)] ) {
        [[NSNotificationCenter defaultCenter] addObserver:_delegate selector:@selector(applicationDidFinishLaunching:) name:CRApplicationDidFinishLaunchingNotification object:nil];
    }
    if ( [_delegate respondsToSelector:@selector(applicationWillTerminate:)] ) {
        [[NSNotificationCenter defaultCenter] addObserver:_delegate selector:@selector(applicationWillTerminate:) name:CRApplicationWillTerminateNotification object:nil];
    }
}

#pragma mark - Initialization

+ (CRApplication *)sharedApplication {
	Class class;
	if( ! CRApp ) {
		if( ! ( class = [NSBundle mainBundle].principalClass ) ) {
			NSLog(@"Main bundle does not define an existing principal class: %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSPrincipalClass"]);
			class = self;
		}
		if( ! [class isSubclassOfClass:self.class] ) {
			NSLog(@"Principal class (%@) of main bundle is not subclass of %@", NSStringFromClass(class), NSStringFromClass(self.class) );
		}
		[class new];
	}

	return CRApp;
}

- (instancetype)init {
    self = [super init];
    if ( self != nil ) {
        CRApp = self;
    }
    return self;
}

- (instancetype)initWithDelegate:(id<CRApplicationDelegate>)delegate {
    self = [self init];
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

- (void)waitingOnTerminateLaterReplyTimerCallback {
    [self terminate:nil];
}

- (void)startRunLoop {
    shouldKeepRunning = YES;

    [[NSNotificationCenter defaultCenter] postNotificationName:CRApplicationDidFinishLaunchingNotification object:self];
    [[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:[[NSDate distantFuture] timeIntervalSinceNow] target:self selector:@selector(stop) userInfo:nil repeats:YES] forMode:CRApplicationRunLoopMode];

    while ( shouldKeepRunning && [[NSRunLoop mainRunLoop] runMode:CRApplicationRunLoopMode beforeDate:[NSDate distantFuture]] );
}

- (void)stopRunLoop {
    CFRunLoopStop(CFRunLoopGetMain());
}

- (void)terminate:(id)sender {
    [self performSelectorOnMainThread:@selector(stop:) withObject:nil waitUntilDone:YES];
    
    CRApplicationTerminateReply reply = CRTerminateNow;
    if ( [_delegate respondsToSelector:@selector(applicationShouldTerminate:)]) {
        reply = [_delegate applicationShouldTerminate:self];
    }
    
    switch ( reply ) {
        case CRTerminateCancel:
            [self cancelTermination];
            break;
            
        case CRTerminateLater:
            waitingOnTerminateLaterReply = YES;
            waitingOnTerminateLaterReplyTimer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(waitingOnTerminateLaterReplyTimerCallback) userInfo:nil repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:waitingOnTerminateLaterReplyTimer forMode:CRApplicationRunLoopMode];
            while (waitingOnTerminateLaterReply && [[NSRunLoop mainRunLoop] runMode:CRApplicationRunLoopMode beforeDate:[NSDate distantFuture]]);
            break;
            
        case CRTerminateNow:
        default:
            [self quit];
            break;
    }

}

- (void)replyToApplicationShouldTerminate:(BOOL)shouldTerminate {
    waitingOnTerminateLaterReply = NO;
    [waitingOnTerminateLaterReplyTimer invalidate];
    
    [self performSelectorOnMainThread:@selector(stop:) withObject:nil waitUntilDone:YES];
    
    if ( shouldTerminate ) {        
        [self quit];
    } else {
        [self cancelTermination];
    }
}

- (void)run {
    [self finishLaunching];
    [self startRunLoop];
    [self terminate:nil];
}

- (void)stop:(id)sender
{
    [self stopRunLoop];
}

- (void)finishLaunching
{
	// Let observers know that initialization is complete
	[[NSNotificationCenter defaultCenter] postNotificationName:CRApplicationWillFinishLaunchingNotification object:self];
}

#pragma mark - Output


- (void)logErrorFormat:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    BOOL shouldLog = YES;
    
    if ( [self.delegate respondsToSelector:@selector(application:shouldLogError:)] ) {
        [self.delegate application:self shouldLogError:formattedString];
    }
    
    if ( shouldLog ) {
        [[NSFileHandle fileHandleWithStandardError] writeData: [[formattedString stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (void)logFormat:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    BOOL shouldLog = YES;
    
    if ( [self.delegate respondsToSelector:@selector(application:shouldLogString:)] ) {
        [self.delegate application:self shouldLogString:formattedString];
    }
    
    if ( shouldLog ) {
        [[NSFileHandle fileHandleWithStandardOutput] writeData: [[formattedString stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
}


@end