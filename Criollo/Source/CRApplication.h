//
//  CRApplication.h
//  Criollo
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

typedef NS_ENUM(NSUInteger, CRApplicationTerminateReply) {
    CRTerminateCancel = 0,
    CRTerminateNow    = 1,
    CRTerminateLater  = 2
};

FOUNDATION_EXPORT NSString * __nonnull const Criollo;
FOUNDATION_EXPORT NSString * __nonnull const CRErrorDomain;

typedef NSUInteger CRError;

@class CRApplication;

@protocol CRApplicationDelegate <NSObject>

@required
- (void)applicationDidFinishLaunching:(nonnull NSNotification *)notification;

@optional
- (void)applicationWillFinishLaunching:(nonnull NSNotification *)notification;

- (CRApplicationTerminateReply)applicationShouldTerminate:(nonnull CRApplication *)sender;
- (void)applicationWillTerminate:(nonnull NSNotification *)notification;

- (BOOL)application:(nonnull CRApplication *)application shouldLogError:(nonnull NSString*)errorString;
- (BOOL)application:(nonnull CRApplication *)application shouldLogString:(nonnull NSString*)string;

@end

FOUNDATION_EXPORT NSUInteger const CRErrorNone;
FOUNDATION_EXPORT NSUInteger const CRErrorSigTERM;

FOUNDATION_EXPORT NSString * __nonnull const CRApplicationRunLoopMode;

FOUNDATION_EXPORT NSString * __nonnull const CRApplicationWillFinishLaunchingNotification;
FOUNDATION_EXPORT NSString * __nonnull const CRApplicationDidFinishLaunchingNotification;
FOUNDATION_EXPORT NSString * __nonnull const CRApplicationWillTerminateNotification;

FOUNDATION_EXPORT id __nonnull CRApp;
FOUNDATION_EXPORT int CRApplicationMain(int argc, const char * __nullable argv[], id<CRApplicationDelegate> __nonnull delegate);

@interface CRApplication : NSObject

@property (nonatomic, assign, nonnull) id<CRApplicationDelegate> delegate;

+ (nonnull CRApplication *)sharedApplication;

- (nonnull instancetype)initWithDelegate:(nullable id<CRApplicationDelegate>)delegate;

- (void)run;
- (void)stop:(nullable id)sender;
- (void)terminate:(nullable id)sender;
- (void)replyToApplicationShouldTerminate:(BOOL)shouldTerminate;

- (void)log:(nonnull NSString *)string;
- (void)logFormat:(nonnull NSString *)format, ...;
- (void)logFormat:(nonnull NSString *)format args:(va_list)args;

- (void)logError:(nonnull NSString *)string;
- (void)logErrorFormat:(nonnull NSString *)format, ...;
- (void)logErrorFormat:(nonnull NSString *)format args:(va_list)args;

@end