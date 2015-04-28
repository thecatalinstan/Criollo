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
				[_delegate application:self didReceiveRequest:@{CLRequestKey: request}];
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
			CLHTTPRequest* httpRequest = [CLHTTPRequest requestWithFCGIRequest:request];
			CLHTTPResponse* httpResponse = [CLHTTPResponse responseWithHTTPRequest:httpRequest];

			NSDictionary* userInfo = @{CLRequestKey: httpRequest, CLResponseKey: httpResponse};
			if ( [_delegate respondsToSelector:@selector(application:didPrepareResponse:)] ) {
				[_delegate application:self didPrepareResponse:userInfo];
			}

			// Determine the appropriate view controller
			NSString* requestURI = [self routeLookupURIForRequest:httpRequest];

			CLRoute* route = [[CLRoutingCenter sharedCenter] routeForRequestURI:requestURI];
			if ( route == nil ) {
				route = [[CLRoutingCenter sharedCenter] routeForRequestURI:@"/*"];
			}

			CLViewController* viewController = [self instantiateViewControllerForRoute:route userInfo:userInfo];
			if ( viewController != nil ) {

				if ( [_delegate respondsToSelector:@selector(application:presentViewController:)] ) {
					[_workerQueue addOperationWithBlock:^{
						[_delegate application:self presentViewController:viewController];
					}];
				}

			} else if ( [_delegate respondsToSelector:@selector(application:didNotFindViewController:)]) {

				[_workerQueue addOperationWithBlock:^{
					[_delegate application:self didNotFindViewController:userInfo];
				}];

			} else {

				[_workerQueue addOperationWithBlock:^{
					NSString* errorDescription = [NSString stringWithFormat:@"No view controller for request URI: %@", httpRequest.parameters[@"DOCUMENT_URI"]];
					NSError* error = [NSError errorWithDomain:CLErrorDomain code:2 userInfo:@{NSLocalizedDescriptionKey: errorDescription, CLErrorFileKey: @__FILE__, CLErrorLineKey: @__LINE__}];
					NSMutableDictionary* finishRequestUserInfo = [NSMutableDictionary dictionaryWithDictionary:userInfo];
					finishRequestUserInfo[CLErrorKey] = error;
					[self finishRequestWithError:finishRequestUserInfo.copy];
				}];

			}
		}
	}
}


- (NSString *)routeLookupURIForRequest:(CLHTTPRequest *)request
{
    NSString* returnURI = nil;
    if ( [_delegate respondsToSelector:@selector(routeLookupURIForRequest:)] ) {
        returnURI = [_delegate routeLookupURIForRequest:request];
    }
    if ( returnURI == nil ) {
        returnURI = request.parameters[@"DOCUMENT_URI"];
    }
    return returnURI;
}



- (CLViewController *)instantiateViewControllerForRoute:(CLRoute *)route userInfo:(NSDictionary*)userInfo
{
    NSString* nibName = route.nibName == nil ? [NSStringFromClass(route.controllerClass) stringByReplacingOccurrencesOfString:@"Controller" withString:@""] : route.nibName;
    
    NSMutableDictionary* combinedUserInfo = [NSMutableDictionary dictionary];
    
    if ( userInfo ) {
        [combinedUserInfo addEntriesFromDictionary:userInfo];
    }
    
    if ( route.userInfo ){
        [combinedUserInfo addEntriesFromDictionary:route.userInfo];
    }
    
    CLViewController* controller = [[route.controllerClass alloc] initWithNibName:nibName bundle:[NSBundle mainBundle] userInfo:combinedUserInfo];
    
    return controller;
}
