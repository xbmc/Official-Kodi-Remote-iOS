//
//  InitialSlidingViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 7/11/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "ECSlidingViewController.h"
#import "CustomNavigationController.h"

@interface InitialSlidingViewController : ECSlidingViewController {
    CustomNavigationController *navController;
}

@property (nonatomic, strong) NSMutableArray *mainMenu;

@end
