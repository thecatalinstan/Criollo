//
//  NSData+CRLF.m
//  Criollo
//
//  Created by Cătălin Stan on 05/06/2021.
//  Copyright © 2021 Cătălin Stan. All rights reserved.
//

#import "NSData+CRLF.h"

@implementation NSData (CRLF)

static NSData *CRLF;
static NSData *CRLFCRLF;
static NSData *zeroCRLFCRLF;
static NSData *space;

+ (void)load {
    CRLF = [NSData dataWithBytes:"\x0D\x0A" length:2];
    CRLFCRLF = [NSData dataWithBytes:"\x0D\x0A\x0D\x0A" length:4];
    zeroCRLFCRLF = [NSData dataWithBytes:"\x30\x0D\x0A\x0D\x0A" length:5];
    space = [NSData dataWithBytes:"\x20" length:1];
}

+ (NSData *)CRLFCRLF {
    return CRLFCRLF;
}

+ (NSData *)CRLF {
    return CRLF;
}

+ (NSData *)zeroCRLFCRLF {
    return zeroCRLFCRLF;
}

+ (NSData *)space {
    return space;
}

@end
