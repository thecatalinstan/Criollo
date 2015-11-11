//
//  ViewController.m
//  HelloWorld-iOS
//
//  Created by Cătălin Stan on 11/9/15.
//
//

#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController () <UITextViewDelegate>

@property (weak) AppDelegate* appDelegate;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setNeedsStatusBarAppearanceUpdate];

    self.appDelegate = [[UIApplication sharedApplication] delegate];
    [self.appDelegate addObserver:self forKeyPath:@"isConnected" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    [self.appDelegate addObserver:self forKeyPath:@"isDisconnected" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];

    [[NSNotificationCenter defaultCenter] addObserverForName:LogMessageNotificationName object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        dispatch_async(self.appDelegate.isolationQueue, ^{
            NSAttributedString* attributtedString = note.object;

            [self.logTextView.textStorage appendAttributedString:attributtedString];
            [self.logTextView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            [self.logTextView scrollRangeToVisible:NSMakeRange(self.logTextView.text.length-1, 0)];

//            self.statusDetailsButton.title = attributtedString.string;
        });
    }];

    self.logTextView.linkTextAttributes = self.appDelegate.linkTextAttributes;
    [self.logTextView scrollRectToVisible:CGRectZero animated:NO];
    [self.appDelegate startListening:nil];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.appDelegate.server closeAllConnections];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        if ( [keyPath isEqualToString:@"isConnected"] || [keyPath isEqualToString:@"isDisconnected"] ) {
            NSString* statusText = @"";
            NSString* statusImageName = @"NSStatusNone";
            if ( self.appDelegate.isDisconnected ) {
                statusText = @"Disconnected";
                statusImageName = @"NSStatusUnavailable";
            } else {
                if ( self.appDelegate.isConnected ) {
                    statusText = @"Connected. Waiting for requests ...";
                    statusImageName = @"NSStatusAvailable";
                } else {
                    statusText = @"";
                    statusImageName = @"NSStatusPartiallyAvailable";
                }
            }

            dispatch_async(self.appDelegate.isolationQueue, ^{
//                self.statusDetailsButton.title = statusText;
//                self.statusImageItem.image = [NSImage imageNamed:statusImageName];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), self.appDelegate.isolationQueue, ^{
                    dispatch_barrier_async(self.appDelegate.isolationQueue, ^{
//                        self.statusDetailsButton.title = self.appDelegate.isDisconnected ? @"Press + to start listening" : @"";
                    });
                });
            });
        }
    });

}

- (void)dealloc {
    [self.appDelegate removeObserver:self forKeyPath:@"isConnected"];
    [self.appDelegate removeObserver:self forKeyPath:@"isDisconnected"];
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return YES;
}

@end
