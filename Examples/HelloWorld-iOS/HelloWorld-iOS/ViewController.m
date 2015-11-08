//
//  ViewController.m
//  HelloWorld-iOS
//
//  Created by Cătălin Stan on 11/8/15.
//  Copyright © 2015 Catalin Stan. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *logTextView;

- (NSDictionary*)linkTextAttributes;

@end

@implementation ViewController

- (NSDictionary*)linkTextAttributes {
    static NSDictionary* _linkTextAttributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _linkTextAttributes = @{
                                NSForegroundColorAttributeName: [UIColor blueColor],
                                NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                                };
    });
    return _linkTextAttributes;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Eye-candy
    self.logTextView.text = nil;
    self.logTextView.attributedText = nil;
    self.logTextView.linkTextAttributes = self.linkTextAttributes;

    [self setNeedsStatusBarAppearanceUpdate];

    // Append message to the list
    [[NSNotificationCenter defaultCenter] addObserverForName:@"LogMessage" object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        NSAttributedString* attributedString = note.object;
        [self.logTextView.textStorage appendAttributedString:attributedString];
        [self.logTextView scrollRangeToVisible:NSMakeRange(self.logTextView.text.length, 0)];
    }];

}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
