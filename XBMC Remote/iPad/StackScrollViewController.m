/*
 This module is licenced under the BSD license.
 
 Copyright (C) 2011 by raw engineering <nikhil.jain (at) raweng (dot) com, reefaq.mohammed (at) raweng (dot) com>.
 
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
//
//  StackScrollViewController.m
//  SlidingView
//
//  Created by Reefaq on 2/24/11.
//  Copyright 2011 raw engineering . All rights reserved.
//

#import "StackScrollViewController.h"
#import "AppDelegate.h"
#import "RemoteControllerGestureZoneView.h"
#import "OBSlider.h"
#import "Utilities.h"
#import <QuartzCore/QuartzCore.h>

#define VIEW_TAG 1000
#define SLIDE_VIEWS_MINUS_X_POSITION -200 /* Lets two stacks slightly overlap in landscape. */
#define SLIDE_VIEWS_START_X_POS 0
#define STACK_OVERLAP 53
#define SLIDE_TRANSITION_TIME 0.2

@implementation StackScrollViewController

@synthesize slideViews, borderViews, viewControllersStack, slideStartPosition;

- (id)init {
    if (self = [super init]) {
        
        bottomPadding = [Utilities getBottomPadding];
        
        viewControllersStack = [NSMutableArray new];
        borderViews = [[UIView alloc] initWithFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION - 2, -2, 2, self.view.frame.size.height + 2)];
        borderViews.backgroundColor = UIColor.clearColor;
        borderViews.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        UIView *verticalLineView1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, borderViews.frame.size.height)];
        verticalLineView1.backgroundColor = UIColor.whiteColor;
        verticalLineView1.tag = 1 + VIEW_TAG;
        verticalLineView1.hidden = YES;
        verticalLineView1.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        [borderViews addSubview:verticalLineView1];
        
        UIView *verticalLineView2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, borderViews.frame.size.height)];
        verticalLineView2.backgroundColor = UIColor.grayColor;
        verticalLineView2.tag = 2 + VIEW_TAG;
        verticalLineView2.hidden = YES;
        verticalLineView2.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        [borderViews addSubview:verticalLineView2];
        
        [self.view addSubview:borderViews];
        
        slideViews = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - bottomPadding)];
        slideViews.backgroundColor = UIColor.clearColor;
        self.view.backgroundColor = UIColor.clearColor;
        self.view.frame = slideViews.frame;
        self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        viewXPosition = 0;
        lastTouchPoint = -1;
        
        dragDirection = [NSString new];
        dragDirection = @"";
        
        viewAtLeft2 = nil;
        viewAtLeft = nil;
        viewAtRight = nil;
        viewAtRight2 = nil;
        viewAtRightAtTouchBegan = nil;
        
        UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
        panRecognizer.delegate = self;
        panRecognizer.maximumNumberOfTouches = 1;
        panRecognizer.delaysTouchesBegan = YES;
        panRecognizer.delaysTouchesEnded = YES;
        panRecognizer.cancelsTouchesInView = YES;
        [self.view addGestureRecognizer:panRecognizer];
        [self.view addSubview:slideViews];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleStackScrollFullScreenEnabled:)
                                                     name: @"StackScrollFullScreenEnabled"
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleStackScrollFullScreenDisabled:)
                                                     name: @"StackScrollFullScreenDisabled"
                                                   object: nil];
    }
    
    return self;
}

- (void)handleStackScrollFullScreenEnabled:(NSNotification*)sender {
    UIView *senderView = nil;
    if ([[sender object] isKindOfClass:[UIView class]]) {
        senderView = [sender object];
    }
    hideToolbar = [[sender.userInfo objectForKey:@"hideToolbar"] boolValue];
    BOOL clipsToBounds = [[sender.userInfo objectForKey:@"clipsToBounds"] boolValue];
    NSTimeInterval duration = [[sender.userInfo objectForKey:@"duration"] doubleValue];
    if (!duration) {
        duration = 1.5;
    }
    if (clipsToBounds) {
        senderView.clipsToBounds = YES;
    }
    stackScrollIsFullscreen = YES;
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        int i = 0;
        // Find the view requesting fullscreen and expand the frame
        for (UIView *subview in slideViews.subviews) {
            if ([subview isEqual:[sender object]]) {
                fullscreenView = subview;
                originalFrame = subview.frame;
                CGRect frame = subview.frame;
                frame.origin.x = 0 - PAD_MENU_TABLE_WIDTH;
                if (hideToolbar) {
                    CGFloat statusbarHeight = [Utilities getTopPadding];
                    frame.origin.y -= statusbarHeight;
                    frame.size.height += statusbarHeight;
                }
                frame.size.width = self.view.frame.size.width + PAD_MENU_TABLE_WIDTH;
                subview.frame = frame;
                break;
            }
            i++;
        }
        
        // Remove all views right of the fullscreen
        NSInteger numViews = slideViews.subviews.count;
        for (int j = i + 1; j < numViews; j++) {
            [slideViews.subviews[i + 1] removeFromSuperview];
        }
    }
                     completion:^(BOOL finished) {}
    ];
}

- (void)handleStackScrollFullScreenDisabled:(NSNotification*)sender {
    UIView *senderView = nil;
    if ([[sender object] isKindOfClass:[UIView class]]) {
        senderView = [sender object];
    }
    NSTimeInterval duration = [[sender.userInfo objectForKey:@"duration"] doubleValue];
    if (!duration) {
        duration = 1.5;
    }
    senderView.clipsToBounds = NO;
    stackScrollIsFullscreen = NO;
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        int i = 0;
        // Find the view leaving fullscreen and restore the frame
        for (UIView *subview in slideViews.subviews) {
            if ([subview isEqual:[sender object]]) {
                fullscreenView = nil;
                CGRect frame = subview.frame;
                frame.origin.x = 0;
                frame.origin.y = 0;
                frame.size.height = self.view.frame.size.height;
                frame.size.width = originalFrame.size.width;
                subview.frame = frame;
                break;
            }
            i++;
        }
    }
                     completion:^(BOOL finished) {}
    ];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch {
    if ([touch.view isKindOfClass:[UIButton class]] || [touch.view isKindOfClass:[RemoteControllerGestureZoneView class]] || [touch.view isKindOfClass:[OBSlider class]] || [touch.view isKindOfClass:[UISlider class]] || [touch.view isKindOfClass:NSClassFromString(@"UITableViewCellReorderControl")]) {
        return NO;
    }
    return YES;
}

- (void)disablePanGestureRecognizer:(UIImageView*)fallbackView {
    return;
}

- (void)enablePanGestureRecognizer {
    return;
}

- (void)arrangeVerticalBar {
    if (slideViews.subviews.count > 2) {
        [borderViews viewWithTag:2 + VIEW_TAG].hidden = YES;
        [borderViews viewWithTag:1 + VIEW_TAG].hidden = YES;
        NSInteger stackCount = 0;
        if (viewAtLeft != nil) {
            stackCount = [slideViews.subviews indexOfObject:viewAtLeft];
        }
        
        if (viewAtLeft != nil && viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION) {
            stackCount += 1;
        }
        
        if (stackCount == 2) {
            [borderViews viewWithTag:2 + VIEW_TAG].hidden = NO;
        }
        if (stackCount >= 3) {
            [borderViews viewWithTag:2 + VIEW_TAG].hidden = NO;
            [borderViews viewWithTag:1 + VIEW_TAG].hidden = NO;
        }
    }
}

- (void)offView {
    CGFloat posX = (IS_PORTRAIT ? GET_MAINSCREEN_WIDTH : GET_MAINSCREEN_HEIGHT) - PAD_MENU_TABLE_WIDTH;
    
    [UIView transitionWithView:self.view
                      duration:SLIDE_TRANSITION_TIME
                       options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionTransitionNone
                    animations:^{
        for (UIView *subview in slideViews.subviews) {
            subview.frame = CGRectMake(posX,
                                       viewAtLeft.frame.origin.y,
                                       viewAtLeft.frame.size.width,
                                       viewAtLeft.frame.size.height);
        }
        [borderViews viewWithTag:3 + VIEW_TAG].hidden = YES;
        [borderViews viewWithTag:2 + VIEW_TAG].hidden = YES;
        [borderViews viewWithTag:1 + VIEW_TAG].hidden = YES;
        viewAtLeft2 = nil;
        viewAtRight = nil;
        viewAtLeft = nil;
        viewAtRight2 = nil;
    }
                    completion:^(BOOL finished) {
        for (UIView *subview in slideViews.subviews) {
            [subview removeFromSuperview];
        }
        [borderViews viewWithTag:3 + VIEW_TAG].hidden = YES;
        [borderViews viewWithTag:2 + VIEW_TAG].hidden = YES;
        [borderViews viewWithTag:1 + VIEW_TAG].hidden = YES;
        [viewControllersStack removeAllObjects];
        [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollOffScreen" object: nil];
    }];
}

- (void)changeFrame:(UIView*)view originX:(CGFloat)originX {
    CGRect frame = view.frame;
    frame.origin.x = originX;
    view.frame = frame;
}

- (void)changeFrame:(UIView*)view originX:(CGFloat)originX height:(CGFloat)height {
    CGRect frame = view.frame;
    frame.origin.x = originX;
    frame.size.height = height;
    view.frame = frame;
}

- (void)cardDrop {
    NSInteger viewControllerCount = viewControllersStack.count;
    if (viewControllerCount > 1) {
        for (int i = 1; i < viewControllerCount; i++) {
            viewXPosition = self.view.frame.size.width - [slideViews viewWithTag:i + VIEW_TAG].frame.size.width;
            [[slideViews viewWithTag:i + VIEW_TAG] removeFromSuperview];
            [viewControllersStack removeLastObject];
        }
        [borderViews viewWithTag:3 + VIEW_TAG].hidden = YES;
        [borderViews viewWithTag:2 + VIEW_TAG].hidden = YES;
        [borderViews viewWithTag:1 + VIEW_TAG].hidden = YES;
    }
    // Removes the selection of row for the first slide view
    for (UIView* tableView in slideViews.subviews[0].subviews) {
        if ([tableView isKindOfClass:[UIView class]]) {
            for (UIView* tableView2 in tableView.subviews) {
                if ([tableView2 isKindOfClass:[UITableView class]]) {
                    NSIndexPath* selectedRow = [(UITableView*)tableView2 indexPathForSelectedRow];
                    [(UITableView*)tableView2 deselectRowAtIndexPath:selectedRow animated:YES];
                }
                if ([tableView2 isKindOfClass:[UICollectionView class]]) {
                    for (NSIndexPath* selection in [(UICollectionView*)tableView2 indexPathsForSelectedItems]) {
                        [(UICollectionView*)tableView2 deselectItemAtIndexPath:selection animated:YES];
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollCardDropNotification" object: nil];
                }
            }
        }
        if ([tableView isKindOfClass:[UITableView class]]) {
            NSIndexPath* selectedRow = [(UITableView*)tableView indexPathForSelectedRow];
            [(UITableView*)tableView deselectRowAtIndexPath:selectedRow animated:YES];
        }
        if ([tableView isKindOfClass:[UICollectionView class]]) {
            for (NSIndexPath* selection in [(UICollectionView*)tableView indexPathsForSelectedItems]) {
                [(UICollectionView*)tableView deselectItemAtIndexPath:selection animated:YES];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollCardDropNotification" object: nil];
        }
    }
    viewAtLeft2 = nil;
    viewAtRight = nil;
    viewAtRight2 = nil;
}

- (void)handlePanFrom:(UIPanGestureRecognizer*)recognizer {
    if (stackScrollIsFullscreen) {
        return;
    }
    CGPoint translatedPoint = [recognizer translationInView:self.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        displacementPosition = 0;
        positionOfViewAtRightAtTouchBegan = viewAtRight.frame.origin;
        positionOfViewAtLeftAtTouchBegan = viewAtLeft.frame.origin;
        viewAtRightAtTouchBegan = viewAtRight;
        viewAtLeftAtTouchBegan = viewAtLeft;
        [viewAtLeft.layer removeAllAnimations];
        [viewAtRight.layer removeAllAnimations];
        [viewAtRight2.layer removeAllAnimations];
        [viewAtLeft2.layer removeAllAnimations];
        if (viewAtLeft2 != nil) {
            NSInteger viewAtLeft2Position = [slideViews.subviews indexOfObject:viewAtLeft2];
            if (viewAtLeft2Position > 0) {
                slideViews.subviews[viewAtLeft2Position - 1].hidden = NO;
            }
        }
        [self arrangeVerticalBar];
    }
    
    CGPoint location = [recognizer locationInView:self.view];
    
    if (lastTouchPoint != -1) {
        if (location.x < lastTouchPoint) {
            if ([dragDirection isEqualToString:@"RIGHT"]) {
                positionOfViewAtRightAtTouchBegan = viewAtRight.frame.origin;
                positionOfViewAtLeftAtTouchBegan = viewAtLeft.frame.origin;
                displacementPosition = translatedPoint.x * -1;
            }
            
            dragDirection = @"LEFT";
            
            if (viewAtRight != nil) {
                
                if (viewAtLeft.frame.origin.x <= SLIDE_VIEWS_MINUS_X_POSITION) {
                    if ([slideViews.subviews indexOfObject:viewAtRight] < slideViews.subviews.count - 1) {
                        viewAtLeft2 = viewAtLeft;
                        viewAtLeft = viewAtRight;
                        viewAtRight2.hidden = NO;
                        viewAtRight = viewAtRight2;
                        if ([slideViews.subviews indexOfObject:viewAtRight] < slideViews.subviews.count - 1) {
                            viewAtRight2 = slideViews.subviews[[slideViews.subviews indexOfObject:viewAtRight] + 1];
                        }
                        else {
                            viewAtRight2 = nil;
                        }
                        positionOfViewAtRightAtTouchBegan = viewAtRight.frame.origin;
                        positionOfViewAtLeftAtTouchBegan = viewAtLeft.frame.origin;
                        displacementPosition = translatedPoint.x * -1;
                        if ([slideViews.subviews indexOfObject:viewAtLeft2] > 1) {
                            slideViews.subviews[[slideViews.subviews indexOfObject:viewAtLeft2] - 2].hidden = YES;
                        }
                    }
                }
                
                CGFloat atRightDisplacement = positionOfViewAtRightAtTouchBegan.x + translatedPoint.x + displacementPosition;
                if (viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION && CGRectGetMaxX(viewAtRight.frame) > self.view.frame.size.width) {
                    CGFloat originX = MAX(atRightDisplacement, self.view.frame.size.width - viewAtRight.frame.size.width);
                    [self changeFrame:viewAtRight
                              originX:originX];
                }
                else if (([slideViews.subviews indexOfObject:viewAtRight] == slideViews.subviews.count - 1) && viewAtRight.frame.origin.x <= (self.view.frame.size.width - viewAtRight.frame.size.width)) {
                    CGFloat originX = MAX(atRightDisplacement, SLIDE_VIEWS_MINUS_X_POSITION);
                    [self changeFrame:viewAtRight
                              originX:originX];
                }
                else {
                    CGFloat atLeftDisplacement = positionOfViewAtLeftAtTouchBegan.x + translatedPoint.x + displacementPosition;
                    CGFloat originX = MAX(atLeftDisplacement, SLIDE_VIEWS_MINUS_X_POSITION);
                    [self changeFrame:viewAtLeft
                              originX:originX];
                    [self changeFrame:viewAtRight
                              originX:CGRectGetMaxX(viewAtLeft.frame)];
                    
                    if (viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION) {
                        positionOfViewAtRightAtTouchBegan = viewAtRight.frame.origin;
                        positionOfViewAtLeftAtTouchBegan = viewAtLeft.frame.origin;
                        displacementPosition = translatedPoint.x * -1;
                    }
                }
            }
            else {
                CGFloat atLeftDisplacement = positionOfViewAtLeftAtTouchBegan.x + translatedPoint.x + displacementPosition;
                [self changeFrame:viewAtLeft
                          originX:atLeftDisplacement];
            }
            [self arrangeVerticalBar];
        }
        else if (location.x > lastTouchPoint) {
            if ([dragDirection isEqualToString:@"LEFT"]) {
                positionOfViewAtRightAtTouchBegan = viewAtRight.frame.origin;
                positionOfViewAtLeftAtTouchBegan = viewAtLeft.frame.origin;
                displacementPosition = translatedPoint.x;
            }
            
            dragDirection = @"RIGHT";
            
            if (viewAtLeft != nil) {
                if (viewAtRight.frame.origin.x >= self.view.frame.size.width) {
                    if ([slideViews.subviews indexOfObject:viewAtLeft] > 0) {
                        viewAtRight2.hidden = YES;
                        viewAtRight2 = viewAtRight;
                        viewAtRight = viewAtLeft;
                        viewAtLeft = viewAtLeft2;
                        if ([slideViews.subviews indexOfObject:viewAtLeft] > 0) {
                            viewAtLeft2 = slideViews.subviews[[slideViews.subviews indexOfObject:viewAtLeft] - 1];
                            viewAtLeft2.hidden = NO;
                        }
                        else {
                            viewAtLeft2 = nil;
                        }
                        positionOfViewAtRightAtTouchBegan = viewAtRight.frame.origin;
                        positionOfViewAtLeftAtTouchBegan = viewAtLeft.frame.origin;
                        displacementPosition = translatedPoint.x;
                        [self arrangeVerticalBar];
                    }
                }
                
                CGFloat atRightDisplacement = positionOfViewAtRightAtTouchBegan.x + translatedPoint.x - displacementPosition;
                CGFloat overlapLeftRight = viewAtRight.frame.origin.x - viewAtLeft.frame.size.width;
                if (viewAtRight.frame.origin.x < CGRectGetMaxX(viewAtLeft.frame) && viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION) {
                    CGFloat originX = MIN(atRightDisplacement, CGRectGetMaxX(viewAtLeft.frame));
                    [self changeFrame:viewAtRight
                              originX:originX];
                }
                else if ([slideViews.subviews indexOfObject:viewAtLeft] == 0) {
                    if (viewAtRight == nil) {
                        CGFloat atLeftDisplacement = positionOfViewAtLeftAtTouchBegan.x + translatedPoint.x - displacementPosition;
                        [self changeFrame:viewAtLeft
                                  originX:atLeftDisplacement];
                    }
                    else {
                        [self changeFrame:viewAtRight
                                  originX:atRightDisplacement];
                        CGFloat originX = MAX(overlapLeftRight, SLIDE_VIEWS_MINUS_X_POSITION);
                        [self changeFrame:viewAtLeft
                                  originX:originX];
                    }
                }
                else {
                    CGFloat originX = MIN(atRightDisplacement, self.view.frame.size.width);
                    [self changeFrame:viewAtRight
                              originX:originX];
                    
                    originX = MAX(overlapLeftRight, SLIDE_VIEWS_MINUS_X_POSITION);
                    [self changeFrame:viewAtLeft
                              originX:originX];
                    
                    if (viewAtRight.frame.origin.x >= self.view.frame.size.width) {
                        positionOfViewAtRightAtTouchBegan = viewAtRight.frame.origin;
                        positionOfViewAtLeftAtTouchBegan = viewAtLeft.frame.origin;
                        displacementPosition = translatedPoint.x;
                    }
                    [self arrangeVerticalBar];
                }
            }
            [self arrangeVerticalBar];
        }
    }
    
    lastTouchPoint = location.x;
    
    // STATE END
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if ([dragDirection isEqualToString:@"LEFT"]) {
            if (viewAtRight != nil) {
                if ([slideViews.subviews indexOfObject:viewAtLeft] == 0 && !(viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION || viewAtLeft.frame.origin.x == SLIDE_VIEWS_START_X_POS)) {
                    [UIView transitionWithView:self.view
                                      duration:SLIDE_TRANSITION_TIME
                                       options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionTransitionNone
                                    animations:^{
                        if (viewAtLeft.frame.origin.x < SLIDE_VIEWS_START_X_POS && viewAtRight != nil) {
                            [self changeFrame:viewAtLeft
                                      originX:SLIDE_VIEWS_MINUS_X_POSITION];
                            [self changeFrame:viewAtRight
                                      originX:SLIDE_VIEWS_MINUS_X_POSITION + viewAtLeft.frame.size.width];
                        }
                        else {
                            // Drop Card View Animation
                            if (slideViews.subviews[0].frame.origin.x - SLIDE_VIEWS_MINUS_X_POSITION >= self.view.frame.origin.x + slideViews.subviews[0].frame.size.width) {
                                [self cardDrop];
                            }
                            
                            [self changeFrame:viewAtLeft
                                      originX:SLIDE_VIEWS_START_X_POS];
                            if (viewAtRight != nil) {
                                [self changeFrame:viewAtRight
                                          originX:SLIDE_VIEWS_START_X_POS + viewAtLeft.frame.size.width];
                            }
                        }
                    }
                                    completion:^(BOOL finished) {}
                    ];
                }
                else if (viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION && CGRectGetMaxX(viewAtRight.frame) > self.view.frame.size.width) {
                    [UIView transitionWithView:self.view
                                      duration:SLIDE_TRANSITION_TIME
                                       options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionTransitionNone
                                    animations:^{
                        [self changeFrame:viewAtRight
                                  originX:self.view.frame.size.width - viewAtRight.frame.size.width];
                    }
                                    completion:^(BOOL finished) {}
                    ];
                }
                else if (viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION && CGRectGetMaxX(viewAtRight.frame) < self.view.frame.size.width) {
                    [UIView transitionWithView:self.view
                                      duration:SLIDE_TRANSITION_TIME
                                       options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionTransitionNone
                                    animations:^{
                        [self changeFrame:viewAtRight
                                  originX:self.view.frame.size.width - viewAtRight.frame.size.width];
                    }
                                    completion:^(BOOL finished) {
                        [self bounceBack:@"RIGHT-WITH-RIGHT" finished:@(finished) context:nil];
                    }
                    ];
                }
                else if (viewAtLeft.frame.origin.x > SLIDE_VIEWS_MINUS_X_POSITION) {
                    __block NSString *animationDirection;
                    [UIView transitionWithView:self.view
                                      duration:SLIDE_TRANSITION_TIME
                                       options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionTransitionNone
                                    animations:^{
                        if (CGRectGetMaxX(viewAtLeft.frame) > self.view.frame.size.width && viewAtLeft.frame.origin.x < (self.view.frame.size.width - viewAtLeft.frame.size.width / 2)) {
                            animationDirection = @"LEFT-WITH-LEFT";
                            [self changeFrame:viewAtLeft
                                      originX:self.view.frame.size.width - viewAtLeft.frame.size.width];
                            
                            // Show bounce effect
                            [self changeFrame:viewAtRight
                                      originX:self.view.frame.size.width];
                        }
                        else {
                            animationDirection = @"LEFT-WITH-RIGHT";
                            [self changeFrame:viewAtLeft
                                      originX:SLIDE_VIEWS_MINUS_X_POSITION];
                            if (positionOfViewAtLeftAtTouchBegan.x + viewAtLeft.frame.size.width <= self.view.frame.size.width) {
                                [self changeFrame:viewAtRight
                                          originX:self.view.frame.size.width - viewAtRight.frame.size.width];
                            }
                            else {
                                [self changeFrame:viewAtRight
                                          originX:SLIDE_VIEWS_MINUS_X_POSITION + viewAtLeft.frame.size.width];
                            }
                            
                            // Show bounce effect
                            [self changeFrame:viewAtRight2
                                      originX:CGRectGetMaxX(viewAtRight.frame)];
                        }
                    }
                                    completion:^(BOOL finished) {
                        [self bounceBack:animationDirection finished:@(finished) context:nil];
                    }
                    ];
                }
            }
            else {
                [UIView transitionWithView:self.view
                                  duration:SLIDE_TRANSITION_TIME
                                   options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionTransitionNone
                                animations:^{
                    [self changeFrame:viewAtLeft
                              originX:SLIDE_VIEWS_START_X_POS];
                }
                                completion:^(BOOL finished) {}
                ];
            }
        }
        else if ([dragDirection isEqualToString:@"RIGHT"]) {
            if (viewAtLeft != nil) {
                if ([slideViews.subviews indexOfObject:viewAtLeft] == 0 && !(viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION || viewAtLeft.frame.origin.x == SLIDE_VIEWS_START_X_POS)) {
                    [UIView transitionWithView:self.view
                                      duration:SLIDE_TRANSITION_TIME
                                       options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionTransitionNone
                                    animations:^{
                        if (viewAtLeft.frame.origin.x > SLIDE_VIEWS_MINUS_X_POSITION || viewAtRight == nil) {
                            // Drop Card View Animation
                            CGFloat posX = SLIDE_VIEWS_START_X_POS;
                            if (slideViews.subviews[0].frame.origin.x + PAD_MENU_TABLE_WIDTH >= self.view.frame.origin.x + slideViews.subviews[0].frame.size.width) {
                                [self cardDrop];
                                // MODDED BY JOE
                                CGFloat marginPosX = (IS_PORTRAIT ? GET_MAINSCREEN_WIDTH : GET_MAINSCREEN_HEIGHT) - PAD_MENU_TABLE_WIDTH - STACK_OVERLAP;
                                if (slideViews.subviews[0].frame.origin.x + marginPosX / 2 >= marginPosX) {
                                    posX = marginPosX;
                                }
                                // END MODDED
                            }
                            [self changeFrame:viewAtLeft
                                      originX:posX];
                            if (viewAtRight != nil) {
                                [self changeFrame:viewAtRight
                                          originX:SLIDE_VIEWS_START_X_POS + viewAtLeft.frame.size.width];
                            }
                        }
                        else {
                            [self changeFrame:viewAtLeft
                                      originX:SLIDE_VIEWS_MINUS_X_POSITION];
                            [self changeFrame:viewAtRight
                                      originX:SLIDE_VIEWS_MINUS_X_POSITION + viewAtLeft.frame.size.width];
                        }
                    }
                                    completion:^(BOOL finished) {}
                    ];
                }
                else if (viewAtRight.frame.origin.x < self.view.frame.size.width) {
                    [self moveStack];
                }
            }
        }
        lastTouchPoint = -1;
        dragDirection = @"";
    }
}

- (void)moveStack {
    if (viewAtRight.frame.origin.x < CGRectGetMaxX(viewAtLeft.frame) && viewAtRight.frame.origin.x < (self.view.frame.size.width - viewAtRight.frame.size.width / 2)) {
        [UIView transitionWithView:self.view
                          duration:SLIDE_TRANSITION_TIME
                           options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionTransitionNone
                        animations:^{
            [self changeFrame:viewAtRight
                      originX:SLIDE_VIEWS_MINUS_X_POSITION + viewAtLeft.frame.size.width];
        }
                        completion:^(BOOL finished) {
            [self bounceBack:@"RIGHT-WITH-RIGHT" finished:@(finished) context:nil];
        }
        ];
    }
    else {
        [UIView transitionWithView:self.view
                          duration:SLIDE_TRANSITION_TIME
                           options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionTransitionNone
                        animations:^{
            if ([slideViews.subviews indexOfObject:viewAtLeft] > 0) {
                if (positionOfViewAtRightAtTouchBegan.x + viewAtRight.frame.size.width <= self.view.frame.size.width) {
                    [self changeFrame:viewAtLeft
                              originX:self.view.frame.size.width - viewAtLeft.frame.size.width];
                }
                else {
                    [self changeFrame:viewAtLeft
                              originX:SLIDE_VIEWS_MINUS_X_POSITION + viewAtLeft2.frame.size.width];
                }
                [self changeFrame:viewAtRight
                          originX:self.view.frame.size.width];
            }
            else {
                [self changeFrame:viewAtLeft
                          originX:SLIDE_VIEWS_MINUS_X_POSITION];
                [self changeFrame:viewAtRight
                          originX:SLIDE_VIEWS_MINUS_X_POSITION + viewAtLeft.frame.size.width];
            }
        }
                        completion:^(BOOL finished) {
            [self bounceBack:@"RIGHT-WITH-LEFT" finished:@(finished) context:nil];
        }
        ];
    }
}

- (CABasicAnimation*)setBounceAnimation:(CABasicAnimation*)animation from:(CGFloat)fromPos to:(CGFloat)toPos {
    animation.duration = 0.2;
    animation.fromValue = @(fromPos);
    animation.toValue = @(toPos);
    animation.repeatCount = 0;
    animation.autoreverses = YES;
    animation.fillMode = kCAFillModeBackwards;
    animation.removedOnCompletion = YES;
    animation.additive = NO;
    return animation;
}

- (void)bounceBack:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context {
    BOOL isBouncing = NO;
    
    if ([dragDirection isEqualToString:@""] && [finished boolValue]) {
        [viewAtLeft.layer removeAllAnimations];
        [viewAtRight.layer removeAllAnimations];
        [viewAtRight2.layer removeAllAnimations];
        [viewAtLeft2.layer removeAllAnimations];
        if ([animationID isEqualToString:@"LEFT-WITH-LEFT"] && viewAtLeft2.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION) {
            CABasicAnimation *bounceAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
            bounceAnimation = [self setBounceAnimation:bounceAnimation
                                                  from:viewAtLeft.center.x
                                                    to:viewAtLeft.center.x - 10];
            [viewAtLeft.layer addAnimation:bounceAnimation forKey:@"bounceAnimation"];
            
            viewAtRight.hidden = NO;
            CABasicAnimation *bounceAnimationForRight = [CABasicAnimation animationWithKeyPath:@"position.x"];
            bounceAnimationForRight = [self setBounceAnimation:bounceAnimationForRight
                                                          from:viewAtRight.center.x
                                                            to:viewAtRight.center.x - 20];
            [viewAtRight.layer addAnimation:bounceAnimationForRight forKey:@"bounceAnimationRight"];
        }
        else if ([animationID isEqualToString:@"LEFT-WITH-RIGHT"] && viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION) {
            CABasicAnimation *bounceAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
            bounceAnimation = [self setBounceAnimation:bounceAnimation
                                                  from:viewAtRight.center.x
                                                    to:viewAtRight.center.x - 10];
            [viewAtRight.layer addAnimation:bounceAnimation forKey:@"bounceAnimation"];
            
            viewAtRight2.hidden = NO;
            CABasicAnimation *bounceAnimationForRight2 = [CABasicAnimation animationWithKeyPath:@"position.x"];
            bounceAnimationForRight2 = [self setBounceAnimation:bounceAnimationForRight2
                                                           from:viewAtRight2.center.x
                                                             to:viewAtRight2.center.x - 20];
            [viewAtRight2.layer addAnimation:bounceAnimationForRight2 forKey:@"bounceAnimationRight2"];
        }
        else if ([animationID isEqualToString:@"RIGHT-WITH-RIGHT"]) {
            CABasicAnimation *bounceAnimationLeft = [CABasicAnimation animationWithKeyPath:@"position.x"];
            bounceAnimationLeft = [self setBounceAnimation:bounceAnimationLeft
                                                      from:viewAtLeft.center.x
                                                        to:viewAtLeft.center.x + 10];
            [viewAtLeft.layer addAnimation:bounceAnimationLeft forKey:@"bounceAnimationLeft"];
            
            CABasicAnimation *bounceAnimationRight = [CABasicAnimation animationWithKeyPath:@"position.x"];
            bounceAnimationRight = [self setBounceAnimation:bounceAnimationRight
                                                       from:viewAtRight.center.x
                                                         to:viewAtRight.center.x + 10];
            [viewAtRight.layer addAnimation:bounceAnimationRight forKey:@"bounceAnimationRight"];
            
        }
        else if ([animationID isEqualToString:@"RIGHT-WITH-LEFT"]) {
            CABasicAnimation *bounceAnimationLeft = [CABasicAnimation animationWithKeyPath:@"position.x"];
            bounceAnimationLeft = [self setBounceAnimation:bounceAnimationLeft
                                                      from:viewAtLeft.center.x
                                                        to:viewAtLeft.center.x + 10];
            [viewAtLeft.layer addAnimation:bounceAnimationLeft forKey:@"bounceAnimationLeft"];
            
            if (viewAtLeft2 != nil) {
                viewAtLeft2.hidden = NO;
                NSInteger viewAtLeft2Position = [slideViews.subviews indexOfObject:viewAtLeft2];
                if (viewAtLeft2Position > 0) {
                    slideViews.subviews[viewAtLeft2Position - 1].hidden = NO;
                }
                CABasicAnimation *bounceAnimationLeft2 = [CABasicAnimation animationWithKeyPath:@"position.x"];
                bounceAnimationLeft2 = [self setBounceAnimation:bounceAnimationLeft2
                                                           from:viewAtLeft2.center.x
                                                             to:viewAtLeft2.center.x + 10];
                [viewAtLeft2.layer addAnimation:bounceAnimationLeft2 forKey:@"bounceAnimationviewAtLeft2"];
                [self performSelector:@selector(callArrangeVerticalBar) withObject:nil afterDelay:0.4];
                isBouncing = YES;
            }
        }
    }
    [self arrangeVerticalBar];
    if ([slideViews.subviews indexOfObject:viewAtLeft2] == 1 && isBouncing) {
        [borderViews viewWithTag:2 + VIEW_TAG].hidden = YES;
    }
}

- (void)callArrangeVerticalBar {
    [self arrangeVerticalBar];
}

- (void)loadView {
    [super loadView];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleAutoPan)
                                                 name: @"UIApplicationEnableStackPan"
                                               object: nil];
}

- (void)handleAutoPan {
    [self moveStack];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)addViewInSlider:(UIViewController*)controller invokeByController:(UIViewController*)invokeByController isStackStartView:(BOOL)isStackStartView {
    CGFloat animX = 0;
    if (isStackStartView) {
        NSInteger numViews = slideViews.subviews.count;
        if (numViews == 0) {
            animX = (IS_PORTRAIT ? GET_MAINSCREEN_WIDTH : GET_MAINSCREEN_HEIGHT) - PAD_MENU_TABLE_WIDTH;
        }
        else {
            animX = slideViews.subviews[0].frame.origin.x;
        }
        slideStartPosition = SLIDE_VIEWS_START_X_POS;
        viewXPosition = slideStartPosition;
        
        for (UIView *subview in slideViews.subviews) {
            [subview removeFromSuperview];
        }
        
        [borderViews viewWithTag:3 + VIEW_TAG].hidden = YES;
        [borderViews viewWithTag:2 + VIEW_TAG].hidden = YES;
        [borderViews viewWithTag:1 + VIEW_TAG].hidden = YES;
        [viewControllersStack removeAllObjects];
    }
    
    // Special treatment to not have multiple remote custom button views.
    // Removes topmost custom button view and pushes the new one on top of the stack.
    if ([controller.nibName isEqualToString:@"RightMenuViewController"] && viewControllersStack.count > 0) {
        NSInteger index = viewControllersStack.count - 1;
        UIViewController *indexController = viewControllersStack[index];
        if ([indexController.nibName isEqualToString:@"RightMenuViewController"]) {
            [[slideViews viewWithTag:index + VIEW_TAG] removeFromSuperview];
            [viewControllersStack removeObjectAtIndex:index];
            viewXPosition = self.view.frame.size.width - controller.view.frame.size.width;
        }
    }
    
    if (viewControllersStack.count > 1) {
        UIViewController *invokedBy = invokeByController.parentViewController ?: invokeByController;
        NSInteger indexOfViewController = [viewControllersStack indexOfObject:invokedBy];
        if (indexOfViewController == NSNotFound) {
            indexOfViewController = viewControllersStack.count;
        }
        else {
            indexOfViewController += 1;
        }
        
        NSInteger viewControllerCount = viewControllersStack.count;
        for (NSInteger i = indexOfViewController; i < viewControllerCount; i++) {
            [[slideViews viewWithTag:i + VIEW_TAG] removeFromSuperview];
            [viewControllersStack removeObjectAtIndex:indexOfViewController];
            viewXPosition = self.view.frame.size.width - controller.view.frame.size.width;
        }
    }
    else if (viewControllersStack.count == 0) {
        for (UIView *subview in slideViews.subviews) {
            [subview removeFromSuperview];
        }		[viewControllersStack removeAllObjects];
        [borderViews viewWithTag:3 + VIEW_TAG].hidden = YES;
        [borderViews viewWithTag:2 + VIEW_TAG].hidden = YES;
        [borderViews viewWithTag:1 + VIEW_TAG].hidden = YES;
    }
    
    if (slideViews.subviews.count != 0) {
        UIView *verticalLineView = [[UIView alloc] initWithFrame:CGRectMake(-40, 0, 40, self.view.frame.size.height - bottomPadding)];
        verticalLineView.backgroundColor = UIColor.clearColor;
        verticalLineView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        verticalLineView.clipsToBounds = NO;
        [controller.view addSubview:verticalLineView];
    }
    
    [viewControllersStack addObject:controller];
    if (invokeByController != nil) {
        viewXPosition = invokeByController.view.frame.origin.x + invokeByController.view.frame.size.width;
    }
    if (slideViews.subviews.count == 0) {
        slideStartPosition = SLIDE_VIEWS_START_X_POS;
        viewXPosition = slideStartPosition;
    }
    controller.view.frame = CGRectMake(viewXPosition, 0, controller.view.frame.size.width, self.view.frame.size.height - bottomPadding);
    controller.view.tag = viewControllersStack.count - 1 + VIEW_TAG;
    [controller viewWillAppear:NO];
    [controller viewDidAppear:NO];
    
    [Utilities addShadowsToView:controller.view viewFrame:controller.view.frame];
    
    [slideViews addSubview:controller.view];
    if (slideViews.subviews.count > 0) {
        if (slideViews.subviews.count == 1) {
            viewAtLeft = slideViews.subviews[slideViews.subviews.count - 1];
            controller.view.frame = CGRectMake(animX, 0, controller.view.frame.size.width, self.view.frame.size.height - bottomPadding);
            
            [UIView transitionWithView:viewAtLeft
                              duration:SLIDE_TRANSITION_TIME
                               options:UIViewAnimationOptionTransitionNone
                            animations:^{
                controller.view.frame = CGRectMake(viewXPosition, 0, controller.view.frame.size.width, self.view.frame.size.height - bottomPadding);
            }
                            completion:^(BOOL finished) {}
            ];
            viewAtLeft2 = nil;
            viewAtRight = nil;
            viewAtRight2 = nil;
        }
        else if (slideViews.subviews.count == 2) {
            viewAtRight = slideViews.subviews[slideViews.subviews.count - 1];
            viewAtLeft = slideViews.subviews[slideViews.subviews.count - 2];
            viewAtLeft2 = nil;
            viewAtRight2 = nil;
            
            [UIView transitionWithView:viewAtLeft
                              duration:SLIDE_TRANSITION_TIME
                               options:UIViewAnimationOptionTransitionNone
                            animations:^{
                [self changeFrame:viewAtLeft
                          originX:SLIDE_VIEWS_MINUS_X_POSITION];
                [self changeFrame:viewAtRight
                          originX:self.view.frame.size.width - viewAtRight.frame.size.width];
            }
                            completion:^(BOOL finished) {}
            ];
            slideStartPosition = SLIDE_VIEWS_MINUS_X_POSITION;
        }
        else {
            viewAtRight = slideViews.subviews[slideViews.subviews.count - 1];
            viewAtLeft = slideViews.subviews[slideViews.subviews.count - 2];
            viewAtLeft2 = slideViews.subviews[slideViews.subviews.count - 3];
            viewAtLeft2.hidden = NO;
            viewAtRight2 = nil;
            
            [UIView transitionWithView:viewAtLeft
                              duration:SLIDE_TRANSITION_TIME
                               options:UIViewAnimationOptionTransitionNone
                            animations:^{
                [self changeFrame:viewAtLeft2
                          originX:SLIDE_VIEWS_MINUS_X_POSITION];
                [self changeFrame:viewAtLeft
                          originX:SLIDE_VIEWS_MINUS_X_POSITION];
                [self changeFrame:viewAtRight
                          originX:self.view.frame.size.width - viewAtRight.frame.size.width];
            }
                            completion:^(BOOL finished) {}
            ];
            slideStartPosition = SLIDE_VIEWS_MINUS_X_POSITION;
            if (slideViews.subviews.count > 3) {
                slideViews.subviews[slideViews.subviews.count - 4].hidden = YES;
            }
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Rotation support

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    BOOL isViewOutOfScreen = NO;
    CGFloat posX = SLIDE_VIEWS_START_X_POS;
    if (viewControllersStack.count == 1) {
        posX = slideViews.subviews[0].frame.origin.x;
    }
    for (UIViewController *subController in viewControllersStack) {
        // If we have a view in fullscreen, keep it fullscreen
        if (fullscreenView != nil && [fullscreenView isEqual:subController.view]) {
            CGRect frame = self.view.frame;
            frame.size.width += PAD_MENU_TABLE_WIDTH;
            frame.origin.x -= PAD_MENU_TABLE_WIDTH;
            if (hideToolbar) {
                CGFloat statusbarHeight = [Utilities getTopPadding];
                frame.origin.y -= statusbarHeight;
                frame.size.height += statusbarHeight;
            }
            subController.view.frame = frame;
        }
        else if (viewAtRight != nil && [viewAtRight isEqual:subController.view]) {
            if (viewAtRight.frame.origin.x <= CGRectGetMaxX(viewAtLeft.frame)) {
                [self changeFrame:subController.view
                          originX:self.view.frame.size.width - subController.view.frame.size.width
                           height:self.view.frame.size.height - bottomPadding];
            }
            else {
                [self changeFrame:subController.view
                          originX:CGRectGetMaxX(viewAtLeft.frame)
                           height:self.view.frame.size.height - bottomPadding];
            }
            isViewOutOfScreen = YES;
        }
        else if (viewAtLeft != nil && [viewAtLeft isEqual:subController.view]) {
            if (viewAtLeft2 == nil) {
                if (viewAtRight == nil) {
                    [self changeFrame:subController.view
                              originX:posX
                               height:self.view.frame.size.height - bottomPadding];
                }
                else {
                    [self changeFrame:subController.view
                              originX:SLIDE_VIEWS_MINUS_X_POSITION
                               height:self.view.frame.size.height - bottomPadding];
                    [self changeFrame:viewAtRight
                              originX:SLIDE_VIEWS_MINUS_X_POSITION + subController.view.frame.size.width
                               height:viewAtRight.frame.size.height - bottomPadding];
                }
            }
            else if (viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION || viewAtLeft.frame.origin.x == SLIDE_VIEWS_START_X_POS) {
                [self changeFrame:subController.view
                          originX:subController.view.frame.origin.x
                           height:self.view.frame.size.height - bottomPadding];
            }
            else {
                if (CGRectGetMaxX(viewAtLeft.frame) == self.view.frame.size.width) {
                    [self changeFrame:subController.view
                              originX:self.view.frame.size.width - subController.view.frame.size.width
                               height:self.view.frame.size.height - bottomPadding];
                }
                else {
                    [self changeFrame:subController.view
                              originX:viewAtLeft2.frame.origin.x + viewAtLeft2.frame.size.width
                               height:self.view.frame.size.height - bottomPadding];
                }
            }
        }
        else if (!isViewOutOfScreen) {
            [self changeFrame:subController.view
                      originX:subController.view.frame.origin.x
                       height:self.view.frame.size.height - bottomPadding];
        }
        else {
            [self changeFrame:subController.view
                      originX:self.view.frame.size.width
                       height:self.view.frame.size.height - bottomPadding];
        }
    }
    for (UIViewController *subController in viewControllersStack) {
        [subController viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
        if (!((viewAtRight != nil && [viewAtRight isEqual:subController.view]) || (viewAtLeft != nil && [viewAtLeft isEqual:subController.view]) || (viewAtLeft2 != nil && [viewAtLeft2 isEqual:subController.view]))) {
            subController.view.hidden = YES;
        }
    }
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {}
                                 completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        for (UIViewController *subController in viewControllersStack) {
            [subController viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
        }
        viewAtLeft.hidden = NO;
        viewAtRight.hidden = NO;
        viewAtLeft2.hidden = NO;
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

@end
