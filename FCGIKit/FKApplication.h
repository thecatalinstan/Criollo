//
//  FCGIApplication.h
//  FCGIKit
//
//  Created by Cătălin Stan on 4/24/13.
//  Copyright (c) 2013 Catalin Stan. All rights reserved.
//

#import "GCDAsyncSocket.h"

#import "FKApplicationDelegate.h"

#define FCGIRecordFixedLengthPartLength 8
#define FCGITimeout 5

extern NSString* const FKApplicationRunLoopMode;

extern NSString* const FCGIKit;

extern NSString* const FKErrorKey;
extern NSString* const FKErrorFileKey;
extern NSString* const FKErrorLineKey;
extern NSString* const FKErrorDomain;

extern NSString* const FKConnectionInfoKey;
extern NSString* const FKConnectionInfoPortKey;
extern NSString* const FKConnectionInfoInterfaceKey;

extern NSUInteger const FKDefaultPortNumber;

extern NSString* const FKRecordKey;
extern NSString* const FKSocketKey;
extern NSString* const FKDataKey;
extern NSString* const FKRequestKey;
extern NSString* const FKResponseKey;
extern NSString* const FKResultKey;
extern NSString* const FKApplicationStatusKey;
extern NSString* const FKProtocolStatusKey;

extern NSString* const FKRoutesKey;
extern NSString* const FKRoutePathKey;
extern NSString* const FKRouteControllerKey;
extern NSString* const FKRouteNibNameKey;
extern NSString* const FKRouteUserInfoKey;

extern NSString* const FKFileNameKey;
extern NSString* const FKFileTmpNameKey;
extern NSString* const FKFileSizeKey;
extern NSString* const FKFileContentTypeKey;

extern NSString* const FKApplicationWillFinishLaunchingNotification;
extern NSString* const FKApplicationDidFinishLaunchingNotification;
extern NSString* const FKApplicationWillTerminateNotification;

@class FCGIRequest, FKHTTPRequest, FKHTTPResponse;
@protocol AsyncSocketDelegate;

extern id FKApp;
extern int FKApplicationMain(int argc, const char **argv, id<FKApplicationDelegate> delegate);

@interface FKApplication : NSObject<GCDAsyncSocketDelegate> {
	NSObject<FKApplicationDelegate> *_delegate;
	NSUInteger _maxConnections;
	NSUInteger _portNumber;
	NSString* _listenIngInterface;

	BOOL _isListeningOnAllInterfaces;
	BOOL _isRunning;
		
	NSMutableDictionary* _environment;

	BOOL firstRunCompleted;
	BOOL shouldKeepRunning;
	BOOL isWaitingOnTerminateLaterReply;
		
	NSTimer* waitingOnTerminateLaterReplyTimer;
	CFRunLoopObserverRef mainRunLoopObserver;

	dispatch_queue_t _socketQueue;
	NSOperationQueue* _workerQueue;
	
	GCDAsyncSocket *_listenSocket;
	NSMutableArray* _connectedSockets;
	NSMutableDictionary* _currentRequests;

	NSArray* _startupArguments;

	NSMutableDictionary* _viewControllers;
}

@property (nonatomic, assign) NSObject<FKApplicationDelegate> *delegate;
@property (atomic, assign) NSUInteger maxConnections;
@property (atomic, assign) NSUInteger portNumber;
@property (nonatomic, retain) NSString* listeningInterface;
@property (atomic, readonly) BOOL isListeningOnAllInterfaces;
@property (atomic, readonly) BOOL isRunning;
@property (nonatomic, retain) GCDAsyncSocket* listenSocket;
@property (nonatomic, retain) NSMutableArray* connectedSockets;
@property (nonatomic, retain) NSMutableDictionary* currentRequests;
@property (nonatomic, readonly, retain) NSArray* startupArguments;
@property (nonatomic, retain) NSMutableDictionary* viewControllers;
@property (nonatomic, readonly, copy) NSDictionary *infoDictionary;
@property (nonatomic, readonly, copy) NSDictionary *dumpConfig;
@property (nonatomic, readonly, copy) NSString *temporaryDirectoryLocation;
@property (nonatomic, retain) NSOperationQueue *workerQueue;

+ (FKApplication *)sharedApplication;

- (instancetype) initWithArguments:(const char **)argv count:(int)argc;

- (void)terminate:(id)sender;
- (void)replyToApplicationShouldTerminate:(BOOL)shouldTerminate;

- (void)run;
- (void)stop:(id)sender;

- (void)presentError:(NSError*)error;

- (void)writeDataToStderr:(NSDictionary *)info;
- (void)writeDataToStdout:(NSDictionary *)info;
- (void)finishRequest:(FCGIRequest*)request;
- (void)finishRequestWithError:(NSDictionary*)userInfo;

@end