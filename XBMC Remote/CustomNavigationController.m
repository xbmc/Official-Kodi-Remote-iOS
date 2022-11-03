//
//  CustomNavigationController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 21/9/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "CustomNavigationController.h"

@interface CustomNavigationController ()

@end

@implementation CustomNavigationController

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        navBarHairlineImageView = [self findHairlineImageViewUnder:self.navigationBar];
    }
    return self;
}

- (UIImageView*)findHairlineImageViewUnder:(UIView*)view {
    if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
        return (UIImageView*)view;
    }
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self findHairlineImageViewUnder:subview];
        if (imageView) {
            return imageView;
        }
    }
    return nil;
}

- (void)hideNavBarBottomLine:(BOOL)hideBottomLine {
    if (navBarHairlineImageView == nil) {
        navBarHairlineImageView = [self findHairlineImageViewUnder:self.navigationBar];
    }
    navBarHairlineImageView.hidden = hideBottomLine;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotate {
    return NO;
}

@end
