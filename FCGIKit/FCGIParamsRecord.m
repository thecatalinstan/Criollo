//
//  FCGIParamsRecord.m
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

#import "FCGIParamsRecord.h"


@implementation FCGIParamsRecord

@synthesize params;

- (instancetype)init {
    if ((self = [super init])) {
      self.params = [NSMutableDictionary dictionaryWithCapacity:20];
    }
    
    return self;
}

-(NSString*)description
{
  return [NSString stringWithFormat:@"FCGIParamsRecord - Params: %@, %@", self.params, [super description]];
}

-(void)processContentData:(NSData*)data
{
  uint8 pos0, pos1, pos4;
  uint8 valueLengthB3, valueLengthB2, valueLengthB1, valueLengthB0;
  uint8 nameLengthB3, nameLengthB2, nameLengthB1, nameLengthB0;
  
  uint32 nameLength, valueLength;
  NSString *name, *value;
  
  //Remove Padding
  NSMutableData* unpaddedData = [[data subdataWithRange:NSMakeRange(0, self.contentLength)] mutableCopy];
  while ([unpaddedData length] > 0)
  {
    [unpaddedData getBytes:&pos0 range:NSMakeRange(0, 1)];
    [unpaddedData getBytes:&pos1 range:NSMakeRange(1, 1)];
    [unpaddedData getBytes:&pos4 range:NSMakeRange(4, 1)];
    if (pos0 >> 7 == 0)
    {
      nameLength = pos0;
      // NameValuePair11 or 14
      if (pos1 >> 7 == 0)
      {
        //NameValuePair11
        valueLength = pos1;
        [unpaddedData replaceBytesInRange:NSMakeRange(0,2) withBytes:NULL length:0];
      }
      else
      {
        //NameValuePair14
        [unpaddedData getBytes:&valueLengthB3 range:NSMakeRange(1, 1)];
        [unpaddedData getBytes:&valueLengthB2 range:NSMakeRange(2, 1)];
        [unpaddedData getBytes:&valueLengthB1 range:NSMakeRange(3, 1)];
        [unpaddedData getBytes:&valueLengthB0 range:NSMakeRange(4, 1)];
        valueLength = ((valueLengthB3 & 0x7f) << 24) + (valueLengthB2 << 16) + (valueLengthB1 << 8) + valueLengthB0;
        [unpaddedData replaceBytesInRange:NSMakeRange(0,5) withBytes:NULL length:0];
      }
    }
    else
    {
      // NameValuePair41 or 44
      [unpaddedData getBytes:&nameLengthB3 range:NSMakeRange(0, 1)];
      [unpaddedData getBytes:&nameLengthB2 range:NSMakeRange(1, 1)];
      [unpaddedData getBytes:&nameLengthB1 range:NSMakeRange(2, 1)];
      [unpaddedData getBytes:&nameLengthB0 range:NSMakeRange(3, 1)];
      nameLength = ((nameLengthB3 & 0x7f) << 24) + (nameLengthB2 << 16) + (nameLengthB1 << 8) + nameLengthB0;

      if (pos4 >> 7 == 0)
      {
        //NameValuePair41
        valueLength = pos4;
        [unpaddedData replaceBytesInRange:NSMakeRange(0,5) withBytes:NULL length:0];
      }
      else
      {
        //NameValuePair44
        [unpaddedData getBytes:&valueLengthB3 range:NSMakeRange(4, 1)];
        [unpaddedData getBytes:&valueLengthB2 range:NSMakeRange(5, 1)];
        [unpaddedData getBytes:&valueLengthB1 range:NSMakeRange(6, 1)];
        [unpaddedData getBytes:&valueLengthB0 range:NSMakeRange(7, 1)];
        valueLength = ((valueLengthB3 & 0x7f) << 24) + (valueLengthB2 << 16) + (valueLengthB1 << 8) + valueLengthB0;
        [unpaddedData replaceBytesInRange:NSMakeRange(0,8) withBytes:NULL length:0];

      }
    }
    
    name = [[NSString alloc] initWithData:[unpaddedData subdataWithRange:NSMakeRange(0, nameLength)] encoding:NSASCIIStringEncoding];
    [unpaddedData replaceBytesInRange:NSMakeRange(0, nameLength) withBytes:NULL length:0];
    
    value = [[NSString alloc] initWithData:[unpaddedData subdataWithRange:NSMakeRange(0, valueLength)] encoding:NSASCIIStringEncoding];
    [unpaddedData replaceBytesInRange:NSMakeRange(0, valueLength) withBytes:NULL length:0];
    
    (self.params)[name] = value;
  }
}

@end
