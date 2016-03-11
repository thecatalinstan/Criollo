//
//  CRViewController.h
//  Criollo
//
//  Created by Cătălin Stan on 5/17/14.
//  Copyright (c) 2014 Catalin Stan. All rights reserved.
//

@class CRView, CRRequest, CRResponse;

#import "CRTypes.h"

@interface CRViewController : NSObject

@property (nonatomic, strong, nullable) IBOutlet CRView* view;

@property (nonatomic, strong, nonnull) NSMutableDictionary<NSString*, NSString*> *templateVariables;

@property (nonatomic, readonly, nonnull) NSString *nibName;
@property (nonatomic, readonly, nullable) NSBundle *nibBundle;

@property (nonatomic, readonly) BOOL shouldFinishResponse;
@property (nonatomic, readonly, nonnull) CRRouteBlock routeBlock;

- (nonnull instancetype)initWithNibName:(NSString * _Nullable)nibNameOrNil bundle:(NSBundle * _Nullable)nibBundleOrNil NS_DESIGNATED_INITIALIZER;

- (void)viewDidLoad;
- (nonnull NSString*)presentViewControllerWithRequest:(CRRequest * _Nonnull)request response:(CRResponse * _Nonnull)response;

@end
