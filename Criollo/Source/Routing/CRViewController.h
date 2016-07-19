//
//  CRViewController.h
//  Criollo
//
//  Created by Cătălin Stan on 5/17/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

#import "CRTypes.h"

@class CRView, CRRequest, CRResponse;

NS_ASSUME_NONNULL_BEGIN

@interface CRViewController : NSObject

@property (nonatomic, strong, nullable) CRView* view;

@property (nonatomic, strong) NSMutableDictionary<NSString*, NSString*> *templateVariables;

@property (nonatomic, readonly) NSString *nibName;
@property (nonatomic, readonly, nullable) NSBundle *nibBundle;

@property (nonatomic, readonly) BOOL shouldFinishResponse;
@property (nonatomic, readonly) CRRouteBlock routeBlock;

- (instancetype)initWithNibName:(NSString * _Nullable)nibNameOrNil bundle:(NSBundle * _Nullable)nibBundleOrNil NS_DESIGNATED_INITIALIZER;

- (void)viewDidLoad;
- (NSString*)presentViewControllerWithRequest:(CRRequest *)request response:(CRResponse *)response;

@end

NS_ASSUME_NONNULL_END