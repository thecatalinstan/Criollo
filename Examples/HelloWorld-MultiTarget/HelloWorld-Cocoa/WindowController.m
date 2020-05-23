//
//  WindowController.m
//  HelloWorld
//
//  Created by Cătălin Stan on 11/10/15.
//
//

#import "WindowController.h"
#import "AppDelegate.h"

@interface WindowController ()

@property (weak) AppDelegate* appDelegate;
@property (unsafe_unretained) IBOutlet NSTextView *logTextView;
@property (weak) IBOutlet NSToolbarItem *statusImageItem;
@property (weak) IBOutlet NSButton *statusDetailsButton;

@property (strong) NSDataDetector* linkChecker;

@end

@implementation WindowController

- (void)windowDidLoad {
    [super windowDidLoad];

    self.appDelegate = [[NSApplication sharedApplication] delegate];
    [self.appDelegate addObserver:self forKeyPath:@"isConnected" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    [self.appDelegate addObserver:self forKeyPath:@"isDisconnected" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];

    NSError* linkCheckerError;
    self.linkChecker = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&linkCheckerError];

    [[NSNotificationCenter defaultCenter] addObserverForName:LogMessageNotificationName object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        dispatch_async(self.appDelegate.isolationQueue, ^{
            NSMutableAttributedString* attributtedString = [note.object mutableCopy];

            self.statusDetailsButton.title = attributtedString.string;

            NSArray<NSTextCheckingResult*>* matches = [self.linkChecker matchesInString:attributtedString.string options:0 range:NSMakeRange(0, attributtedString.length)];
            [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult * _Nonnull match, NSUInteger idx, BOOL * _Nonnull stop) {
                [attributtedString addAttribute:NSLinkAttributeName value:match.URL range:match.range];
            }];

            [self.logTextView.textStorage appendAttributedString:attributtedString];
            [self.logTextView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            [self.logTextView scrollRangeToVisible:NSMakeRange(self.logTextView.string.length, 0)];
        });
    }];

    self.window.titleVisibility = NSWindowTitleHidden;
    self.logTextView.linkTextAttributes = self.appDelegate.linkTextAttributes;
    self.logTextView.automaticLinkDetectionEnabled = YES;
    [self.logTextView scrollRectToVisible:NSZeroRect];

    [self.appDelegate startListening:nil];
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
                self.statusDetailsButton.title = statusText;
                self.statusImageItem.image = [NSImage imageNamed:statusImageName];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), self.appDelegate.isolationQueue, ^{
                    dispatch_barrier_async(self.appDelegate.isolationQueue, ^{
                        self.statusDetailsButton.title = self.appDelegate.isDisconnected ? NSLocalizedString(@"Press + to start listening",) : @"";
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

@end
