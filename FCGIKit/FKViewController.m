//
//  FCGIKitViewController.m
//  FCGIKit
//
//  Created by Cătălin Stan on 5/17/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "FKApplication.h"
#import "FKViewController.h"
#import "FKView.h"
#import "FKNib.h"
#import "FKHTTPRequest.h"
#import "FKHTTPResponse.h"

@implementation FKViewController

@synthesize view = _view;
@synthesize nibBundle = _nibBundle;
@synthesize nibName = _nibName;
@synthesize response = _response;
@synthesize request = _request;
@synthesize userInfo = _userInfo;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil userInfo:nil];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil userInfo:(NSDictionary *)userInfo
{
    self = [self init];
    if ( self != nil ) {
        variables = [NSMutableDictionary dictionary];

        _nibName = nibNameOrNil;
        _nibBundle = nibBundleOrNil;
        _userInfo = userInfo;
		
		if ( userInfo[FKRequestKey] ) {
			_request = userInfo[FKRequestKey];
		}
		
		if ( userInfo[FKResponseKey] ) {
			_response = userInfo[FKResponseKey];
		}

        [self loadView];
    }
    return self;
}

- (void)loadView
{
    // Load the NIB file
    FKNib* templateNib = [FKNib cachedNibForNibName:self.nibName];
    if ( templateNib == nil ) {
        templateNib = [[FKNib alloc] initWithNibNamed:self.nibName bundle:self.nibBundle];
        if ( templateNib != nil ) {
            [FKNib cacheNib:templateNib forNibName:self.nibName];
        }
    }
    
    NSString* templateText = templateNib != nil ? [templateNib stringUsingEncoding:NSUTF8StringEncoding] : @"";
 
    // Determine the view class to use
    Class viewClass = NSClassFromString([self.className stringByReplacingOccurrencesOfString:@"Controller" withString:@""]);
	
    if ( viewClass == nil ) {
        viewClass = [FKView class];
    }
    FKView* view = [[viewClass alloc] initWithTemplateText:templateText];
    [self setView:view];
    
    [self viewDidLoad];
}

- (void)viewDidLoad
{
	
}

- (NSString *)presentViewController:(BOOL)writeData
{
    NSString* output = [self.view render:self.allVariables];
    if ( writeData ) {
        [self.response writeString:output];
		
		if ( self.automaticallyFinishesResponse ) {
			[self.response finish];
		}
    }
    return output;
}

- (BOOL)automaticallyFinishesResponse
{
	return YES;
}

- (NSDictionary *)allVariables
{
    return variables;
}

- (void)addVariablesFromDictionary:(NSDictionary *)variablesDictionary
{
    [variables addEntriesFromDictionary:variablesDictionary];
}

- (void)removeAllVariables
{
    [variables removeAllObjects];
}

- (void)setObject:(id)object forVariableNamed:(NSString*)variableName
{
    variables[variableName] = object;
}

- (void)setObjects:(NSArray*)objects forVariablesNamed:(NSArray*)variableNames
{
    [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        variables[variableNames[idx]] = obj;
    }];
}

- (void)removeVariableName:(NSString*)variableName
{
    [variables removeObjectForKey:variableName];
}

- (void)removeVariablesNamed:(NSArray *)variableNames
{
    [variables removeObjectsForKeys:variableNames];
}

@end
