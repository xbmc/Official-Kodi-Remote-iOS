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
#import <QuartzCore/QuartzCore.h>

#define VIEW_TAG 1000
#define SLIDE_VIEWS_MINUS_X_POSITION -200 /* Lets two stacks slightly overlap in landscape. */
#define SLIDE_VIEWS_START_X_POS 0
#define STACK_OVERLAP 53

@implementation StackScrollViewController

@synthesize slideViews, borderViews, viewControllersStack, slideStartPosition;

- (id)init {
	
	if (self = [super init]) {
		
        bottomPadding = 0;
        if (@available(iOS 11.0, *)) {
            UIWindow *window = UIApplication.sharedApplication.keyWindow;
            bottomPadding = window.safeAreaInsets.bottom;
        }
        
		viewControllersStack = [NSMutableArray new];
        stackViewsFrames = [NSMutableArray new];
		borderViews = [[UIView alloc] initWithFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION - 2, -2, 2, self.view.frame.size.height + 2)];
		[borderViews setBackgroundColor:[UIColor clearColor]];
        borderViews.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		UIView* verticalLineView1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, borderViews.frame.size.height)];
		[verticalLineView1 setBackgroundColor:[UIColor whiteColor]];
		[verticalLineView1 setTag:1 + VIEW_TAG];
		[verticalLineView1 setHidden:YES];
        verticalLineView1.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		[borderViews addSubview:verticalLineView1];
		
		UIView* verticalLineView2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, borderViews.frame.size.height)];
		[verticalLineView2 setBackgroundColor:[UIColor grayColor]];
		[verticalLineView2 setTag:2 + VIEW_TAG];
		[verticalLineView2 setHidden:YES];		
        verticalLineView2.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		[borderViews addSubview:verticalLineView2];
		
		[self.view addSubview:borderViews];
		
		slideViews = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - bottomPadding)];
		[slideViews setBackgroundColor:[UIColor clearColor]];
		[self.view setBackgroundColor:[UIColor clearColor]];
		[self.view setFrame:slideViews.frame];
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
		
		UIPanGestureRecognizer* panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
        [panRecognizer setDelegate:self];
		[panRecognizer setMaximumNumberOfTouches:1];
		[panRecognizer setDelaysTouchesBegan:YES];
		[panRecognizer setDelaysTouchesEnded:YES];
		[panRecognizer setCancelsTouchesInView:YES];
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
    BOOL hideToolbar = [[[sender userInfo] valueForKey:@"hideToolbar"] boolValue];
    BOOL clipsToBounds = [[[sender userInfo] valueForKey:@"clipsToBounds"] boolValue];
    NSTimeInterval duration = [[[sender userInfo] valueForKey:@"duration"] doubleValue];
    if (!duration) {
        duration = 1.5;
    }
    if (clipsToBounds) {
        senderView.clipsToBounds = YES;
    }
//    [[senderView viewWithTag:2002] setHidden:YES];
    stackScrollIsFullscreen = YES;
    [stackViewsFrames removeAllObjects];
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         int i = 0;
                         NSInteger numViews = [[slideViews subviews] count];
                         for (UIView* subview in [slideViews subviews]) {
                             if ([subview isEqual:[sender object]]) {
                                 originalFrame = subview.frame;
                                 CGRect frame = subview.frame;
                                 frame.origin.x = 0 - PAD_MENU_TABLE_WIDTH;
                                 if (hideToolbar) {
                                     frame.origin.y = frame.origin.y - 22;
                                     frame.size.height = frame.size.height + 22;
                                 }
                                 frame.size.width = self.view.frame.size.width + PAD_MENU_TABLE_WIDTH;
                                 subview.frame = frame;
                                 break;
                             }
                             i++;
                         }
                         if (i + 1 < numViews) {
                             CGRect frame = CGRectZero;
                             for (int j = i + 1; j < numViews; j++) {
                                 frame = [[slideViews subviews][j] frame];
                                 [stackViewsFrames addObject:[NSValue valueWithCGRect:frame]];
                                 frame.origin.x = self.view.frame.size.width;
                                 if (hideToolbar) {
                                     frame.origin.y = frame.origin.y - 20;
                                     frame.size.height = frame.size.height + 20;
                                 }
                                 [[slideViews subviews][j] setFrame:frame];
                             }
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
    NSTimeInterval duration = [[[sender userInfo] valueForKey:@"duration"] doubleValue];
    if (!duration) {
        duration = 1.5;
    }
    senderView.clipsToBounds = NO;
//    [[senderView viewWithTag:2002] setHidden:NO];
    stackScrollIsFullscreen = NO;
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         int i = 0;
                         NSInteger numViews = [[slideViews subviews] count];
                         for (UIView* subview in [slideViews subviews]) {
                             if ([subview isEqual:[sender object]]) {
                                 subview.frame = originalFrame;
                                 break;
                             }
                             i++;
                         }
                         if (i + 1 < numViews) {
                             int k = 0;
                             NSInteger numStoredFrames = [stackViewsFrames count];
                             for (int j = i + 1; j < numViews && k < numStoredFrames; j++) {
                                 [[slideViews subviews][j] setFrame:[stackViewsFrames[k] CGRectValue]];
                                 k ++;
                             }
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
//    if ([self.view.gestureRecognizers count]) {
//        [self.view removeGestureRecognizer:self.view.gestureRecognizers[0]];
//    }
//    if (![fallbackView.gestureRecognizers count]) {
//        UIPanGestureRecognizer* panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
//        [panRecognizer setMaximumNumberOfTouches:1];
//        [panRecognizer setDelaysTouchesBegan:YES];
//        [panRecognizer setDelaysTouchesEnded:YES];
//        [panRecognizer setCancelsTouchesInView:YES];
//        [fallbackView addGestureRecognizer:panRecognizer];
//    }
}

- (void)enablePanGestureRecognizer {
    return;
//    if (![self.view.gestureRecognizers count]) {
//        UIPanGestureRecognizer* panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
//		[panRecognizer setMaximumNumberOfTouches:1];
//		[panRecognizer setDelaysTouchesBegan:YES];
//		[panRecognizer setDelaysTouchesEnded:YES];
//		[panRecognizer setCancelsTouchesInView:YES];
//		[self.view addGestureRecognizer:panRecognizer];
//    }
}

- (void)arrangeVerticalBar {
	
	if ([[slideViews subviews] count] > 2) {
		[[borderViews viewWithTag:2 + VIEW_TAG] setHidden:YES];
		[[borderViews viewWithTag:1 + VIEW_TAG] setHidden:YES];
		NSInteger stackCount = 0;
		if (viewAtLeft != nil) {
			stackCount = [[slideViews subviews] indexOfObject:viewAtLeft];
		}
		
		if (viewAtLeft != nil && viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION) {
			stackCount += 1;
		}
		
		if (stackCount == 2) {
			[[borderViews viewWithTag:2 + VIEW_TAG] setHidden:NO];
		}
		if (stackCount >= 3) {
			[[borderViews viewWithTag:2 + VIEW_TAG] setHidden:NO];
			[[borderViews viewWithTag:1 + VIEW_TAG] setHidden:NO];
		}
	}
}

- (void)offView {
    CGFloat posX = (IS_PORTRAIT ? GET_MAINSCREEN_WIDTH : GET_MAINSCREEN_HEIGHT) - PAD_MENU_TABLE_WIDTH;
    
    [UIView animateWithDuration:0.2
                     animations:^{ 
                         [UIView setAnimationBeginsFromCurrentState:YES];
                         [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:self.view cache:YES];
                         for (UIView* subview in [slideViews subviews]) {
                             [subview setFrame:CGRectMake(posX, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
                         }
                         [[borderViews viewWithTag:3 + VIEW_TAG] setHidden:YES];
                         [[borderViews viewWithTag:2 + VIEW_TAG] setHidden:YES];
                         [[borderViews viewWithTag:1 + VIEW_TAG] setHidden:YES];
                         viewAtLeft2 = nil;
                         viewAtRight = nil;
                         viewAtLeft = nil;
                         viewAtRight2 = nil;
                     }
                     completion:^(BOOL finished) {
                         for (UIView* subview in [slideViews subviews]) {
                             [subview removeFromSuperview];
                         }
                         [[borderViews viewWithTag:3 + VIEW_TAG] setHidden:YES];
                         [[borderViews viewWithTag:2 + VIEW_TAG] setHidden:YES];
                         [[borderViews viewWithTag:1 + VIEW_TAG] setHidden:YES];
                         [viewControllersStack removeAllObjects];
                         [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollOffScreen" object: nil]; 
                     }];
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
			NSInteger viewAtLeft2Position = [[slideViews subviews] indexOfObject:viewAtLeft2];
			if (viewAtLeft2Position > 0) {
				[((UIView*)[slideViews subviews][viewAtLeft2Position -1]) setHidden:NO];
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
					if ([[slideViews subviews] indexOfObject:viewAtRight] < ([[slideViews subviews] count]-1)) {
						viewAtLeft2 = viewAtLeft;
						viewAtLeft = viewAtRight;
						[viewAtRight2 setHidden:NO];
						viewAtRight = viewAtRight2;
						if ([[slideViews subviews] indexOfObject:viewAtRight] < ([[slideViews subviews] count]-1)) {
							viewAtRight2 = [slideViews subviews][[[slideViews subviews] indexOfObject:viewAtRight] + 1];
						}
                        else {
							viewAtRight2 = nil;
						}							
						positionOfViewAtRightAtTouchBegan = viewAtRight.frame.origin;
						positionOfViewAtLeftAtTouchBegan = viewAtLeft.frame.origin;
						displacementPosition = translatedPoint.x * -1;							
						if ([[slideViews subviews] indexOfObject:viewAtLeft2] > 1) {
							[[slideViews subviews][[[slideViews subviews] indexOfObject:viewAtLeft2] - 2] setHidden:YES];
						}
					}
				}
				
				if (viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION && viewAtRight.frame.origin.x + viewAtRight.frame.size.width > self.view.frame.size.width) {
					if ((positionOfViewAtRightAtTouchBegan.x + translatedPoint.x + displacementPosition + viewAtRight.frame.size.width) <= self.view.frame.size.width) {
						[viewAtRight setFrame:CGRectMake(self.view.frame.size.width - viewAtRight.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					}
                    else {
						[viewAtRight setFrame:CGRectMake(positionOfViewAtRightAtTouchBegan.x + translatedPoint.x + displacementPosition, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					}
				}
				else if (([[slideViews subviews] indexOfObject:viewAtRight] == [[slideViews subviews] count]-1) && viewAtRight.frame.origin.x <= (self.view.frame.size.width - viewAtRight.frame.size.width)) {
					if ((positionOfViewAtRightAtTouchBegan.x + translatedPoint.x + displacementPosition) <= SLIDE_VIEWS_MINUS_X_POSITION) {
						[viewAtRight setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					}
                    else {
						[viewAtRight setFrame:CGRectMake(positionOfViewAtRightAtTouchBegan.x + translatedPoint.x + displacementPosition, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					}
				}
				else {
					if (positionOfViewAtLeftAtTouchBegan.x + translatedPoint.x + displacementPosition <= SLIDE_VIEWS_MINUS_X_POSITION) {
						[viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
					}
                    else {
						[viewAtLeft setFrame:CGRectMake(positionOfViewAtLeftAtTouchBegan.x + translatedPoint.x + displacementPosition, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
					}						
					[viewAtRight setFrame:CGRectMake(viewAtLeft.frame.origin.x + viewAtLeft.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					
					if (viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION) {
						positionOfViewAtRightAtTouchBegan = viewAtRight.frame.origin;
						positionOfViewAtLeftAtTouchBegan = viewAtLeft.frame.origin;
						displacementPosition = translatedPoint.x * -1;
					}
				}
			}
            else {
				[viewAtLeft setFrame:CGRectMake(positionOfViewAtLeftAtTouchBegan.x + translatedPoint.x + displacementPosition, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
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
					if ([[slideViews subviews] indexOfObject:viewAtLeft] > 0) {							
						[viewAtRight2 setHidden:YES];
						viewAtRight2 = viewAtRight;
						viewAtRight = viewAtLeft;
						viewAtLeft = viewAtLeft2;						
						if ([[slideViews subviews] indexOfObject:viewAtLeft] > 0) {
							viewAtLeft2 = [slideViews subviews][[[slideViews subviews] indexOfObject:viewAtLeft] - 1];
							[viewAtLeft2 setHidden:NO];
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
				
				if ((viewAtRight.frame.origin.x < (viewAtLeft.frame.origin.x + viewAtLeft.frame.size.width)) && viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION) {
					if ((positionOfViewAtRightAtTouchBegan.x + translatedPoint.x - displacementPosition) >= (viewAtLeft.frame.origin.x + viewAtLeft.frame.size.width)) {
						[viewAtRight setFrame:CGRectMake(viewAtLeft.frame.origin.x + viewAtLeft.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					}
                    else {
						[viewAtRight setFrame:CGRectMake(positionOfViewAtRightAtTouchBegan.x + translatedPoint.x - displacementPosition, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					}
				}
                else if ([[slideViews subviews] indexOfObject:viewAtLeft] == 0) {
					if (viewAtRight == nil) {
						[viewAtLeft setFrame:CGRectMake(positionOfViewAtLeftAtTouchBegan.x + translatedPoint.x - displacementPosition, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
					}
                    else {
						[viewAtRight setFrame:CGRectMake(positionOfViewAtRightAtTouchBegan.x + translatedPoint.x - displacementPosition, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
						if (viewAtRight.frame.origin.x - viewAtLeft.frame.size.width < SLIDE_VIEWS_MINUS_X_POSITION) {
							[viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
						}
                        else {
							[viewAtLeft setFrame:CGRectMake(viewAtRight.frame.origin.x - viewAtLeft.frame.size.width, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
						}
					}
				}					
				else {
					if ((positionOfViewAtRightAtTouchBegan.x + translatedPoint.x - displacementPosition) >= self.view.frame.size.width) {
						[viewAtRight setFrame:CGRectMake(self.view.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					}
                    else {
						[viewAtRight setFrame:CGRectMake(positionOfViewAtRightAtTouchBegan.x + translatedPoint.x - displacementPosition, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					}
					if (viewAtRight.frame.origin.x - viewAtLeft.frame.size.width < SLIDE_VIEWS_MINUS_X_POSITION) {
						[viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
					}
					else {
						[viewAtLeft setFrame:CGRectMake(viewAtRight.frame.origin.x - viewAtLeft.frame.size.width, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
					}
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
				if ([[slideViews subviews] indexOfObject:viewAtLeft] == 0 && !(viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION || viewAtLeft.frame.origin.x == SLIDE_VIEWS_START_X_POS)) {
					[UIView beginAnimations:nil context:NULL];
					[UIView setAnimationDuration:0.2];
					[UIView setAnimationTransition:UIViewAnimationTransitionNone forView:self.view cache:YES];
					[UIView setAnimationBeginsFromCurrentState:YES];
					if (viewAtLeft.frame.origin.x < SLIDE_VIEWS_START_X_POS && viewAtRight != nil) {
						[viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
						[viewAtRight setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION + viewAtLeft.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					}
					else {
						//Drop Card View Animation
						if ((((UIView*)[slideViews subviews][0]).frame.origin.x-SLIDE_VIEWS_MINUS_X_POSITION) >= (self.view.frame.origin.x + ((UIView*)[slideViews subviews][0]).frame.size.width)) {
							NSInteger viewControllerCount = [viewControllersStack count];
							
							if (viewControllerCount > 1) {
								for (int i = 1; i < viewControllerCount; i++) {
									viewXPosition = self.view.frame.size.width - [slideViews viewWithTag:i + VIEW_TAG].frame.size.width;
									[[slideViews viewWithTag:i + VIEW_TAG] removeFromSuperview];
									[viewControllersStack removeLastObject];
								}
								
								[[borderViews viewWithTag:3 + VIEW_TAG] setHidden:YES];
								[[borderViews viewWithTag:2 + VIEW_TAG] setHidden:YES];
								[[borderViews viewWithTag:1 + VIEW_TAG] setHidden:YES];
								
							}
							// Removes the selection of row for the first slide view
							for (UIView* tableView in [[slideViews subviews][0] subviews]) {
                                if ([tableView isKindOfClass:[UIView class]]) {
                                    for (UIView* tableView2 in [tableView subviews]) {
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
						
						[viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_START_X_POS, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
						if (viewAtRight != nil) {
							[viewAtRight setFrame:CGRectMake(SLIDE_VIEWS_START_X_POS + viewAtLeft.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
						}
						
					}
					[UIView commitAnimations];
				}
				else if (viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION && viewAtRight.frame.origin.x + viewAtRight.frame.size.width > self.view.frame.size.width) {
					[UIView beginAnimations:nil context:NULL];
					[UIView setAnimationDuration:0.2];
					[UIView setAnimationTransition:UIViewAnimationTransitionNone forView:self.view cache:YES];
					[UIView setAnimationBeginsFromCurrentState:YES];
					[viewAtRight setFrame:CGRectMake(self.view.frame.size.width - viewAtRight.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					[UIView commitAnimations];						
				}	
				else if (viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION && viewAtRight.frame.origin.x + viewAtRight.frame.size.width < self.view.frame.size.width) {
					[UIView beginAnimations:@"RIGHT-WITH-RIGHT" context:NULL];
					[UIView setAnimationDuration:0.2];
					[UIView setAnimationTransition:UIViewAnimationTransitionNone forView:self.view cache:YES];
					[UIView setAnimationBeginsFromCurrentState:YES];
					[viewAtRight setFrame:CGRectMake(self.view.frame.size.width - viewAtRight.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					[UIView setAnimationDelegate:self];
					[UIView setAnimationDidStopSelector:@selector(bounceBack:finished:context:)];
					[UIView commitAnimations];
				}
				else if (viewAtLeft.frame.origin.x > SLIDE_VIEWS_MINUS_X_POSITION) {
					[UIView setAnimationDuration:0.2];
					[UIView setAnimationTransition:UIViewAnimationTransitionNone forView:self.view cache:YES];
					[UIView setAnimationBeginsFromCurrentState:YES];
					if ((viewAtLeft.frame.origin.x + viewAtLeft.frame.size.width > self.view.frame.size.width) && viewAtLeft.frame.origin.x < (self.view.frame.size.width - (viewAtLeft.frame.size.width)/2)) {
						[UIView beginAnimations:@"LEFT-WITH-LEFT" context:nil];
						[viewAtLeft setFrame:CGRectMake(self.view.frame.size.width - viewAtLeft.frame.size.width, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
						
						//Show bounce effect
						[viewAtRight setFrame:CGRectMake(self.view.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					}
					else {
						[UIView beginAnimations:@"LEFT-WITH-RIGHT" context:nil];	
						[viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
						if (positionOfViewAtLeftAtTouchBegan.x + viewAtLeft.frame.size.width <= self.view.frame.size.width) {
							[viewAtRight setFrame:CGRectMake((self.view.frame.size.width - viewAtRight.frame.size.width), viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
						}
						else {
							[viewAtRight setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION + viewAtLeft.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
						}
						
						//Show bounce effect
						[viewAtRight2 setFrame:CGRectMake(viewAtRight.frame.origin.x + viewAtRight.frame.size.width, viewAtRight2.frame.origin.y, viewAtRight2.frame.size.width, viewAtRight2.frame.size.height)];
					}
					[UIView setAnimationDelegate:self];
					[UIView setAnimationDidStopSelector:@selector(bounceBack:finished:context:)];
					[UIView commitAnimations];
				}
				
			}
			else {
				[UIView beginAnimations:nil context:NULL];
				[UIView setAnimationDuration:0.2];
				[UIView setAnimationBeginsFromCurrentState:YES];
				[UIView setAnimationTransition:UIViewAnimationTransitionNone forView:self.view cache:YES];
				[viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_START_X_POS, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
				[UIView commitAnimations];
			}
		}
        else if ([dragDirection isEqualToString:@"RIGHT"]) {
			if (viewAtLeft != nil) {
				if ([[slideViews subviews] indexOfObject:viewAtLeft] == 0 && !(viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION || viewAtLeft.frame.origin.x == SLIDE_VIEWS_START_X_POS)) {
					[UIView beginAnimations:nil context:NULL];
					[UIView setAnimationDuration:0.2];			
					[UIView setAnimationBeginsFromCurrentState:YES];
					[UIView setAnimationTransition:UIViewAnimationTransitionNone forView:self.view cache:YES];
					if (viewAtLeft.frame.origin.x > SLIDE_VIEWS_MINUS_X_POSITION || viewAtRight == nil) {
						//Drop Card View Animation
                        CGFloat posX = SLIDE_VIEWS_START_X_POS;
						if ((((UIView*)[slideViews subviews][0]).frame.origin.x + PAD_MENU_TABLE_WIDTH) >= (self.view.frame.origin.x + ((UIView*)[slideViews subviews][0]).frame.size.width)) {
//                            NSLog(@"ELIMINO 2");
							NSInteger viewControllerCount = [viewControllersStack count];
							if (viewControllerCount > 1) {
								for (int i = 1; i < viewControllerCount; i++) {
									viewXPosition = self.view.frame.size.width - [slideViews viewWithTag:i + VIEW_TAG].frame.size.width;
									[[slideViews viewWithTag:i + VIEW_TAG] removeFromSuperview];
									[viewControllersStack removeLastObject];
								}
								[[borderViews viewWithTag:3 + VIEW_TAG] setHidden:YES];
								[[borderViews viewWithTag:2 + VIEW_TAG] setHidden:YES];
								[[borderViews viewWithTag:1 + VIEW_TAG] setHidden:YES];
							}
							// Removes the selection of row for the first slide view
							for (UIView* tableView in [[slideViews subviews][0] subviews]) {
                                if ([tableView isKindOfClass:[UIView class]]) {
                                    for (UIView* tableView2 in [tableView subviews]) {
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
                            // MODDED BY JOE
                            CGFloat marginPosX = (IS_PORTRAIT ? GET_MAINSCREEN_WIDTH : GET_MAINSCREEN_HEIGHT) - PAD_MENU_TABLE_WIDTH - STACK_OVERLAP;
                            if ((((UIView*)[slideViews subviews][0]).frame.origin.x+marginPosX/2) >= marginPosX) {
                                posX = marginPosX;
                            }
                            //END MODDED
                        }
						[viewAtLeft setFrame:CGRectMake(posX, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
						if (viewAtRight != nil) {
							[viewAtRight setFrame:CGRectMake(SLIDE_VIEWS_START_X_POS + viewAtLeft.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
						}
					}
					else {
						[viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
						[viewAtRight setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION + viewAtLeft.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
					}
					[UIView commitAnimations];
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
    if ((viewAtRight.frame.origin.x < (viewAtLeft.frame.origin.x + viewAtLeft.frame.size.width)) && viewAtRight.frame.origin.x < (self.view.frame.size.width - (viewAtRight.frame.size.width/2))) {
        [UIView beginAnimations:@"RIGHT-WITH-RIGHT" context:NULL];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:self.view cache:YES];
        [viewAtRight setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION + viewAtLeft.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(bounceBack:finished:context:)];
        [UIView commitAnimations];
    }
    else {
        [UIView beginAnimations:@"RIGHT-WITH-LEFT" context:NULL];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:self.view cache:YES];
        if ([[slideViews subviews] indexOfObject:viewAtLeft] > 0) {
            if (positionOfViewAtRightAtTouchBegan.x + viewAtRight.frame.size.width <= self.view.frame.size.width) {
                [viewAtLeft setFrame:CGRectMake(self.view.frame.size.width - viewAtLeft.frame.size.width, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
            }
            else {
                [viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION + viewAtLeft2.frame.size.width, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
            }
            [viewAtRight setFrame:CGRectMake(self.view.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
        }
        else {
            [viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
            [viewAtRight setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION + viewAtLeft.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
        }
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(bounceBack:finished:context:)];
        [UIView commitAnimations];
    }
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
                bounceAnimation.duration = 0.2;
                bounceAnimation.fromValue = @(viewAtLeft.center.x);
                bounceAnimation.toValue = @(viewAtLeft.center.x -10);
                bounceAnimation.repeatCount = 0;
                bounceAnimation.autoreverses = YES;
                bounceAnimation.fillMode = kCAFillModeBackwards;
                bounceAnimation.removedOnCompletion = YES;
                bounceAnimation.additive = NO;
                [viewAtLeft.layer addAnimation:bounceAnimation forKey:@"bounceAnimation"];
                
                [viewAtRight setHidden:NO];
                CABasicAnimation *bounceAnimationForRight = [CABasicAnimation animationWithKeyPath:@"position.x"];
                bounceAnimationForRight.duration = 0.2;
                bounceAnimationForRight.fromValue = @(viewAtRight.center.x);
                bounceAnimationForRight.toValue = @(viewAtRight.center.x - 20);
                bounceAnimationForRight.repeatCount = 0;
                bounceAnimationForRight.autoreverses = YES;
                bounceAnimationForRight.fillMode = kCAFillModeBackwards;
                bounceAnimationForRight.removedOnCompletion = YES;
                bounceAnimationForRight.additive = NO;
                [viewAtRight.layer addAnimation:bounceAnimationForRight forKey:@"bounceAnimationRight"];
            }
            else if ([animationID isEqualToString:@"LEFT-WITH-RIGHT"] && viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION) {
                CABasicAnimation *bounceAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
                bounceAnimation.duration = 0.2;
                bounceAnimation.fromValue = @(viewAtRight.center.x);
                bounceAnimation.toValue = @(viewAtRight.center.x - 10);
                bounceAnimation.repeatCount = 0;
                bounceAnimation.autoreverses = YES;
                bounceAnimation.fillMode = kCAFillModeBackwards;
                bounceAnimation.removedOnCompletion = YES;
                bounceAnimation.additive = NO;
                [viewAtRight.layer addAnimation:bounceAnimation forKey:@"bounceAnimation"];
                
                [viewAtRight2 setHidden:NO];
                CABasicAnimation *bounceAnimationForRight2 = [CABasicAnimation animationWithKeyPath:@"position.x"];
                bounceAnimationForRight2.duration = 0.2;
                bounceAnimationForRight2.fromValue = @(viewAtRight2.center.x);
                bounceAnimationForRight2.toValue = @(viewAtRight2.center.x - 20);
                bounceAnimationForRight2.repeatCount = 0;
                bounceAnimationForRight2.autoreverses = YES;
                bounceAnimationForRight2.fillMode = kCAFillModeBackwards;
                bounceAnimationForRight2.removedOnCompletion = YES;
                bounceAnimationForRight2.additive = NO;
                [viewAtRight2.layer addAnimation:bounceAnimationForRight2 forKey:@"bounceAnimationRight2"];
            }
            else if ([animationID isEqualToString:@"RIGHT-WITH-RIGHT"]) {
                CABasicAnimation *bounceAnimationLeft = [CABasicAnimation animationWithKeyPath:@"position.x"];
                bounceAnimationLeft.duration = 0.2;
                bounceAnimationLeft.fromValue = @(viewAtLeft.center.x);
                bounceAnimationLeft.toValue = @(viewAtLeft.center.x + 10);
                bounceAnimationLeft.repeatCount = 0;
                bounceAnimationLeft.autoreverses = YES;
                bounceAnimationLeft.fillMode = kCAFillModeBackwards;
                bounceAnimationLeft.removedOnCompletion = YES;
                bounceAnimationLeft.additive = NO;
                [viewAtLeft.layer addAnimation:bounceAnimationLeft forKey:@"bounceAnimationLeft"];
                
                CABasicAnimation *bounceAnimationRight = [CABasicAnimation animationWithKeyPath:@"position.x"];
                bounceAnimationRight.duration = 0.2;
                bounceAnimationRight.fromValue = @(viewAtRight.center.x);
                bounceAnimationRight.toValue = @(viewAtRight.center.x + 10);
                bounceAnimationRight.repeatCount = 0;
                bounceAnimationRight.autoreverses = YES;
                bounceAnimationRight.fillMode = kCAFillModeBackwards;
                bounceAnimationRight.removedOnCompletion = YES;
                bounceAnimationRight.additive = NO;
                [viewAtRight.layer addAnimation:bounceAnimationRight forKey:@"bounceAnimationRight"];
                
            }
            else if ([animationID isEqualToString:@"RIGHT-WITH-LEFT"]) {
                CABasicAnimation *bounceAnimationLeft = [CABasicAnimation animationWithKeyPath:@"position.x"];
                bounceAnimationLeft.duration = 0.2;
                bounceAnimationLeft.fromValue = @(viewAtLeft.center.x);
                bounceAnimationLeft.toValue = @(viewAtLeft.center.x + 10);
                bounceAnimationLeft.repeatCount = 0;
                bounceAnimationLeft.autoreverses = YES;
                bounceAnimationLeft.fillMode = kCAFillModeBackwards;
                bounceAnimationLeft.removedOnCompletion = YES;
                bounceAnimationLeft.additive = NO;
                [viewAtLeft.layer addAnimation:bounceAnimationLeft forKey:@"bounceAnimationLeft"];
                
                if (viewAtLeft2 != nil) {
                    [viewAtLeft2 setHidden:NO];
                    NSInteger viewAtLeft2Position = [[slideViews subviews] indexOfObject:viewAtLeft2];
                    if (viewAtLeft2Position > 0) {
                        [((UIView*)[slideViews subviews][viewAtLeft2Position -1]) setHidden:NO];
                    }
                    CABasicAnimation* bounceAnimationLeft2 = [CABasicAnimation animationWithKeyPath:@"position.x"];
                    bounceAnimationLeft2.duration = 0.2;
                    bounceAnimationLeft2.fromValue = @(viewAtLeft2.center.x);
                    bounceAnimationLeft2.toValue = @(viewAtLeft2.center.x + 10);
                    bounceAnimationLeft2.repeatCount = 0;
                    bounceAnimationLeft2.autoreverses = YES;
                    bounceAnimationLeft2.fillMode = kCAFillModeBackwards;
                    bounceAnimationLeft2.removedOnCompletion = YES;
                    bounceAnimationLeft2.additive = NO;
                    [viewAtLeft2.layer addAnimation:bounceAnimationLeft2 forKey:@"bounceAnimationviewAtLeft2"];
                    [self performSelector:@selector(callArrangeVerticalBar) withObject:nil afterDelay:0.4];
                    isBouncing = YES;
                }
                
            }
		
	}
	[self arrangeVerticalBar];	
	if ([[slideViews subviews] indexOfObject:viewAtLeft2] == 1 && isBouncing) {
		[[borderViews viewWithTag:2 + VIEW_TAG] setHidden:YES];
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
        NSInteger numViews = [[slideViews subviews]count];
        if (numViews == 0) {
            animX = (IS_PORTRAIT ? GET_MAINSCREEN_WIDTH : GET_MAINSCREEN_HEIGHT) - PAD_MENU_TABLE_WIDTH;
        }
        else {
            animX = [[slideViews subviews][0] frame].origin.x;
        }
		slideStartPosition = SLIDE_VIEWS_START_X_POS;
		viewXPosition = slideStartPosition;
		
		for (UIView* subview in [slideViews subviews]) {
			[subview removeFromSuperview];
		}
		
		[[borderViews viewWithTag:3 + VIEW_TAG] setHidden:YES];
		[[borderViews viewWithTag:2 + VIEW_TAG] setHidden:YES];
		[[borderViews viewWithTag:1 + VIEW_TAG] setHidden:YES];
		[viewControllersStack removeAllObjects];
	}
	
	
	if ([viewControllersStack count] > 1) {
//        NSLog(@"DUE");
		NSInteger indexOfViewController = [viewControllersStack
										   indexOfObject:invokeByController]+1;
		
		if ([invokeByController parentViewController]) {
			indexOfViewController = [viewControllersStack
									 indexOfObject:[invokeByController parentViewController]]+1;
		}
		
		NSInteger viewControllerCount = [viewControllersStack count];
		for (NSInteger i = indexOfViewController; i < viewControllerCount; i++) {
            [[slideViews viewWithTag:i + VIEW_TAG] removeFromSuperview];
//FIXME: 
            if (!TARGET_IPHONE_SIMULATOR) {
                [viewControllersStack removeObjectAtIndex:indexOfViewController];
            }
// END FIXME
			viewXPosition = self.view.frame.size.width - [controller view].frame.size.width;
		}
	}
    else if ([viewControllersStack count] == 0) {
//        NSLog(@"TRE"); //FIRST
		for (UIView* subview in [slideViews subviews]) {
			[subview removeFromSuperview];
		}		[viewControllersStack removeAllObjects];
		[[borderViews viewWithTag:3 + VIEW_TAG] setHidden:YES];
		[[borderViews viewWithTag:2 + VIEW_TAG] setHidden:YES];
		[[borderViews viewWithTag:1 + VIEW_TAG] setHidden:YES];
	}
	
	if ([slideViews.subviews count] != 0) {
//        NSLog(@"QUATTRO");
        UIView* verticalLineView = [[UIView alloc] initWithFrame:CGRectMake(-40, 0, 40, self.view.frame.size.height - bottomPadding)];
		[verticalLineView setBackgroundColor:[UIColor clearColor]];
		[verticalLineView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
		[verticalLineView setClipsToBounds:NO];
		[controller.view addSubview:verticalLineView];
	}
	
	[viewControllersStack addObject:controller];
	if (invokeByController != nil) {
//        NSLog(@"CINQUE"); //FIRST
		viewXPosition = invokeByController.view.frame.origin.x + invokeByController.view.frame.size.width;			
	}
	if ([[slideViews subviews] count] == 0) {
//        NSLog(@"SEI"); //FIRST
		slideStartPosition = SLIDE_VIEWS_START_X_POS;
		viewXPosition = slideStartPosition;
	}
	[[controller view] setFrame:CGRectMake(viewXPosition, 0, [controller view].frame.size.width, self.view.frame.size.height - bottomPadding)];
	[controller.view setTag:([viewControllersStack count]-1) + VIEW_TAG];
	[controller viewWillAppear:NO];
	[controller viewDidAppear:NO];
    
    CGRect shadowRect = CGRectMake(-16, 0, 16, self.view.frame.size.height - bottomPadding);
    UIImageView *shadow = [[UIImageView alloc] initWithFrame:shadowRect];
    [shadow setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    [shadow setImage:[UIImage imageNamed:@"tableLeft"]];
    shadow.opaque = YES;
    shadow.tag = 2001;
    [controller.view addSubview:shadow];
    
    shadowRect = CGRectMake(STACKSCROLL_WIDTH, 0, 16, self.view.frame.size.height - bottomPadding);
    UIImageView *shadowRight = [[UIImageView alloc] initWithFrame:shadowRect];
    [shadowRight setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin];
    [shadowRight setImage:[UIImage imageNamed:@"tableRight"]];
    shadowRight.opaque = YES;
    shadowRight.tag = 2002;
    [controller.view addSubview:shadowRight];
    
    shadowRect = CGRectMake(-15, -15, STACKSCROLL_WIDTH + 30, 15);
    UIImageView *shadowUp = [[UIImageView alloc] initWithFrame:shadowRect];
    [shadowUp setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [shadowUp setImage:[UIImage imageNamed:@"stackScrollUpShadow"]];
    [controller.view insertSubview:shadowUp atIndex:1];
    
	[slideViews addSubview:[controller view]];
    if ([[slideViews subviews] count] > 0) {
		if ([[slideViews subviews] count] == 1) {
//            NSLog(@"SETTE"); //FIRST
			viewAtLeft = [slideViews subviews][[[slideViews subviews] count]-1];
            [[controller view] setFrame:CGRectMake(animX, 0, [controller view].frame.size.width, self.view.frame.size.height - bottomPadding)];

            [UIView beginAnimations:nil context:NULL];
			[UIView setAnimationTransition:UIViewAnimationTransitionNone forView:viewAtLeft cache:YES];	
			[UIView setAnimationBeginsFromCurrentState:NO];	
            [[controller view] setFrame:CGRectMake(viewXPosition, 0, [controller view].frame.size.width, self.view.frame.size.height - bottomPadding)];

            [UIView commitAnimations];
			viewAtLeft2 = nil;
			viewAtRight = nil;
			viewAtRight2 = nil;
		}
        else if ([[slideViews subviews] count] == 2) {
//            NSLog(@"OTTO");
			viewAtRight = [slideViews subviews][[[slideViews subviews] count]-1];
			viewAtLeft = [slideViews subviews][[[slideViews subviews] count]-2];
			viewAtLeft2 = nil;
			viewAtRight2 = nil;
			
			[UIView beginAnimations:nil context:NULL];
			[UIView setAnimationTransition:UIViewAnimationTransitionNone forView:viewAtLeft cache:YES];	
			[UIView setAnimationBeginsFromCurrentState:NO];	
			[viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
			[viewAtRight setFrame:CGRectMake(self.view.frame.size.width - viewAtRight.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
			[UIView commitAnimations];
			slideStartPosition = SLIDE_VIEWS_MINUS_X_POSITION;
		}
        else {
//            NSLog(@"NOVE");
            viewAtRight = [slideViews subviews][[[slideViews subviews] count]-1];
            viewAtLeft = [slideViews subviews][[[slideViews subviews] count]-2];
            viewAtLeft2 = [slideViews subviews][[[slideViews subviews] count]-3];
            [viewAtLeft2 setHidden:NO];
            viewAtRight2 = nil;
            
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:viewAtLeft cache:YES];	
            [UIView setAnimationBeginsFromCurrentState:NO];	
            
            if (viewAtLeft2.frame.origin.x != SLIDE_VIEWS_MINUS_X_POSITION) {
                [viewAtLeft2 setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, viewAtLeft2.frame.origin.y, viewAtLeft2.frame.size.width, viewAtLeft2.frame.size.height)];
            }
            [viewAtLeft setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, viewAtLeft.frame.origin.y, viewAtLeft.frame.size.width, viewAtLeft.frame.size.height)];
            [viewAtRight setFrame:CGRectMake(self.view.frame.size.width - viewAtRight.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height)];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(bounceBack:finished:context:)];
            [UIView commitAnimations];				
            slideStartPosition = SLIDE_VIEWS_MINUS_X_POSITION;	
            if ([[slideViews subviews] count] > 3) {
                [[slideViews subviews][[[slideViews subviews] count]-4] setHidden:YES];
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
    if ([viewControllersStack count] == 1) {
        posX = [[slideViews subviews][0] frame].origin.x;
    }
    for (UIViewController* subController in viewControllersStack) {
        if (viewAtRight != nil && [viewAtRight isEqual:subController.view]) {
            if (viewAtRight.frame.origin.x <= (viewAtLeft.frame.origin.x + viewAtLeft.frame.size.width)) {
                [subController.view setFrame:CGRectMake(self.view.frame.size.width - subController.view.frame.size.width, subController.view.frame.origin.y, subController.view.frame.size.width, self.view.frame.size.height - bottomPadding)];
            }
            else {
                [subController.view setFrame:CGRectMake(viewAtLeft.frame.origin.x + viewAtLeft.frame.size.width, subController.view.frame.origin.y, subController.view.frame.size.width, self.view.frame.size.height - bottomPadding)];
            }
            isViewOutOfScreen = YES;
        }
        else if (viewAtLeft != nil && [viewAtLeft isEqual:subController.view]) {
            if (viewAtLeft2 == nil) {
                if (viewAtRight == nil) {
                    [subController.view setFrame:CGRectMake(posX, subController.view.frame.origin.y, subController.view.frame.size.width, self.view.frame.size.height - bottomPadding)];
                }
                else {
                    [subController.view setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION, subController.view.frame.origin.y, subController.view.frame.size.width, self.view.frame.size.height - bottomPadding)];
                    [viewAtRight setFrame:CGRectMake(SLIDE_VIEWS_MINUS_X_POSITION + subController.view.frame.size.width, viewAtRight.frame.origin.y, viewAtRight.frame.size.width, viewAtRight.frame.size.height - bottomPadding)];
                }
            }
            else if (viewAtLeft.frame.origin.x == SLIDE_VIEWS_MINUS_X_POSITION || viewAtLeft.frame.origin.x == SLIDE_VIEWS_START_X_POS) {
                [subController.view setFrame:CGRectMake(subController.view.frame.origin.x, subController.view.frame.origin.y, subController.view.frame.size.width, self.view.frame.size.height - bottomPadding)];
            }
            else {
                if (viewAtLeft.frame.origin.x + viewAtLeft.frame.size.width == self.view.frame.size.width) {
                    [subController.view setFrame:CGRectMake(self.view.frame.size.width - subController.view.frame.size.width, subController.view.frame.origin.y, subController.view.frame.size.width, self.view.frame.size.height - bottomPadding)];
                }
                else {
                    [subController.view setFrame:CGRectMake(viewAtLeft2.frame.origin.x + viewAtLeft2.frame.size.width, subController.view.frame.origin.y, subController.view.frame.size.width, self.view.frame.size.height - bottomPadding)];
                }
            }
        }
        else if (!isViewOutOfScreen) {
            [subController.view setFrame:CGRectMake(subController.view.frame.origin.x, subController.view.frame.origin.y, subController.view.frame.size.width, self.view.frame.size.height - bottomPadding)];
        }
        else {
            [subController.view setFrame:CGRectMake(self.view.frame.size.width, subController.view.frame.origin.y, subController.view.frame.size.width, self.view.frame.size.height - bottomPadding)];
        }
        
    }
    for (UIViewController* subController in viewControllersStack) {
        [subController viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
        if (!((viewAtRight != nil && [viewAtRight isEqual:subController.view]) || (viewAtLeft != nil && [viewAtLeft isEqual:subController.view]) || (viewAtLeft2 != nil && [viewAtLeft2 isEqual:subController.view]))) {
            [[subController view] setHidden:YES];
        }
        
    }
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {}
                                 completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        for (UIViewController* subController in viewControllersStack) {
            [subController viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
        }
        [viewAtLeft setHidden:NO];
        [viewAtRight setHidden:NO];
        [viewAtLeft2 setHidden:NO];
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
//	[slideViews release];
//	[viewControllersStack release];
//    [super dealloc];
}


@end
