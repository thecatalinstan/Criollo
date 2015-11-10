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

@end

@implementation WindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.appDelegate = [[NSApplication sharedApplication] delegate];

    [[NSNotificationCenter defaultCenter] addObserverForName:LogMessageNotificationName object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        dispatch_async(self.appDelegate.isolationQueue, ^{
            NSAttributedString* attributtedString = note.object;
            [self.logTextView.textStorage appendAttributedString:attributtedString];
            [self.logTextView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            [self.logTextView scrollRangeToVisible:NSMakeRange(self.logTextView.string.length - 1, 0)];
        });
    }];

    self.logTextView.linkTextAttributes = self.appDelegate.linkTextAttributes;

    [self.appDelegate startListening:nil];
}

@end
