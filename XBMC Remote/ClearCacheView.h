//
//  ClearCacheView.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 6/4/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ClearCacheView : UIView {
    UIActivityIndicatorView *busyView;
}

- (id)initWithFrame:(CGRect)frame border:(int)borderWidth;
-(void)startActivityIndicator;
-(void)stopActivityIndicator;

@end