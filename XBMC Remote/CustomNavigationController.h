//
//  CustomNavigationController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 21/9/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomNavigationController : UINavigationController {
    UIImageView *navBarHairlineImageView;
}

- (void)hideNavBarBottomLine:(BOOL)hideBottomLine;

@end
