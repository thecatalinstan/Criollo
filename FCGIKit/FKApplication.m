
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
	
	else if ([record isKindOfClass:[FCGIByteStreamRecord class]]) {
		
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

#pragma mark - GCDAsyncSocketDelegate


@end