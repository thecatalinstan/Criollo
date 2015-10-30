//
//  FCGIRecord.h
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

#import <Foundation/Foundation.h>
#import "FCGITypes.h"
#import <CoreServices/CoreServices.h>

/*typedef struct {
  unsigned char version;
  unsigned char type;
  unsigned char requestIdB1;
  unsigned char requestIdB0;
  unsigned char contentLengthB1;
  unsigned char contentLengthB0;
  unsigned char paddingLength;
  unsigned char reserved;
  unsigned char contentData[contentLength];
  unsigned char paddingData[paddingLength];
} FCGI_Record;*/

@interface FCGIRecord : NSObject {
@protected
  FCGIVersion version;
  FCGIRecordType type;
  FCGIRequestId requestId;
  FCGIContentLength contentLength;
  FCGIPaddingLength paddingLength;
}

@property (nonatomic, assign) FCGIVersion version;
@property (nonatomic, assign) FCGIRecordType type;
@property (nonatomic, assign) FCGIRequestId requestId;
@property (nonatomic, assign) FCGIContentLength contentLength;
@property (nonatomic, assign) FCGIPaddingLength paddingLength;

+(instancetype)recordWithHeaderData:(NSData*)data;
-(void)processContentData:(NSData*)data;
@property (nonatomic, readonly, copy) NSData *headerProtocolData;

@end
