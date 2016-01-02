//
//  MessagesView.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 8/4/14.
//  Copyright (c) 2014 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MessagesView : UIView {
    NSTimer *fadeoutTimer;
    CGFloat slideHeight;
}

- (id)initWithFrame:(CGRect)frame deltaY:(float)deltaY deltaX:(float)deltaX;
- (void)showMessage:(NSString *)message timeout:(float)timeout color:(UIColor *)color;

@property (nonatomic, retain) UILabel *viewMessage;

@end
