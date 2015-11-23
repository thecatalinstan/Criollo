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

- (nonnull instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_DESIGNATED_INITIALIZER;

- (nonnull NSString*)presentViewControllerWithRequest:(nonnull CRRequest*)request response:(nonnull CRResponse*)response;

@end
