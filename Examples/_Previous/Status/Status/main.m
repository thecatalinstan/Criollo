//
//  main.m
//  Status
//
//  Created by Cătălin Stan on 10/04/15.
//  Copyright (c) 2015 Catalin Stan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <FCGIKit/FCGIKit.h>

#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    return FKApplicationMain(argc, argv, [AppDelegate new]);
}
