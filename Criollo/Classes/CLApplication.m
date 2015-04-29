//
//  CLApplication.m
//  Criollo
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import <Criollo/CLApplication.h>

#import "CLApplication+Internal.h"

NSString* const Criollo = @"Criollo";

NSString* const CLApplicationRunLoopMode = @"NSDefaultRunLoopMode";
NSString* const CLErrorDomain = @"CLErrorDomain";

NSUInteger const CLDefaultPortNumber = 10070;

NSString* const CLRequestKey = @"CLRequest";
NSString* const CLResponseKey = @"CLResponse";

NSString* const CLApplicationWillFinishLaunchingNotification = @"CLApplicationWillFinishLaunchingNotification";
NSString* const CLApplicationDidFinishLaunchingNotification = @"CLApplicationDidFinishLaunchingNotification";
NSString* const CLApplicationWillTerminateNotification = @"CLApplicationWillTerminateNotification";

CLApplication* CLApp;

int CLApplicationMain(int argc, char * const argv[], id<CLApplicationDelegate> delegate)
{
    NSString* interface;
    NSUInteger portNumber = CLDefaultPortNumber;
    int opt;
    while ( ( opt = getopt (argc, argv, "i:p:") ) != -1) {
        switch (opt) {
            case 'i':
                interface = [NSString stringWithCString:optarg encoding:NSASCIIStringEncoding];
                break;
            case 'p':
                portNumber = [NSString stringWithCString:optarg encoding:NSASCIIStringEncoding].integerValue;
                portNumber = MIN(INT16_MAX, MAX(0, portNumber));
                break;
            case '?':
                if (optopt == 'c' || optopt == 'p') {
                    fprintf (stderr, "Option -%c requires an argument.\n", optopt);
                    exit(EXIT_FAILURE);
                }
        }
    }
    
    (void)signal(SIGTERM, handleSIGTERM) ;
    
    @autoreleasepool {
        CLApplication* app = [[CLApplication alloc] initWithDelegate:delegate portNumber:portNumber interface:interface];
        [app run];
    }
    return EXIT_SUCCESS;
}

@interface CLApplication () {
    __strong id<CLApplicationDelegate> _delegate;
    
    BOOL firstRunCompleted;
    BOOL waitingOnTerminateLaterReply;
    
    NSTimer* waitingOnTerminateLaterReplyTimer;
    CFRunLoopObserverRef mainRunLoopObserver;
}

@end

@implementation CLApplication

#pragma mark - Properties

- (id<CLApplicationDelegate>) delegate
{
    return _delegate;
}

- (void)setDelegate:(id<CLApplicationDelegate>)delegate
{
    if ( _delegate ) {
        [[NSNotificationCenter defaultCenter] removeObserver:_delegate];
        _delegate = nil;
    }
    
    _delegate = delegate;
    
    if ( [_delegate respondsToSelector:@selector(applicationWillFinishLaunching:)] ) {
        [[NSNotificationCenter defaultCenter] addObserver:_delegate selector:@selector(applicationWillFinishLaunching:) name:CLApplicationWillFinishLaunchingNotification object:nil];
    }
    if ( [_delegate respondsToSelector:@selector(applicationDidFinishLaunching:)] ) {
        [[NSNotificationCenter defaultCenter] addObserver:_delegate selector:@selector(applicationDidFinishLaunching:) name:CLApplicationDidFinishLaunchingNotification object:nil];
    }
    if ( [_delegate respondsToSelector:@selector(applicationWillTerminate:)] ) {
        [[NSNotificationCenter defaultCenter] addObserver:_delegate selector:@selector(applicationWillTerminate:) name:CLApplicationWillTerminateNotification object:nil];
    }
}

#pragma mark - Initialization

+ (CLApplication *)sharedApplication
{
	Class class;
	if( ! CLApp ) {
		if( ! ( class = [NSBundle mainBundle].principalClass ) ) {
			NSLog(@"Main bundle does not define an existing principal class: %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSPrincipalClass"]);
			class = self;
		}
		if( ! [class isSubclassOfClass:self.class] ) {
			NSLog(@"Principal class (%@) of main bundle is not subclass of %@", NSStringFromClass(class), NSStringFromClass(self.class) );
		}
		[class new];
	}

	return CLApp;
}

- (instancetype)init {
    return [self initWithDelegate:nil portNumber:CLDefaultPortNumber interface:nil];
}

- (instancetype)initWithDelegate:(id<CLApplicationDelegate>)delegate
{
    return [self initWithDelegate:delegate portNumber:CLDefaultPortNumber interface:nil];
}

- (instancetype)initWithDelegate:(id<CLApplicationDelegate>)delegate portNumber:(NSUInteger)portNumber
{
    return [self initWithDelegate:nil portNumber:portNumber interface:nil];
}

- (instancetype)initWithDelegate:(id<CLApplicationDelegate>)delegate portNumber:(NSUInteger)portNumber interface:(NSString*)interface
{
    self = [super init];
    if ( self != nil ) {
        CLApp = self;
        
        self.portNumber = portNumber;
        self.interface = interface;
        self.connections = [NSMutableArray array];
        
        self.delegate = delegate;
    }
    return self;
}

#pragma mark - Lifecycle

- (void)terminate:(id)sender
{
	// Stop the main run loop
    [self performSelectorOnMainThread:@selector(stop:) withObject:nil waitUntilDone:YES];
    
    CLApplicationTerminateReply reply = CLTerminateNow;
    
    if ( [_delegate respondsToSelector:@selector(applicationShouldTerminate:)]) {
        reply = [_delegate applicationShouldTerminate:self];
    }
    
    switch ( reply ) {
        case CLTerminateCancel:
            [self cancelTermination];
            break;
            
        case CLTerminateLater:
            waitingOnTerminateLaterReply = YES;
            waitingOnTerminateLaterReplyTimer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(waitingOnTerminateLaterReplyTimerCallback) userInfo:nil repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:waitingOnTerminateLaterReplyTimer forMode:CLApplicationRunLoopMode];
            while (waitingOnTerminateLaterReply && [[NSRunLoop mainRunLoop] runMode:CLApplicationRunLoopMode beforeDate:[NSDate distantFuture]]);
            break;
            
        case CLTerminateNow:
        default:
            [self quit];
            break;
    }

}

- (void)replyToApplicationShouldTerminate:(BOOL)shouldTerminate
{
    waitingOnTerminateLaterReply = NO;
    [waitingOnTerminateLaterReplyTimer invalidate];
    
    [self performSelectorOnMainThread:@selector(stop:) withObject:nil waitUntilDone:YES];
    
    if ( shouldTerminate ) {        
        [self quit];
    } else {
        [self cancelTermination];
    }
}

- (void)run
{
    [self finishLaunching];
    [self startRunLoop];
    [self terminate:nil];
}

- (void)stop:(id)sender
{
    CFRunLoopStop([[NSRunLoop mainRunLoop] getCFRunLoop]);
}

- (void)finishLaunching
{
	// Let observers know that initialization is complete
	[[NSNotificationCenter defaultCenter] postNotificationName:CLApplicationWillFinishLaunchingNotification object:self];
}

#pragma mark - Output

- (void)presentError:(NSError *)error
{
    BOOL shouldPresent = YES;
    
    if ( [self.delegate respondsToSelector:@selector(application:shouldLogError:)] ) {
        shouldPresent = [self.delegate application:self shouldLogError:error];
    }
    
    if ( shouldPresent ) {
        [[NSFileHandle fileHandleWithStandardError] writeData:[[error.localizedDescription stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
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