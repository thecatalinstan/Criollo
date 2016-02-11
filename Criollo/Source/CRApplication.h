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

FOUNDATION_EXPORT NSString * _Nonnull const Criollo;
FOUNDATION_EXPORT NSString * _Nonnull const CRErrorDomain;

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

FOUNDATION_EXPORT NSString * _Nonnull const CRApplicationRunLoopMode;

FOUNDATION_EXPORT NSString * _Nonnull const CRApplicationWillFinishLaunchingNotification;
FOUNDATION_EXPORT NSString * _Nonnull const CRApplicationDidFinishLaunchingNotification;
FOUNDATION_EXPORT NSString * _Nonnull const CRApplicationWillTerminateNotification;

FOUNDATION_EXPORT id _Nonnull CRApp;
FOUNDATION_EXPORT int CRApplicationMain(int argc, const char * _Nullable argv[], id<CRApplicationDelegate> _Nonnull delegate);

@interface CRApplication : NSObject

@property (nonatomic, assign, nonnull) id<CRApplicationDelegate> delegate;

+ (nonnull CRApplication *)sharedApplication;

- (nonnull instancetype)initWithDelegate:(nullable id<CRApplicationDelegate>)delegate;

- (void)run;
- (void)stop:(nullable id)sender;
- (void)terminate:(nullable id)sender;
- (void)replyToApplicationShouldTerminate:(BOOL)shouldTerminate;

- (void)log:(nonnull NSString *)string;
- (void)logError:(nonnull NSString *)string;

- (void)logFormat:(nonnull NSString *)format, ...;
- (void)logErrorFormat:(nonnull NSString *)format, ...;

NS_ASSUME_NONNULL_BEGIN
- (void)logFormat:(nonnull NSString *)format args:(va_list)args;
- (void)logErrorFormat:(nonnull NSString *)format args:(va_list)args;
NS_ASSUME_NONNULL_END

@end