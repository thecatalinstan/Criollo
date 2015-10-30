//
//  FCGIRequest.h
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
#import "GCDAsyncSocket.h"

#import "FCGITypes.h"
#import "FCGIBeginRequestRecord.h"
#import "FCGIByteStreamRecord.h"
#import "FCGIEndRequestRecord.h"
#import "FKApplication.h"

@interface FCGIRequest : NSObject {
@private
  FCGIRequestId requestId;
  FCGIRequestRole role;
  BOOL keepConnection;
  NSMutableDictionary* parameters;
  GCDAsyncSocket* socket;
  NSMutableData* stdinData;
}
@property (nonatomic, assign) FCGIRequestId requestId; 
@property (nonatomic, assign) FCGIRequestRole role; 
@property (nonatomic, assign) BOOL keepConnection;
@property (nonatomic, retain) NSMutableDictionary* parameters;
@property (nonatomic, retain) GCDAsyncSocket* socket;
@property (nonatomic, retain) NSMutableData* stdinData;

-(instancetype)initWithBeginRequestRecord:(FCGIBeginRequestRecord*)record;

-(void)writeDataToStdout:(NSData*)data;
-(void)writeDataToStderr:(NSData*)data;
-(void)doneWithProtocolStatus:(FCGIProtocolStatus)protocolStatus applicationStatus:(FCGIApplicationStatus)applicationStatus;
@end
