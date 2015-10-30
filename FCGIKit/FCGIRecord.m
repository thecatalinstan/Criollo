//
//  FCGIRecord.m
//  FCGIKit
//
//  Created by Magnus Nordlander on 2010-12-31.
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

#import "FCGIRecord.h"
#import "FCGIBeginRequestRecord.h"
#import "FCGIParamsRecord.h"
#import "FCGIByteStreamRecord.h"

@implementation FCGIRecord

@synthesize version, type, requestId, contentLength, paddingLength;

-(instancetype)init {
    if ((self = [super init])) {
      
    }
    
    return self;
}

+(instancetype)recordWithHeaderData:(NSData*)data
{
  FCGIRecordType type;
  [data getBytes:&type range:NSMakeRange(1, 1)];
  
  FCGIRecord* record;
  
  switch(type)
  {
    case FCGI_BEGIN_REQUEST:
      record = [[FCGIBeginRequestRecord alloc] init];
    break;
    case FCGI_PARAMS:
      record = [[FCGIParamsRecord alloc] init];
    break;
    case FCGI_STDIN:
      record = [[FCGIByteStreamRecord alloc] init];
    break;
    default:
      record = nil;
  }
  
  record.type = type;
  
  FCGIVersion version;
  [data getBytes:&version range:NSMakeRange(0, 1)];
  record.version = version;

  FCGIPaddingLength paddingLength;
  [data getBytes:&paddingLength range:NSMakeRange(6, 1)];
  record.paddingLength = paddingLength;
  
  uint16 bigEndianRequestId;
  [data getBytes:&bigEndianRequestId range:NSMakeRange(2, 2)];
  record.requestId = EndianU16_BtoN(bigEndianRequestId);
  
  uint16 bigEndianContentLength;
  [data getBytes:&bigEndianContentLength range:NSMakeRange(4, 2)];
  record.contentLength = EndianU16_BtoN(bigEndianContentLength);

    return record;
}

-(void)processContentData:(NSData*)data
{

}

- (NSString*)description
{
  return [NSString stringWithFormat:@"Version: %d, Type: %d, Request-ID: %d, ContentLength: %d, PaddingLength: %d", self.version, self.type, self.requestId, self.contentLength, self.paddingLength];
}

-(NSData*)headerProtocolData
{
  NSMutableData* protocolData = [NSMutableData dataWithCapacity:1024];
  [protocolData appendBytes:&version length:1];
  [protocolData appendBytes:&type length:1];
  
  uint16 bigEndianRequestId = EndianU16_NtoB(self.requestId);
  [protocolData appendBytes:&bigEndianRequestId length:2];
  
  uint16 bigEndianContentLength = EndianU16_NtoB(self.contentLength);
  [protocolData appendBytes:&bigEndianContentLength length:2];
  
  [protocolData appendBytes:&paddingLength length:1];

  unsigned char reserved = 0x00;
  [protocolData appendBytes:&reserved length:1];

  return protocolData;
}


@end
