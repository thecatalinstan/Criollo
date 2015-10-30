//
//  FCGIRequest.m
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

#import "FCGIRequest.h"

@implementation FCGIRequest

@synthesize requestId, role, keepConnection, parameters, socket, stdinData;

- (instancetype)initWithBeginRequestRecord:(FCGIBeginRequestRecord *)record {
    if ( (self = [super init]) ) {
      self.requestId = record.requestId;
      self.role = record.role;
      self.keepConnection = ((record.flags & FCGI_KEEP_CONN) != 0);
      
      self.parameters = [NSMutableDictionary dictionaryWithCapacity:20];
      self.stdinData = [NSMutableData dataWithCapacity:1024];
    }
    
    return self;
}

-(void)writeDataToStderr:(NSData*)data
{
	NSUInteger length = data.length;
	NSUInteger chunkSize = FCGI_SOCKET_BUFFER;
	NSUInteger offset = 0;
	
	do {
		NSUInteger thisChunkSize = length - offset > chunkSize ? chunkSize : length - offset;
		NSData* chunk = [NSData dataWithBytesNoCopy:(char *)data.bytes + offset length:thisChunkSize freeWhenDone:NO];
		offset += thisChunkSize;
		
		FCGIByteStreamRecord* stdErrRecord = [[FCGIByteStreamRecord alloc] init];
		stdErrRecord.version = FCGI_VERSION_1;
		stdErrRecord.type = FCGI_STDERR;
		stdErrRecord.requestId = self.requestId;
		stdErrRecord.contentLength = chunk.length;
		stdErrRecord.paddingLength = 0;
		stdErrRecord.data = chunk;
		
		[self.socket writeData:stdErrRecord.protocolData withTimeout:-1 tag:0];
		
		chunk = nil;
		
	} while (offset < length);
	
	data = nil;
}

-(void)writeDataToStdout:(NSData*)data
{
	NSUInteger length = data.length;
	NSUInteger chunkSize = FCGI_SOCKET_BUFFER;
	NSUInteger offset = 0;
	
	do {
		NSUInteger thisChunkSize = length - offset > chunkSize ? chunkSize : length - offset;
		NSData* chunk = [NSData dataWithBytesNoCopy:(char *)data.bytes + offset length:thisChunkSize freeWhenDone:NO];
		offset += thisChunkSize;

		FCGIByteStreamRecord* stdOutRecord = [[FCGIByteStreamRecord alloc] init];
		stdOutRecord.version = FCGI_VERSION_1;
		stdOutRecord.type = FCGI_STDOUT;
		stdOutRecord.requestId = self.requestId;
		stdOutRecord.contentLength = chunk.length;
		stdOutRecord.paddingLength = 0;
		stdOutRecord.data = chunk;
		
		[self.socket writeData:stdOutRecord.protocolData withTimeout:-1 tag:0];
		
		chunk = nil;
		
	} while (offset < length);
	
	data = nil;
	
}

-(void)doneWithProtocolStatus:(FCGIProtocolStatus)protocolStatus applicationStatus:(FCGIApplicationStatus)applicationStatus
{
    FCGIEndRequestRecord* endRequestRecord = [[FCGIEndRequestRecord alloc] init];
    endRequestRecord.version = FCGI_VERSION_1;
    endRequestRecord.type = FCGI_END_REQUEST;
    endRequestRecord.requestId = self.requestId;
    endRequestRecord.contentLength = 8;
    endRequestRecord.paddingLength = 0;
    endRequestRecord.applicationStatus = applicationStatus;
    endRequestRecord.protocolStatus = protocolStatus;

    [self.socket writeData:[endRequestRecord protocolData] withTimeout:-1 tag:0];

    if (!keepConnection) {
        [self.socket disconnectAfterWriting];
    } else {
        [self.socket readDataToLength:FCGIRecordFixedLengthPartLength withTimeout:FCGITimeout tag:FCGIRecordAwaitingHeaderTag];
    }
}


@end
