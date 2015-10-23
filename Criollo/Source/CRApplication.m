//
//  CRApplication.m
//  Criollo
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import <Criollo/CRApplication.h>
#import <Criollo/CRHTTPRequest.h>

#import "CRApplication+Internal.h"

NSString* const Criollo = @"Criollo";

NSString* const CRApplicationRunLoopMode = @"NSDefaultRunLoopMode";
NSString* const CRErrorDomain = @"CRErrorDomain";

NSUInteger const CRDefaultPortNumber = 1338;

NSString* const CRRequestKey = @"CRRequest";
NSString* const CRResponseKey = @"CRResponse";

NSString* const CRApplicationWillFinishLaunchingNotification = @"CRApplicationWillFinishLaunchingNotification";
NSString* const CRApplicationDidFinishLaunchingNotification = @"CRApplicationDidFinishLaunchingNotification";
NSString* const CRApplicationWillTerminateNotification = @"CRApplicationWillTerminateNotification";

CRApplication* CRApp;

int CRApplicationMain(int argc, char * const argv[], id<CRApplicationDelegate> delegate)
{
    @autoreleasepool {
        
        NSUserDefaults *args = [NSUserDefaults standardUserDefaults];
        
        NSString* interface = [args stringForKey:@"i"];
        if ( interface == nil ) {
            interface = [args stringForKey:@"interface"];
            if ( interface == nil ) {
                interface = @"";
            }
        }
        
        NSUInteger portNumber = [args integerForKey:@"p"];
        if ( portNumber == 0 ) {
            portNumber = [args integerForKey:@"port"];
            if ( portNumber == 0 ) {
                portNumber = CRDefaultPortNumber;
            }
        }
        portNumber = MIN(INT16_MAX, MAX(0, portNumber));
        
        (void)signal(SIGTERM, handleSIGTERM) ;
    
        CRApplication* app = [[CRApplication alloc] initWithDelegate:delegate portNumber:portNumber interface:interface];
        [app run];
        
    }
    return EXIT_SUCCESS;
}

@interface CRApplication () {
    __strong id<CRApplicationDelegate> _delegate;
    
    BOOL firstRunCompleted;
    BOOL waitingOnTerminateLaterReply;
    
    NSTimer* waitingOnTerminateLaterReplyTimer;
    CFRunLoopObserverRef mainRunLoopObserver;
}

@end

@implementation CRApplication

#pragma mark - Properties

- (id<CRApplicationDelegate>) delegate
{
    return _delegate;
}

- (void)setDelegate:(id<CRApplicationDelegate>)delegate
{
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

static NSArray* validHTTPMethods;

+ (void)initialize
{
    validHTTPMethods = @[@"GET",@"POST", @"PUT", @"DELETE"];
}

+ (CRApplication *)sharedApplication
{
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
    return [self initWithDelegate:nil portNumber:CRDefaultPortNumber interface:nil];
}

- (instancetype)initWithDelegate:(id<CRApplicationDelegate>)delegate
{
    return [self initWithDelegate:delegate portNumber:CRDefaultPortNumber interface:nil];
}

- (instancetype)initWithDelegate:(id<CRApplicationDelegate>)delegate portNumber:(NSUInteger)portNumber
{
    return [self initWithDelegate:nil portNumber:portNumber interface:nil];
}

- (instancetype)initWithDelegate:(id<CRApplicationDelegate>)delegate portNumber:(NSUInteger)portNumber interface:(NSString*)interface
{
    self = [super init];
    if ( self != nil ) {
        CRApp = self;
        
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
	[[NSNotificationCenter defaultCenter] postNotificationName:CRApplicationWillFinishLaunchingNotification object:self];
}

#pragma mark - Routing
- (BOOL)canHandleRequest:(CRHTTPRequest *)request
{
//    NSLog(@"%s %@", __PRETTY_FUNCTION__, request.method);
    BOOL canHandle = YES;
    if ( request.method == nil || ![validHTTPMethods containsObject:request.method.uppercaseString] ) {
        canHandle = NO;
    }
    return canHandle;
}

#pragma mark - Output

- (void)presentError:(NSError *)error
{
    [self logErrorFormat:error.localizedDescription];
}

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