//
//  CLViewController.h
//  Criollo
//
//  Created by Cătălin Stan on 5/17/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLView, CLHTTPRequest, CLHTTPResponse;

@interface CLViewController : NSObject {
    CLView* _view;
    
    NSString* _nibName;
    NSBundle* _nibBundle;

    CLHTTPResponse* _response;
    CLHTTPRequest* _request;
    
    NSDictionary* _userInfo;
    
    NSMutableDictionary* variables;
}

@property (nonatomic, retain) IBOutlet CLView* view;

@property (nonatomic, readonly) NSString* nibName;
@property (nonatomic, readonly) NSBundle* nibBundle;
@property (nonatomic, retain) CLHTTPRequest* request;
@property (nonatomic, retain) CLHTTPResponse* response;
@property (nonatomic, retain) NSDictionary* userInfo;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil userInfo:(NSDictionary*)userInfo;

- (void)loadView;
- (void)viewDidLoad;

- (NSString*)presentViewController:(BOOL)writeData;

@property (nonatomic, readonly, copy) NSDictionary *allVariables;
- (void)addVariablesFromDictionary:(NSDictionary*)variablesDictionary;
- (void)removeAllVariables;
- (void)setObject:(id)object forVariableNamed:(NSString*)variableName;
- (void)setObjects:(NSArray*)objects forVariablesNamed:(NSArray*)variableNames;
- (void)removeVariableName:(NSString*)variableName;
- (void)removeVariablesNamed:(NSArray *)variableNames;

@property (nonatomic, readonly) BOOL automaticallyFinishesResponse;

@end
