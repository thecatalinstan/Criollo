//
//  FCGIEndRequestRecord.m
//  FCGIKit
//
//  Created by Magnus Nordlander on 2011-01-01.
//  Copyright (C) 2011 by Smiling Plants HB
// 
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "FCGIEndRequestRecord.h"


@implementation FCGIEndRequestRecord

@synthesize applicationStatus, protocolStatus;

- (instancetype)init {
    if ((self = [super init])) {
        // Initialization code here.
    }
    
    return self;
}


-(NSData*)protocolData
{
  NSMutableData* protocolData = [NSMutableData dataWithCapacity:1024];
  [protocolData appendData:[self headerProtocolData]];
  
  uint32 bigEndianApplicationStatus = EndianU32_NtoB(self.applicationStatus);
  [protocolData appendBytes:&bigEndianApplicationStatus length:4];
  
  [protocolData appendBytes:&protocolStatus length:1];
  
  unsigned char reserved = 0x00;
  [protocolData appendBytes:&reserved length:1];
  [protocolData appendBytes:&reserved length:1];
  [protocolData appendBytes:&reserved length:1];
  
  return protocolData;
}

@end
