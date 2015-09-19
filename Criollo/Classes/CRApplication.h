//
//  CRApplication.h
//  Criollo
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//


/*!
 @abstract Logs the user in or authorizes additional permissions.
 @param permissions the optional array of permissions. Note this is converted to NSSet and is only
 an NSArray for the convenience of literal syntax.
 @param fromViewController the view controller to present from. If nil, the topmost view controller will be
 automatically determined as best as possible.
 @param handler the callback.
 @discussion Use this method when asking for read permissions. You should only ask for permissions when they
 are needed and explain the value to the user. You can inspect the result.declinedPermissions to also
 provide more information to the user if they decline permissions.
 
 If `[FBSDKAccessToken currentAccessToken]` is not nil, it will be treated as a reauthorization for that user
 and will pass the "rerequest" flag to the login dialog.
 
 This method will present UI the user. You typically should check if `[FBSDKAccessToken currentAccessToken]`
 already contains the permissions you need before asking to reduce unnecessary app switching. For example,
 you could make that check at viewDidLoad.
 */


typedef NS_ENUM(NSUInteger, CRApplicationTerminateReply) {
    CRTerminateCancel = 0,
    CRTerminateNow    = 1,
    CRTerminateLater  = 2
};

typedef NS_ENUM(NSUInteger, CRError) {
    CRErrorNone             = 0,
    CRErrorSigTERM          = 1007,
    CRErrorSocketError      = 2001,
    
    CRErrorRequestMalformedRequest = 3001,
    CRErrorRequestUnsupportedMethod = 3002,
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

extern NSString* const Criollo;

extern NSString* const CRApplicationRunLoopMode;

extern NSString* const CRErrorDomain;

extern NSUInteger const CRDefaultPortNumber;

extern NSString* const CRRequestKey;
extern NSString* const CRResponseKey;

extern NSString* const CRApplicationWillFinishLaunchingNotification;
extern NSString* const CRApplicationDidFinishLaunchingNotification;
extern NSString* const CRApplicationWillTerminateNotification;

@class CRHTTPRequest, CRHTTPResponse, GCDAsyncSocket;

extern id CRApp;
extern int CRApplicationMain(int argc, char * const argv[], id<CRApplicationDelegate> delegate);

@interface CRApplication : NSObject

@property (nonatomic, assign) id<CRApplicationDelegate> delegate;

@property (atomic, assign) NSUInteger portNumber;
@property (nonatomic, strong) NSString* interface;

@property (nonatomic, strong) GCDAsyncSocket* httpSocket;
@property (nonatomic, strong) NSMutableArray* connections;

@property (nonatomic, strong) dispatch_queue_t delegateQueue;
@property (nonatomic, strong) NSOperationQueue* workerQueue;

+ (CRApplication *)sharedApplication;

- (instancetype)initWithDelegate:(id<CRApplicationDelegate>)delegate;
- (instancetype)initWithDelegate:(id<CRApplicationDelegate>)delegate portNumber:(NSUInteger)portNumber;
- (instancetype)initWithDelegate:(id<CRApplicationDelegate>)delegate portNumber:(NSUInteger)portNumber interface:(NSString*)interface NS_DESIGNATED_INITIALIZER;

- (void)run;
- (void)stop:(id)sender;
- (void)terminate:(id)sender;
- (void)replyToApplicationShouldTerminate:(BOOL)shouldTerminate;

- (BOOL)canHandleRequest:(CRHTTPRequest*)request;

- (void)presentError:(NSError*)error;
- (void)logErrorFormat:(NSString *)format, ...;
- (void)logFormat:(NSString *)format, ...;

@end