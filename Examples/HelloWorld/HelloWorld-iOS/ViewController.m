//
//  ViewController.m
//  HelloWorld-iOS
//
//  Created by Cătălin Stan on 11/9/15.
//
//

#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController ()

@property (weak) AppDelegate* appDelegate;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.appDelegate = [[UIApplication sharedApplication] delegate];

    [[NSNotificationCenter defaultCenter] addObserverForName:LogMessageNotificationName object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        dispatch_async(self.appDelegate.isolationQueue, ^{
            NSAttributedString* attributtedString = note.object;
            [self.logTextView.textStorage appendAttributedString:attributtedString];
            [self.logTextView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            [self.logTextView scrollRangeToVisible:NSMakeRange(self.logTextView.text.length - 1, 0)];
        });
    }];

    self.logTextView.linkTextAttributes = self.appDelegate.linkTextAttributes;

    [self.appDelegate startListening:nil];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
