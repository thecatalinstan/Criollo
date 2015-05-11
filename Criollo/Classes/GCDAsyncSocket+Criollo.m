//
//  GCDAsyncSocket+Criollo.m
//  Criollo
//
//  Created by Cătălin Stan on 11/05/15.
//
//

#import "GCDAsyncSocket+Criollo.h"

@implementation GCDAsyncSocket (Criollo)

+ (NSData *)CRLFCRLFData
{
    return [NSData dataWithBytes:"\x0D\x0A\x0D\x0A" length:4];
}

@end
