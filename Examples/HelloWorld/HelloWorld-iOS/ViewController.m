//
//  ViewController.m
//  HelloWorld-iOS
//
//  Created by Cătălin Stan on 11/9/15.
//
//

#import <SafariServices/SafariServices.h>

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

- (void)adjustDetailsButtonSize;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setNeedsStatusBarAppearanceUpdate];

    UIBarButtonItem* statusBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.statusDetailsButton];

    NSMutableArray* newItems = self.toolbar.items.mutableCopy;
    [newItems addObject:statusBarButtonItem];
    self.toolbar.items = newItems;

    [self adjustDetailsButtonSize];

    self.appDelegate = [[UIApplication sharedApplication] delegate];
    [self.appDelegate addObserver:self forKeyPath:@"isConnected" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    [self.appDelegate addObserver:self forKeyPath:@"isDisconnected" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];

    NSError* linkCheckerError;
    self.linkChecker = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&linkCheckerError];

    [[NSNotificationCenter defaultCenter] addObserverForName:LogMessageNotificationName object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        dispatch_async(self.appDelegate.isolationQueue, ^{
            NSMutableAttributedString* attributtedString = [note.object mutableCopy];

            NSArray<NSTextCheckingResult*>* matches = [self.linkChecker matchesInString:attributtedString.string options:0 range:NSMakeRange(0, attributtedString.length)];
            [matches enumerateObjectsUsingBlock:^(NSTextCheckingResult * _Nonnull match, NSUInteger idx, BOOL * _Nonnull stop) {
                [attributtedString addAttribute:NSLinkAttributeName value:match.URL range:match.range];
            }];

            [self.logTextView.textStorage appendAttributedString:attributtedString];
            [self.logTextView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            [self.logTextView scrollRangeToVisible:NSMakeRange(self.logTextView.text.length, 0)];

            self.statusDetailsButton.text = attributtedString.string;
            [self adjustDetailsButtonSize];
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
                [self adjustDetailsButtonSize];
                self.statusImageItem.image = [UIImage imageNamed:statusImageName];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), self.appDelegate.isolationQueue, ^{
                    dispatch_barrier_async(self.appDelegate.isolationQueue, ^{
                        self.statusDetailsButton.text = self.appDelegate.isDisconnected ? @"Press + to start listening" : @"";
                        [self adjustDetailsButtonSize];
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
    NSLog(@"URL = %@", URL);
    if ( [SFSafariViewController class] != NULL ) {
        SFSafariViewController* safari = [[SFSafariViewController alloc] initWithURL:URL];
        safari.modalPresentationStyle = UIModalPresentationPageSheet;
        safari.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentViewController:safari animated:YES completion:^{}];
        return NO;
    } else {
        return YES;
    }
}

- (void)adjustDetailsButtonSize {
    CGFloat offset = 20;
    CGFloat edgeOffset = CGRectGetMinX( [[self.startItem valueForKey:@"view"] frame] );
    CGFloat toolbarWidth = CGRectGetWidth( self.toolbar.frame );
    CGFloat stopButtonRightEdge = CGRectGetMaxX( [[self.stopItem valueForKey:@"view"] frame] );
    CGFloat maxWidth = toolbarWidth - edgeOffset - offset - stopButtonRightEdge;

    CGFloat newWidth = MIN(maxWidth, [self.statusDetailsButton sizeThatFits:CGSizeMake(maxWidth, CGRectGetHeight(self.statusDetailsButton.frame))].width);
    CGRect newFrame = self.statusDetailsButton.frame;
    newFrame.size.width = newWidth;
    self.statusDetailsButton.frame = newFrame;

}

@end
