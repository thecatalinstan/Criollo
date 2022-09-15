//
//  CRApplication.h
//
//
//  Created by Cătălin Stan on 4/24/13.
//

#import <Foundation/Foundation.h>

/**
 * These constants define wether a Criollo app should terminate or not and are
 * are used by the CRApplicationDelegate method `applicationShouldTerminate`.
 * 
 * @see https://developer.apple.com/reference/appkit/nsapplicationterminatereply
 */
typedef NS_ENUM(NSUInteger, CRApplicationTerminateReply) {
    CRTerminateCancel = 0,
    CRTerminateNow    = 1,
    CRTerminateLater  = 2
};

@class CRApplication;

NS_ASSUME_NONNULL_BEGIN

/**
 * The CRApplicationDelegate protocol defines the methods that may be implemented
 * by delegates of CRApplication objects. It is mean to mimic the behavior of 
 * NSApplicationDelegate.
 *
 * @see https://developer.apple.com/reference/appkit/nsapplicationdelegate
 */
@protocol CRApplicationDelegate

@required
/**
 * Sent by the default notification center after the application has been launched
 * and initialized but before it has received its first event.
 *
 * @param   notification    A notification named CRApplicationDidFinishLaunchingNotification.
 * Calling the `object` method of this notification returns the CRApplication
 * object itself.
 */
- (void)applicationDidFinishLaunching:(NSNotification *)notification;

@optional
/**
 * Sent by the default notification center immediately before the application
 * object is initialized.
 *
 * @param   notification    A notification named CRApplicationWillFinishLaunchingNotification.
 * Calling the `object` method of this notification returns the CRApplication
 * object itself.
 */
- (void)applicationWillFinishLaunching:(NSNotification *)notification;

- (CRApplicationTerminateReply)applicationShouldTerminate:(CRApplication *)sender;
- (void)applicationWillTerminate:(NSNotification *)notification;

@end

FOUNDATION_EXPORT NSNotificationName const CRApplicationWillFinishLaunchingNotification;
FOUNDATION_EXPORT NSNotificationName const CRApplicationDidFinishLaunchingNotification;
FOUNDATION_EXPORT NSNotificationName const CRApplicationWillTerminateNotification;

FOUNDATION_EXPORT id CRApp;
FOUNDATION_EXPORT int CRApplicationMain(int argc, const char * _Nullable argv[_Nullable], id<CRApplicationDelegate> delegate);

@interface CRApplication : NSObject

@property (nonatomic, readonly, weak) id<CRApplicationDelegate> delegate;
@property (class, nonatomic, readonly, strong) CRApplication *sharedApplication;

- (instancetype)initWithDelegate:(id<CRApplicationDelegate> _Nullable)delegate NS_DESIGNATED_INITIALIZER;

- (void)finishLaunching NS_REQUIRES_SUPER;

- (void)run;
- (void)stop:(id _Nullable)sender;
- (void)terminate:(id _Nullable)sender;
- (void)replyToApplicationShouldTerminate:(BOOL)shouldTerminate;

@end

NS_ASSUME_NONNULL_END
