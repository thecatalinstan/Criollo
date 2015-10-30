
NSString* const FKRecordKey = @"FKRecord";
NSString* const FKSocketKey = @"FKSocket";
NSString* const FKDataKey = @"FKData";
NSString* const FKApplicationStatusKey = @"FKApplicationStatus";
NSString* const FKProtocolStatusKey = @"FKProtocolStatus";

- (void)finishRequest:(FCGIRequest*)request
{
	[self removeRequest:request];
    [request doneWithProtocolStatus:FCGI_REQUEST_COMPLETE applicationStatus:0];
}

- (void)finishRequestWithError:(NSDictionary*)userInfo
{
    FKHTTPResponse* httpResponse  = userInfo[FKResponseKey];
    NSError* error = userInfo[FKErrorKey];
    [self presentError:error];
    [httpResponse setHTTPStatus:500];
    [httpResponse finish];
}

-(void)handleRecord:(FCGIRecord*)record fromSocket:(GCDAsyncSocket *)socket
{
	
	if ([record isKindOfClass:[FCGIBeginRequestRecord class]]) {
		
		FCGIRequest* request = [[FCGIRequest alloc] initWithBeginRequestRecord:(FCGIBeginRequestRecord*)record];
		request.socket = socket;
		NSString* globalRequestId = [NSString stringWithFormat:@"%d-%d", record.requestId, socket.connectedPort];
		@synchronized(_currentRequests) {
			_currentRequests[globalRequestId] = request;
		}
		[socket readDataToLength:FCGIRecordFixedLengthPartLength withTimeout:FCGITimeout tag:FCGIRecordAwaitingHeaderTag];
		
	} else if ([record isKindOfClass:[FCGIParamsRecord class]]) {
		
		NSString* globalRequestId = [NSString stringWithFormat:@"%d-%d", record.requestId, [socket connectedPort]];
		FCGIRequest* request;
		@synchronized(_currentRequests) {
			request = _currentRequests[globalRequestId];
		}
		NSDictionary* params = [(FCGIParamsRecord*)record params];
		if ([params count] > 0) {
			[request.parameters addEntriesFromDictionary:params];
		} else {
			if ( _delegate && [_delegate respondsToSelector:@selector(application:didReceiveRequest:)] ) {
				[_delegate application:self didReceiveRequest:@{FKRequestKey: request}];
			}
		}
		[socket readDataToLength:FCGIRecordFixedLengthPartLength withTimeout:FCGITimeout tag:FCGIRecordAwaitingHeaderTag];
		
	} else if ([record isKindOfClass:[FCGIByteStreamRecord class]]) {
		
		NSString* globalRequestId = [NSString stringWithFormat:@"%d-%d", record.requestId, [socket connectedPort]];
		FCGIRequest* request;
		@synchronized(_currentRequests) {
			request = _currentRequests[globalRequestId];
		}
		NSData* data = [(FCGIByteStreamRecord*)record data];
		if ( [data length] > 0 ) {
			[request.stdinData appendData:data];
			[socket readDataToLength:FCGIRecordFixedLengthPartLength withTimeout:FCGITimeout tag:FCGIRecordAwaitingHeaderTag];
		} else {
			FKHTTPRequest* httpRequest = [FKHTTPRequest requestWithFCGIRequest:request];
			FKHTTPResponse* httpResponse = [FKHTTPResponse responseWithHTTPRequest:httpRequest];
			
			NSDictionary* userInfo = @{FKRequestKey: httpRequest, FKResponseKey: httpResponse};
			if ( [_delegate respondsToSelector:@selector(application:didPrepareResponse:)] ) {
				[_delegate application:self didPrepareResponse:userInfo];
			}
			
			// Determine the appropriate view controller
			NSString* requestURI = [self routeLookupURIForRequest:httpRequest];
			
			FKRoute* route = [[FKRoutingCenter sharedCenter] routeForRequestURI:requestURI];
			if ( route == nil ) {
				route = [[FKRoutingCenter sharedCenter] routeForRequestURI:@"/*"];
			}
			
			FKViewController* viewController = [self instantiateViewControllerForRoute:route userInfo:userInfo];
			if ( viewController != nil ) {
				
				if ( [_delegate respondsToSelector:@selector(application:presentViewController:)] ) {
					[_workerQueue addOperationWithBlock:^{
						@autoreleasepool {
							[_delegate application:self presentViewController:viewController];
						}
					}];
				}
				
			} else if ( [_delegate respondsToSelector:@selector(application:didNotFindViewController:)]) {

				[_workerQueue addOperationWithBlock:^{
					@autoreleasepool {
						[_delegate application:self didNotFindViewController:userInfo];
					}
				}];
				
			} else {
				
				[_workerQueue addOperationWithBlock:^{
					@autoreleasepool {
						NSString* errorDescription = [NSString stringWithFormat:@"No view controller for request URI: %@", httpRequest.parameters[@"DOCUMENT_URI"]];
						NSError* error = [NSError errorWithDomain:FKErrorDomain code:2 userInfo:@{NSLocalizedDescriptionKey: errorDescription, FKErrorFileKey: @__FILE__, FKErrorLineKey: @__LINE__}];
						NSMutableDictionary* finishRequestUserInfo = [NSMutableDictionary dictionaryWithDictionary:userInfo];
						finishRequestUserInfo[FKErrorKey] = error;
						[self finishRequestWithError:finishRequestUserInfo];
					}
				}];
				
			}
		}
	}
}


- (FKViewController *)instantiateViewControllerForRoute:(FKRoute *)route userInfo:(NSDictionary*)userInfo
{
	NSString* nibName = route.nibName == nil ? [NSStringFromClass(route.controllerClass) stringByReplacingOccurrencesOfString:@"Controller" withString:@""] : route.nibName;
	
	NSMutableDictionary* combinedUserInfo = [NSMutableDictionary dictionary];
	
	if ( userInfo ) {
		[combinedUserInfo addEntriesFromDictionary:userInfo];
	}
	
	if ( route.userInfo ){
		[combinedUserInfo addEntriesFromDictionary:route.userInfo];
	}
	
	FKViewController* controller = [[route.controllerClass alloc] initWithNibName:nibName bundle:[NSBundle mainBundle] userInfo:combinedUserInfo];
	
	return controller;
}

#pragma mark - GCDAsyncSocketDelegate


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	if (tag == FCGIRecordAwaitingHeaderTag) {
		FCGIRecord* record = [FCGIRecord recordWithHeaderData:data];
		if (record.contentLength == 0) {
			[self handleRecord:record fromSocket:sock];
		} else {
			dispatch_set_context(sock.delegateQueue, (void *)(CFBridgingRetain(record)));
			[sock readDataToLength:(record.contentLength + record.paddingLength) withTimeout:FCGITimeout tag:FCGIRecordAwaitingContentAndPaddingTag];
		}
	} else if (tag == FCGIRecordAwaitingContentAndPaddingTag) {
		FCGIRecord* record = CFBridgingRelease(dispatch_get_context(sock.delegateQueue));
		[record processContentData:data];
		[self handleRecord:record fromSocket:sock];
	}
}


@end