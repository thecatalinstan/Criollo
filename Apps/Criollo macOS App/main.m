//
//  main.m
//  CriolloApp
//
//  Created by Cătălin Stan on 23/03/16.
//  Copyright © 2016 Cătălin Stan. All rights reserved.
//

#import "AppDelegate.h"



int main(int argc, const char * argv[]) {    
    @autoreleasepool {
        NSError *error;
        CRSocket *sock = [[CRSocket alloc] initWithDelegate:[AppDelegate new] delegateQueue:nil];
        if ( ![sock listen:nil port:10781 error:&error]) {
            NSLog(@"%@", error);
            return EXIT_FAILURE;
        }
        
        dispatch_main();
        
        return CRApplicationMain(argc, argv, [AppDelegate new]);
    }
}
