//
//  CRApplication.h
//
//
//  Created by Cătălin Stan on 4/24/13.
//

#import <Foundation/Foundation.h>

/// These constants define wether a Criollo app should terminate or not and are
/// are used by the @c CRApplicationDelegate method @c -applicationShouldTerminate:
///
/// @see https://developer.apple.com/reference/appkit/nsapplicationterminatereply

typedef NS_ENUM(NSUInteger, CRApplicationTerminateReply)  {
    CRTerminateCancel = 0,
    CRTerminateNow    = 1,
    CRTerminateLater  = 2
} NS_SWIFT_NAME(Application.TerminateReply);

@class CRApplication;

NS_ASSUME_NONNULL_BEGIN

/// The @c CRApplicationDelegate protocol defines the methods that may be
/// implemented by delegates of @c CRApplication objects. It is meant to mimic
/// the behavior of @c NSApplicationDelegate.
///
/// @see https://developer.apple.com/reference/appkit/nsapplicationdelegate
NS_SWIFT_NAME(ApplicationDelegate)
@protocol CRApplicationDelegate

@required

/// Sent by the default notification center after the application has been launched
/// and initialized but before it has received its first event.
///
/// @param notification A notification named @c CRApplicationDidFinishLaunchingNotification. Calling the @c object method of this notification returns the @c CRApplication object itself.
- (void)applicationDidFinishLaunching:(NSNotification *)notification;

@optional

/// Sent by the default notification center immediately before the application
/// object is initialized.
///
/// @param notification A notification named @c CRApplicationWillFinishLaunchingNotification. Calling the @c object method of this notification returns the @c CRApplication object itself.
- (void)applicationWillFinishLaunching:(NSNotification *)notification;

/// Returns a value that indicates if the app should terminate.
///
/// @param sender The application object that is about to be terminated.
- (CRApplicationTerminateReply)applicationShouldTerminate:(CRApplication *)sender;

/// Tells the delegate that the app is about to terminate.
///
/// @param notification A notification named @c CRApplicationWillTerminateNotification. Calling the @c object method of this notification returns the @c CRApplication object itself.
- (void)applicationWillTerminate:(NSNotification *)notification;

@end

FOUNDATION_EXPORT NSNotificationName const CRApplicationWillFinishLaunchingNotification NS_SWIFT_NAME(criolloApplicationWillFinishLaunching);
FOUNDATION_EXPORT NSNotificationName const CRApplicationDidFinishLaunchingNotification NS_SWIFT_NAME(criolloApplicationDidFinishLaunching);
FOUNDATION_EXPORT NSNotificationName const CRApplicationWillTerminateNotification NS_SWIFT_NAME(criolloApplicationWillTerminate);

FOUNDATION_EXTERN __kindof CRApplication * _Null_unspecified CRApp;
FOUNDATION_EXTERN int CRApplicationMain(int argc, char * _Nullable argv[_Nonnull], id<CRApplicationDelegate> delegate) NS_REFINED_FOR_SWIFT;

NS_SWIFT_NAME(Application)
@interface CRApplication : NSObject

@property (nonatomic, readonly, weak) id<CRApplicationDelegate> delegate;

@property (class, nonatomic, readonly) CRApplication *sharedApplication;

- (instancetype)initWithDelegate:(id<CRApplicationDelegate> _Nullable)delegate NS_DESIGNATED_INITIALIZER;

- (void)finishLaunching NS_REQUIRES_SUPER;

- (void)run;
- (void)stop:(id _Nullable)sender;
- (void)terminate:(id _Nullable)sender;
- (void)replyToApplicationShouldTerminate:(BOOL)shouldTerminate;

@end

NS_ASSUME_NONNULL_END
