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

@class CRApplication;

@protocol CRApplicationDelegate <NSObject>

@required
- (void)applicationDidFinishLaunching:(NSNotification *)notification;

@optional
- (void)applicationWillFinishLaunching:(NSNotification *)notification;

- (CRApplicationTerminateReply)applicationShouldTerminate:(CRApplication *)sender;
- (void)applicationWillTerminate:(NSNotification *)notification;

- (BOOL)application:(CRApplication*)application shouldLogError:(NSString*)errorString;
- (BOOL)application:(CRApplication*)application shouldLogString:(NSString*)string;

@end

FOUNDATION_EXPORT NSUInteger const CRErrorNone;
FOUNDATION_EXPORT NSUInteger const CRErrorSigTERM;

FOUNDATION_EXPORT NSString* const CRApplicationRunLoopMode;

FOUNDATION_EXPORT NSString* const CRApplicationWillFinishLaunchingNotification;
FOUNDATION_EXPORT NSString* const CRApplicationDidFinishLaunchingNotification;
FOUNDATION_EXPORT NSString* const CRApplicationWillTerminateNotification;

FOUNDATION_EXPORT id CRApp;
FOUNDATION_EXPORT int CRApplicationMain(int argc, char * const argv[], id<CRApplicationDelegate> delegate);

@interface CRApplication : NSObject

@property (nonatomic, assign) id<CRApplicationDelegate> delegate;

+ (CRApplication *)sharedApplication;

- (instancetype)initWithDelegate:(id<CRApplicationDelegate>)delegate;

- (void)run;
- (void)stop:(id)sender;
- (void)terminate:(id)sender;
- (void)replyToApplicationShouldTerminate:(BOOL)shouldTerminate;

- (void)logFormat:(NSString *)format, ...;
- (void)logErrorFormat:(NSString *)format, ...;

@end