//
//  CLApplication+Internal.h
//  Criollo
//
//  Created by Cătălin Stan on 28/04/15.
//
//

#import <Criollo/CLApplication.h>
#import <Criollo/GCDAsyncSocket.h>

void handleSIGTERM(int signum);

@interface CLApplication (Internal)<GCDAsyncSocketDelegate>

- (void)quit;
- (void)cancelTermination;
- (void)waitingOnTerminateLaterReplyTimerCallback;

- (void)startListening;
- (void)stopListening;

- (void)startRunLoop;
- (void)stopRunLoop;

@end
