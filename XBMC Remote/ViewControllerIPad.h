//
//  ViewControllerIPad.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 29/4/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MenuViewController;
@class StackScrollViewController;
@class UIViewExt;

@interface ViewControllerIPad : UIViewController {
	UIViewExt* rootView;
	UIView* leftMenuView;
	UIView* rightSlideView;
	
	MenuViewController* menuViewController;
	StackScrollViewController* stackScrollViewController;
	
}

@property (nonatomic, strong) NSMutableArray *mainMenu;
@property (nonatomic, retain) MenuViewController* menuViewController;
@property (nonatomic, retain) StackScrollViewController* stackScrollViewController;

@end
