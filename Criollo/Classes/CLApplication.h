//
//  CLApplication.h
//  Criollo
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

typedef NS_ENUM(NSUInteger, CLApplicationTerminateReply) {
    CLTerminateCancel = 0,
    CLTerminateNow    = 1,
    CLTerminateLater  = 2
};

typedef NS_ENUM(NSUInteger, CLError) {
    CLErrorNone             = 0,
    CLErrorSigTERM          = 1007,
    CLErrorSocketError      = 2001,
};

@class CLApplication;

@protocol CLApplicationDelegate <NSObject>

@required
- (void)applicationDidFinishLaunching:(NSNotification *)notification;

@optional
- (void)applicationWillFinishLaunching:(NSNotification *)notification;

- (CLApplicationTerminateReply)applicationShouldTerminate:(CLApplication *)sender;
- (void)applicationWillTerminate:(NSNotification *)notification;

- (BOOL)application:(CLApplication*)application shouldLogError:(NSError*)error;
- (BOOL)application:(CLApplication*)application shouldLogString:(NSString*)string;

@end

extern NSString* const Criollo;

extern NSString* const CLApplicationRunLoopMode;

extern NSString* const CLErrorDomain;

extern NSUInteger const CLDefaultPortNumber;

extern NSString* const CLRequestKey;
extern NSString* const CLResponseKey;

extern NSString* const CLApplicationWillFinishLaunchingNotification;
extern NSString* const CLApplicationDidFinishLaunchingNotification;
extern NSString* const CLApplicationWillTerminateNotification;

@class CLHTTPRequest, CLHTTPResponse, GCDAsyncSocket;

extern id CLApp;
extern int CLApplicationMain(int argc, char * const argv[], id<CLApplicationDelegate> delegate);

@interface CLApplication : NSObject

@property (nonatomic, assign) id<CLApplicationDelegate> delegate;

@property (atomic, assign) NSUInteger portNumber;
@property (nonatomic, strong) NSString* interface;

@property (nonatomic, strong) GCDAsyncSocket* httpSocket;
@property (nonatomic, strong) NSMutableArray* connections;

@property (nonatomic, strong) NSOperationQueue* delegateQueue;
@property (nonatomic, strong) NSOperationQueue* workerQueue;


+ (CLApplication *)sharedApplication;

- (instancetype)initWithDelegate:(id<CLApplicationDelegate>)delegate;
- (instancetype)initWithDelegate:(id<CLApplicationDelegate>)delegate portNumber:(NSUInteger)portNumber;
- (instancetype)initWithDelegate:(id<CLApplicationDelegate>)delegate portNumber:(NSUInteger)portNumber interface:(NSString*)interface NS_DESIGNATED_INITIALIZER;

- (void)run;
- (void)stop:(id)sender;
- (void)terminate:(id)sender;
- (void)replyToApplicationShouldTerminate:(BOOL)shouldTerminate;

- (void)presentError:(NSError*)error;
- (void)logFormat:(NSString *)format, ...;

@end