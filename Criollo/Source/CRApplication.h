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

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const Criollo;
FOUNDATION_EXPORT NSString * const CRErrorDomain;

typedef NSUInteger CRError;

@class CRApplication;

@protocol CRApplicationDelegate <NSObject>

@required
- (void)applicationDidFinishLaunching:(NSNotification *)notification;

@optional
- (void)applicationWillFinishLaunching:(NSNotification *)notification;

- (CRApplicationTerminateReply)applicationShouldTerminate:(CRApplication *)sender;
- (void)applicationWillTerminate:(NSNotification *)notification;

- (BOOL)application:(CRApplication *)application shouldLogError:(NSString*)errorString;
- (BOOL)application:(CRApplication *)application shouldLogString:(NSString*)string;

@end

FOUNDATION_EXPORT NSUInteger const CRErrorNone;
FOUNDATION_EXPORT NSUInteger const CRErrorSigTERM;

FOUNDATION_EXPORT NSString * const CRApplicationRunLoopMode;

FOUNDATION_EXPORT NSString * const CRApplicationWillFinishLaunchingNotification;
FOUNDATION_EXPORT NSString * const CRApplicationDidFinishLaunchingNotification;
FOUNDATION_EXPORT NSString * const CRApplicationWillTerminateNotification;

FOUNDATION_EXPORT id CRApp;
FOUNDATION_EXPORT int CRApplicationMain(int argc, const char * _Nullable argv[], id<CRApplicationDelegate> delegate);

@interface CRApplication : NSObject

@property (nonatomic, assign, nonnull) id<CRApplicationDelegate> delegate;

+ (CRApplication *)sharedApplication;

- (instancetype)initWithDelegate:(nullable id<CRApplicationDelegate>)delegate;

- (void)run;
- (void)stop:(nullable id)sender;
- (void)terminate:(nullable id)sender;
- (void)replyToApplicationShouldTerminate:(BOOL)shouldTerminate;

- (void)log:(NSString *)string;
- (void)logFormat:(NSString *)format, ...;
- (void)logFormat:(NSString *)format args:(va_list)args;

- (void)logError:(NSString *)string;
- (void)logErrorFormat:(NSString *)format, ...;
- (void)logErrorFormat:(NSString *)format args:(va_list)args;

@end
NS_ASSUME_NONNULL_END