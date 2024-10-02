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
#define SLIDE_VIEWS_MINUS_NON_OVERLAP (GET_MAINSCREEN_HEIGHT - PAD_MENU_TABLE_WIDTH - 2 * STACKSCROLL_WIDTH)
#define SLIDE_VIEWS_MINUS_X_POSITION MAX(-PAD_MENU_TABLE_WIDTH * 0.67, SLIDE_VIEWS_MINUS_NON_OVERLAP) /* Lets two stacks slightly overlap in landscape. */
#define SLIDE_VIEWS_START_X_POS 0
#define SLIDE_TRANSITION_TIME 0.2
#define BOUNCE_X 20

@implementation StackScrollViewController

@synthesize slideViews, viewControllersStack, slideStartPosition;

- (id)init {
    if (self = [super init]) {
        
        bottomPadding = [Utilities getBottomPadding];
        
        viewControllersStack = [NSMutableArray new];
        
        slideViews = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - bottomPadding)];
        slideViews.backgroundColor = UIColor.clearColor;
        self.view.backgroundColor = UIColor.clearColor;
        self.view.frame = slideViews.frame;
        self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        viewXPosition = 0;
        lastTouchPoint = -1;
        
        viewAtLeft2 = nil;
        viewAtLeft = nil;
        viewAtRight = nil;
        viewAtRight2 = nil;
        
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
            id subview = slideViews.subviews[i + 1];
            if (viewAtRight2 == subview) {
                viewAtRight2 = nil;
            }
            else if (viewAtRight == subview) {
                viewAtRight = nil;
            }
            [subview removeFromSuperview];
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
                frame.size.height = self.view.frame.size.height - [Utilities getBottomPadding];
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
        viewAtLeft2 = nil;
        viewAtRight = nil;
        viewAtLeft = nil;
        viewAtRight2 = nil;
    }
                    completion:^(BOOL finished) {
        for (UIView *subview in slideViews.subviews) {
            [subview removeFromSuperview];
        }
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

- (void)handlePanFrom:(UIPanGestureRecognizer*)recognizer {
    if (stackScrollIsFullscreen) {
        return;
    }
    CGPoint translatedPoint = [recognizer translationInView:self.view];
    
    // Dragging starts
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        referenceXviewAtRight = viewAtRight.frame.origin.x;
        referenceXviewAtLeft = viewAtLeft.frame.origin.x;
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
    }
    
    CGPoint location = [recognizer locationInView:self.view];
    if (lastTouchPoint != -1) {
        // Only viewAtLeft and viewAtRight can be moved. The view viewAtLeft2 is located under viewAtLeft and stays in
        // leftmost position, viewAtRight2 is on top of viewAtRight but outside the visible area.
        if (location.x < lastTouchPoint) {
            dragDirection = StackDraggedLeft;
            // We are dragging to the left.
            // If viewAtLeft is at leftmost position and there is a view right of viewAtRight, shift the assignments
            // viewAtLeft2 <- viewAtLeft <- viewAtRight <- viewAtRight2 <- next controller in stack
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
                    if ([slideViews.subviews indexOfObject:viewAtLeft2] > 1) {
                        slideViews.subviews[[slideViews.subviews indexOfObject:viewAtLeft2] - 2].hidden = YES;
                    }
                    referenceXviewAtRight = viewAtRight.frame.origin.x - translatedPoint.x;
                    referenceXviewAtLeft = viewAtLeft.frame.origin.x - translatedPoint.x;
                }
            }
        }
        else if (location.x > lastTouchPoint) {
            dragDirection = StackDraggedRight;
            // We are dragging to the right.
            // If viewAtRight is at rightmost position and there is a view left of viewAtLeft, shift the assignments
            // previous controller in stack -> viewAtLeft2 -> viewAtLeft -> viewAtRight -> viewAtRight2
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
                    referenceXviewAtRight = viewAtRight.frame.origin.x - translatedPoint.x;
                    referenceXviewAtLeft = viewAtLeft.frame.origin.x - translatedPoint.x;
                }
            }
        }
            
        // If only viewAtLeft is present, obviously only this view is moved. If viewAtRight is present also, the 
        // dragging direction impacts the behaviour. Only check for viewAtRight as viewAtLeft always exists.
        if (viewAtRight) {
            CGFloat leftViewShift, rightViewShift;
            if (dragDirection == StackDraggedRight) {
                // Dragging right. viewAtRight is dragged and viewAtLeft follows
                rightViewShift = MAX(referenceXviewAtRight + translatedPoint.x, SLIDE_VIEWS_MINUS_X_POSITION);
                leftViewShift = MAX(rightViewShift - CGRectGetWidth(viewAtLeft.frame), SLIDE_VIEWS_MINUS_X_POSITION);
            }
            else {
                // Dragging left. viewAtLeft is dragged and viewAtRight follows.
                leftViewShift = MAX(referenceXviewAtLeft + translatedPoint.x, SLIDE_VIEWS_MINUS_X_POSITION);
                rightViewShift = MAX(leftViewShift + CGRectGetWidth(viewAtLeft.frame), SLIDE_VIEWS_MINUS_X_POSITION);
                
                // When viewAtLeft reached leftmost position viewAtRight is dragged further
                if (leftViewShift == SLIDE_VIEWS_MINUS_X_POSITION) {
                    rightViewShift = MAX(referenceXviewAtRight + translatedPoint.x, SLIDE_VIEWS_MINUS_X_POSITION);
                }
            }
            [self changeFrame:viewAtLeft
                      originX:leftViewShift];
            [self changeFrame:viewAtRight
                      originX:rightViewShift];
        }
        else {
            // Only viewAtLeft exists and is moved.
            CGFloat leftViewShift = MAX(referenceXviewAtLeft + translatedPoint.x, SLIDE_VIEWS_MINUS_X_POSITION);
            [self changeFrame:viewAtLeft
                      originX:leftViewShift];
        }
    }
    lastTouchPoint = location.x;
    
    // Dragging ends, the views snap into position.
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        // If both viewAtLeft and viewAtRight are visible, the default location is leftmost for
        // viewAtLeft. For viewAtRight the position is either ensuring the full viaibility of
        // itself (overlapping with the underlying viewAtLeft), or it is moved right of viwwAtLeft
        // to fully show this underlying view.
        if (viewAtRight) {
            if (dragDirection == StackDraggedRight) {
                if (viewAtLeft2) {
                    // We drag right and reveal viewAtLeft2. We will now fully show viewAtLeft after changing the assignments
                    // previous controller in stack -> viewAtLeft2 -> viewAtLeft -> viewAtRight -> viewAtRight2
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
                }
            }
            
            // Per default viewAtRight moves right of viewAtLeft, fully showing viewAtLeft.
            CGFloat rightOrigin = SLIDE_VIEWS_MINUS_X_POSITION + viewAtLeft.frame.size.width;
            if (CGRectGetMaxX(viewAtRight.frame) < CGRectGetWidth(self.view.frame)) {
                // In case viewAtRight's right side is still within the visible area, it shall
                // become fully visible, overlappjng with underlying viewAtLeft.
                rightOrigin = CGRectGetWidth(self.view.frame) - CGRectGetWidth(viewAtRight.frame);
            }
            
            // Bounce into the direction the view snaps back to.
            CGFloat bounce = viewAtRight.frame.origin.x <= rightOrigin ? BOUNCE_X : -BOUNCE_X;
            
            [UIView transitionWithView:self.view
                              duration:SLIDE_TRANSITION_TIME
                               options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionTransitionNone
                            animations:^{
                [self changeFrame:viewAtLeft
                          originX:SLIDE_VIEWS_MINUS_X_POSITION];
                [self changeFrame:viewAtRight
                          originX:rightOrigin];
                [self changeFrame:viewAtRight2
                          originX:CGRectGetMaxX(self.view.frame)];
            }
                            completion:^(BOOL finished) {
                // Bounce of viewAtLeft uses half amount to have a rubberband like effect.
                [self bounceView:viewAtLeft amount:bounce / 2];
                [self bounceView:viewAtRight amount:bounce];
            }];
        }
        // If only viewAtLeft is present, the default location is at SLIDE_VIEWS_START_X_POS.
        else {
            // Bounce into the direction the view snaps back to
            CGFloat bounce = viewAtLeft.frame.origin.x <= SLIDE_VIEWS_START_X_POS ? BOUNCE_X : -BOUNCE_X;
            
            [UIView transitionWithView:self.view
                              duration:SLIDE_TRANSITION_TIME
                               options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionTransitionNone
                            animations:^{
                [self changeFrame:viewAtLeft
                          originX:SLIDE_VIEWS_START_X_POS];
            }
                            completion:^(BOOL finished) {
                [self bounceView:viewAtLeft amount:bounce];
            }];
        }
        
        // Reset variables for next dragging event
        lastTouchPoint = -1;
        dragDirection = StackDraggedNone;
    }
}

- (void)moveStack {
    // Moves viewAtRight to fully show viewAtLeft.
    if (viewAtRight) {
        // Bounce into the direction the view snaps back to.
        CGFloat bounce = viewAtRight.frame.origin.x <= CGRectGetMaxX(viewAtLeft.frame) ? BOUNCE_X : -BOUNCE_X;
        
        CGFloat rightOrigin = SLIDE_VIEWS_MINUS_X_POSITION + CGRectGetWidth(viewAtLeft.frame);
        [UIView transitionWithView:self.view
                          duration:SLIDE_TRANSITION_TIME
                           options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionTransitionNone
                        animations:^{
            [self changeFrame:viewAtLeft
                      originX:SLIDE_VIEWS_MINUS_X_POSITION];
            [self changeFrame:viewAtRight
                      originX:rightOrigin];
            [self changeFrame:viewAtRight2
                      originX:CGRectGetMaxX(self.view.frame)];
        }
                        completion:^(BOOL finished) {
            // Bounce of viewAtLeft uses half amount to have a rubberband like effect.
            [self bounceView:viewAtLeft amount:bounce / 2];
            [self bounceView:viewAtRight amount:bounce];
        }];
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

- (void)bounceView:(UIView*)view amount:(CGFloat)amount {
    [view.layer removeAllAnimations];
    CABasicAnimation *bounceAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
    bounceAnimation = [self setBounceAnimation:bounceAnimation
                                          from:view.center.x
                                            to:view.center.x + amount];
    [view.layer addAnimation:bounceAnimation forKey:@"bounceAnimation"];
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
        }		
        [viewControllersStack removeAllObjects];
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
            frame.size.height -= [Utilities getBottomPadding];
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
