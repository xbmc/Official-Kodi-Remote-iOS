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
//  MenuViewController.m
//  StackScrollView
//
//  Created by Reefaq on 2/24/11.
//  Copyright 2011 raw engineering . All rights reserved.
//
// NOTE: heavly modified by JOE

#import "MenuViewController.h"
#import "AppDelegate.h"
#import "ViewControllerIPad.h"
#import "StackScrollViewController.h"
#import "mainMenu.h"
#import "DetailViewController.h"
#import "RemoteController.h"

@implementation MenuViewController
@synthesize tableView = _tableView;

#pragma mark -
#pragma mark View lifecycle

- (id)initWithFrame:(CGRect)frame mainMenu:(NSMutableArray*)menu {
    if (self = [super init]) {
        self.view.frame = frame;
        CGFloat tableHeight = menu.count * PAD_MENU_HEIGHT;
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, tableHeight) style:UITableViewStylePlain];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = UIColor.clearColor;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.separatorColor = [Utilities getGrayColor:0 alpha:0.1];
        mainMenuItems = menu;
        UIView* footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
        _tableView.tableFooterView = footerView;
        [self.view addSubview:_tableView];
        
		UIView* verticalLineView1 = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width, 0, 1, self.view.frame.size.height)];
		verticalLineView1.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		verticalLineView1.backgroundColor = [Utilities getGrayColor:0 alpha:0.3];
		[self.view addSubview:verticalLineView1];
        [self.view bringSubviewToFront:verticalLineView1];
        
        UIView* verticalLineView2 = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width + 1, 0, 1, self.view.frame.size.height)];
		verticalLineView2.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		verticalLineView2.backgroundColor = [Utilities getGrayColor:77 alpha:0.2];
		[self.view addSubview:verticalLineView2];
        [self.view bringSubviewToFront:verticalLineView2];
	}
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    lastSelected = -1;
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnableMusicSection)
                                                 name: @"UIApplicationEnableMusicSection"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnableMovieSection)
                                                 name: @"UIApplicationEnableMovieSection"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnableTvShowSection)
                                                 name: @"UIApplicationEnableTvShowSection"
                                               object: nil];
}

- (void)handleEnableMusicSection {
    NSIndexPath* selection = [self.tableView indexPathForSelectedRow];
    if (selection.row != 1 || selection == nil) {
        [self.tableView deselectRowAtIndexPath:selection animated:YES];
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
        lastSelected = 1;
        [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollOnScreen" object: nil]; 
    }		
}

- (void)handleEnableMovieSection {
    NSIndexPath* selection = [self.tableView indexPathForSelectedRow];
    if (selection.row != 2 || selection == nil) {
        [self.tableView deselectRowAtIndexPath:selection animated:YES];
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
        lastSelected = 2;
        [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollOnScreen" object: nil];
    }
}

- (void)handleEnableTvShowSection {
    NSIndexPath* selection = [self.tableView indexPathForSelectedRow];
    if (selection.row != 3 || selection == nil) {
        [self.tableView deselectRowAtIndexPath:selection animated:YES];
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
        lastSelected = 3;
        [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollOnScreen" object: nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma mark Table view data source

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return PAD_MENU_HEIGHT;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return mainMenuItems.count;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    cell.backgroundColor = UIColor.clearColor;
}

// Customize the appearance of table view cells.
- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"mainMenuCell"];
    [[NSBundle mainBundle] loadNibNamed:@"cellViewIPad" owner:self options:NULL];
    if (cell == nil) {
        cell = resultMenuCell;
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height)];
        backgroundView.backgroundColor = [Utilities getGrayColor:0 alpha:0.4];
        cell.selectedBackgroundView = backgroundView;
    }
    mainMenu *item = mainMenuItems[indexPath.row];
    UIImageView *icon = (UIImageView*)[cell viewWithTag:1];
    UILabel *title = (UILabel*)[cell viewWithTag:3];
    NSString *iconName = item.icon;
    title.font = [UIFont fontWithName:@"Roboto-Regular" size:20];
    title.text = [item.mainLabel uppercaseString];
    icon.highlightedImage = [UIImage imageNamed:iconName];
    icon.image = [Utilities colorizeImage:icon.highlightedImage withColor:UIColor.grayColor];
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    if (!AppDelegate.instance.serverOnLine) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    mainMenu *item = mainMenuItems[indexPath.row];
    if (item.family == FamilyNowPlaying) {
        [AppDelegate.instance.windowController.stackScrollViewController offView];
    }
    else {
        if (lastSelected == indexPath.row) {
            [AppDelegate.instance.windowController.stackScrollViewController offView];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            lastSelected = -1;
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollOnScreen" object: nil]; 
        if (item.family == FamilyDetailView) {
            DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:item withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
            [AppDelegate.instance.windowController.stackScrollViewController addViewInSlider:detailViewController invokeByController:self isStackStartView:YES];
            [AppDelegate.instance.windowController.stackScrollViewController enablePanGestureRecognizer];
        }
        else if (item.family == FamilyRemote) {
            RemoteController *remoteController = [[RemoteController alloc] initWithNibName:@"RemoteController" bundle:nil]; 
            remoteController.view.frame = CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height);
            [AppDelegate.instance.windowController.stackScrollViewController addViewInSlider:remoteController invokeByController:self isStackStartView:YES];
            [AppDelegate.instance.windowController.stackScrollViewController disablePanGestureRecognizer:remoteController.panFallbackImageView];
        }
        lastSelected = (int)indexPath.row;
    }
}

- (void)setLastSelected:(int)selection {
    lastSelected = selection;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
