//
//  ViewController.m
//  HelloWorld-tvOS
//
//  Created by Cătălin Stan on 23/10/2017.
//

#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController () <UITextViewDelegate>

@property (weak) AppDelegate* appDelegate;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;
@property (weak, nonatomic) IBOutlet UIStackView *pathsStackView;

@property (weak) IBOutlet UIBarButtonItem *startItem;
@property (weak) IBOutlet UIBarButtonItem *stopItem;

@property (weak) IBOutlet UILabel *statusDetailsButton;

@property (assign) BOOL isScheduled;

@property (strong) NSDataDetector* linkChecker;

- (IBAction)startListening:(id)sender;
- (IBAction)stopListening:(id)sender;

@end

@implementation ViewController

- (dispatch_block_t)resetBlock {
    static dispatch_block_t resetBlock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        resetBlock = dispatch_block_create(DISPATCH_BLOCK_ASSIGN_CURRENT, ^{
            dispatch_barrier_async(self.appDelegate.isolationQueue, ^{
                self.statusDetailsButton.text = self.appDelegate.isDisconnected ? @"Press ▶︎ to start listening" : @"";
                [self.statusDetailsButton sizeToFit];
                self.isScheduled = NO;
            });
        });
    });
    return resetBlock;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
        });
    }];
    
    self.logTextView.linkTextAttributes = self.appDelegate.linkTextAttributes;
    [self.logTextView scrollRectToVisible:CGRectZero animated:NO];
        
    [self.appDelegate startListening:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.appDelegate.server closeAllConnections:nil];
}

- (void)startListening:(id)sender {
    [self.appDelegate startListening:sender];
}

- (void)stopListening:(id)sender {
    [self.appDelegate stopListening:sender];
}


- (NSDictionary *)logCommonAtributes {
    static NSDictionary* logCommonAtributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableParagraphStyle* style = [[NSMutableParagraphStyle alloc] init];
        style.lineHeightMultiple = 1.2;
        style.lineBreakMode = NSLineBreakByTruncatingMiddle;
        style.headIndent = 10.f;
        style.firstLineHeadIndent = 10.f;
        style.lineSpacing = 1.5f;
        
        NSMutableDictionary* tempDictionary = [NSMutableDictionary dictionaryWithDictionary:self.appDelegate.logDebugAtributes];
        tempDictionary[NSParagraphStyleAttributeName] = style;
        tempDictionary[NSFontAttributeName] = [UIFont fontWithName:@"Menlo" size:14.0f];
        
        
        logCommonAtributes = tempDictionary.copy;
    });
    return logCommonAtributes;
}

- (NSDictionary *)logResponseAtributes {
    static NSDictionary* logResponseAtributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary* tempDictionary = [NSMutableDictionary dictionaryWithDictionary:[self logCommonAtributes]];
        tempDictionary[NSForegroundColorAttributeName] = [UIColor whiteColor];
        logResponseAtributes = tempDictionary.copy;
    });
    return logResponseAtributes;
}

- (NSDictionary *)logErrorAtributes {
    static NSDictionary* logErrorAtributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary* tempDictionary = [NSMutableDictionary dictionaryWithDictionary:[self logCommonAtributes]];
        tempDictionary[NSForegroundColorAttributeName] = [UIColor redColor];
        logErrorAtributes = tempDictionary.copy;
    });
    return logErrorAtributes;
}

- (void)openURL:(UIButton *)sender {
    NSURL *url = [NSURL URLWithString: sender.titleLabel.text];
    
    NSError *error;
    NSString *response = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    NSDictionary *attributes = [self logResponseAtributes];
    if ( response == nil ) {
        response = error.localizedDescription;
        attributes = [self logErrorAtributes];
    }
    
    NSMutableAttributedString *attributtedString = [[NSMutableAttributedString alloc] initWithString:response attributes:attributes];
    [NSNotificationCenter.defaultCenter postNotificationName:LogMessageNotificationName object:attributtedString];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    [self.pathsStackView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    
    if ( [keyPath isEqualToString:@"isConnected"] || [keyPath isEqualToString:@"isDisconnected"] ) {
        
        if ( self.appDelegate.isConnected ) {
            NSArray<NSString *> *paths = [[self.appDelegate.server valueForKeyPath:@"routes.@distinctUnionOfObjects.path"] sortedArrayUsingSelector:@selector(compare:)];
            [paths enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ( [obj hasSuffix:@"screenshot"] )
                    return;
                UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                [button setTitle:[self.appDelegate.baseURL URLByAppendingPathComponent:[obj substringFromIndex:1]].absoluteString forState:UIControlStateNormal];
                [button addTarget:self action:@selector(openURL:) forControlEvents:UIControlEventAllEvents];
                [self.pathsStackView addArrangedSubview:button];
            }];
            [self.pathsStackView layoutSubviews];
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            
            
            NSString* statusText = @"";
            if ( self.appDelegate.isDisconnected ) {
                statusText = @"Disconnected";
            } else {
                if ( self.appDelegate.isConnected ) {
                    statusText = @"Connected. Waiting for requests ...";
                } else {
                    statusText = @"";
                }
            }
            
            
            if ( self.isScheduled ) {
                dispatch_block_cancel(self.resetBlock);
            }
            self.isScheduled = YES;
            dispatch_async(self.appDelegate.isolationQueue, ^{
                self.statusDetailsButton.text = statusText;
                [self.statusDetailsButton sizeToFit];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), self.appDelegate.isolationQueue, self.resetBlock);
                self.startItem.enabled = self.appDelegate.isDisconnected;
                self.stopItem.enabled = self.appDelegate.isConnected;
            });
        });
    }
}

- (void)dealloc {
    [self.appDelegate removeObserver:self forKeyPath:@"isConnected"];
    [self.appDelegate removeObserver:self forKeyPath:@"isDisconnected"];
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    return YES;
}

@end

