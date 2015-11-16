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
@property (weak, nonatomic) IBOutlet UITextView *logTextView;

@property (weak) IBOutlet UIBarButtonItem *statusImageItem;
@property (weak) IBOutlet UIBarButtonItem *startItem;
@property (weak) IBOutlet UIBarButtonItem *stopItem;

@property (weak) IBOutlet UIToolbar *toolbar;

@property (weak) IBOutlet UILabel *statusDetailsButton;

@property (strong) NSDataDetector* linkChecker;

- (IBAction)startListening:(id)sender;
- (IBAction)stopListening:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setNeedsStatusBarAppearanceUpdate];

    UIBarButtonItem* statusBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.statusDetailsButton];

    NSMutableArray* newItems = self.toolbar.items.mutableCopy;
    [newItems addObject:statusBarButtonItem];
    self.toolbar.items = newItems;

    [self.statusDetailsButton sizeToFit];

    self.appDelegate = [[UIApplication sharedApplication] delegate];
    [self.appDelegate addObserver:self forKeyPath:@"isConnected" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    [self.appDelegate addObserver:self forKeyPath:@"isDisconnected" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];

    NSError* linkCheckerError;
    self.linkChecker = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&linkCheckerError];

    [[NSNotificationCenter defaultCenter] addObserverForName:LogMessageNotificationName object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        dispatch_async(self.appDelegate.isolationQueue, ^{
            NSMutableAttributedString* attributtedString = [note.object mutableCopy];
            NSRange attributedStringRange = NSMakeRange(self.logTextView.text.length, attributtedString.length);

            NSArray<NSTextCheckingResult*>* matches = [self.linkChecker matchesInString:attributtedString.string options:0 range:NSMakeRange(0, attributtedString.length)];
            [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult * _Nonnull match, NSUInteger idx, BOOL * _Nonnull stop) {
                [attributtedString addAttribute:NSLinkAttributeName value:match.URL range:match.range];
            }];

            [self.logTextView.textStorage appendAttributedString:attributtedString];
            [self.logTextView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            [self.logTextView scrollRangeToVisible:attributedStringRange];

            self.statusDetailsButton.text = attributtedString.string;
            [self.statusDetailsButton sizeToFit];
        });
    }];

    self.logTextView.linkTextAttributes = self.appDelegate.linkTextAttributes;
    [self.logTextView scrollRectToVisible:CGRectZero animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.appDelegate.server closeAllConnections];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)startListening:(id)sender {
    [self.appDelegate startListening:sender];
}

- (void)stopListening:(id)sender {
    [self.appDelegate stopListening:sender];
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
                self.statusDetailsButton.text = statusText;
                [self.statusDetailsButton sizeToFit];
                self.statusImageItem.image = [UIImage imageNamed:statusImageName];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), self.appDelegate.isolationQueue, ^{
                    dispatch_barrier_async(self.appDelegate.isolationQueue, ^{
                        self.statusDetailsButton.text = self.appDelegate.isDisconnected ? @"Press + to start listening" : @"";
                        [self.statusDetailsButton sizeToFit];
                    });
                });
                self.startItem.enabled = self.appDelegate.isDisconnected;
                self.stopItem.enabled = self.appDelegate.isConnected;
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
