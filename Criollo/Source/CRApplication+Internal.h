//
//  CRApplication+Internal.h
//  Criollo
//
//  Created by Cătălin Stan on 28/04/15.
//
//

#import <Criollo/CRApplication.h>
#import <Criollo/GCDAsyncSocket.h>

void handleSIGTERM(int signum);

@class CRHTTPConnection;

@interface CRApplication (Internal)<GCDAsyncSocketDelegate>

- (void)quit;
- (void)cancelTermination;
- (void)waitingOnTerminateLaterReplyTimerCallback;

- (void)startListening;
- (void)stopListening;

- (void)startRunLoop;
- (void)stopRunLoop;

- (void)didCloseConnection:(CRHTTPConnection*)connection;

@end
