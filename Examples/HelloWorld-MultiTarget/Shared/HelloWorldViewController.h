//
//  HelloWorldViewController.h
//  HelloWorld-ObjC
//
//  Created by Cătălin Stan on 11/23/15.
//  Copyright © 2015 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <CriolloiOS/CriolloiOS.h>
#else
#import <Criollo/Criollo.h>
#endif

@interface HelloWorldViewController : CRViewController

@end
