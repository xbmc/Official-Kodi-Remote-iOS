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

- (id)initWithFrame:(CGRect)frame mainMenu:(NSMutableArray *)menu{
    if (self = [super init]) {
		[self.view setFrame:frame]; 
        int tableHeight = ([menu count] -1) * PAD_MENU_HEIGHT + PAD_MENU_INFO_HEIGHT;
		_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, tableHeight) style:UITableViewStylePlain];
        [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
		[_tableView setDelegate:self];
		[_tableView setDataSource:self];
        [_tableView setBackgroundColor:[UIColor clearColor]];
        [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        [_tableView setSeparatorColor:[UIColor colorWithWhite:0.0f alpha:0.1]];
        mainMenuItems=menu;
        UIView* footerView =  [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
		_tableView.tableFooterView = footerView;        
		[self.view addSubview:_tableView];
        
//        CGRect shadowRect;
//        UIImageView *shadow;
        
//        shadowRect = CGRectMake(0.0f, 0.0f, 300.0f, 8.0f);
//        shadow = [[UIImageView alloc] initWithFrame:shadowRect];
//        [shadow setImage:[UIImage imageNamed:@"tableUp.png"]];
//        shadow.opaque = YES;
//        shadow.alpha = 0.5;
//        [self.view addSubview:shadow];
        
//        shadowRect = CGRectMake(0.0f, tableHeight - 8, self.view.frame.size.width, 8.0f);
//        shadow = [[UIImageView alloc] initWithFrame:shadowRect];
//        [shadow setImage:[UIImage imageNamed:@"tableDown.png"]];
//        shadow.opaque = YES;
//        shadow.alpha = 0.5;
//        [self.view addSubview:shadow];
		
        
//        UIView* verticalLineView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width, -5, 1, self.view.frame.size.height+5)];
//		[verticalLineView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
//		[verticalLineView setBackgroundColor:[UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:1]];
//		[self.view addSubview:verticalLineView];

//        UIView* verticalLineView1 = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width + 1, -5, 5, self.view.frame.size.height-39)];
//		[verticalLineView1 setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
//		[verticalLineView1 setBackgroundColor:[UIColor colorWithPatternImage: [UIImage imageNamed:@"denim_seam_vertical.png"]]];
//		[self.view addSubview:verticalLineView1];
//        [self.view bringSubviewToFront:verticalLineView1];
        
		UIView* verticalLineView1 = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width, 0, 1, self.view.frame.size.height-39)];
		[verticalLineView1 setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
		[verticalLineView1 setBackgroundColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:.3]];
		[self.view addSubview:verticalLineView1];
        [self.view bringSubviewToFront:verticalLineView1];

        
        UIView* verticalLineView2 = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width+1, 0, 1, self.view.frame.size.height-39)];
		[verticalLineView2 setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
		[verticalLineView2 setBackgroundColor:[UIColor colorWithRed:0.3f green:0.3f blue:0.3f alpha:0.2f]];
		[self.view addSubview:verticalLineView2];
        
        [self.view bringSubviewToFront:verticalLineView2];

		
	}
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    lastSelected=-1;
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

-(void)handleEnableMusicSection{
    NSIndexPath* selection = [self.tableView indexPathForSelectedRow];
    if (selection.row != 1 || selection == nil){
        [self.tableView deselectRowAtIndexPath:selection animated:YES];
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
        lastSelected=1;
        [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollOnScreen" object: nil]; 
    }		
}

-(void)handleEnableMovieSection{
    NSIndexPath* selection = [self.tableView indexPathForSelectedRow];
    if (selection.row != 2 || selection == nil){
        [self.tableView deselectRowAtIndexPath:selection animated:YES];
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
        lastSelected=2;
        [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollOnScreen" object: nil];
    }
}

-(void)handleEnableTvShowSection{
    NSIndexPath* selection = [self.tableView indexPathForSelectedRow];
    if (selection.row != 3 || selection == nil){
        [self.tableView deselectRowAtIndexPath:selection animated:YES];
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
        lastSelected=3;
        [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollOnScreen" object: nil];
    }
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Override to allow orientations other than the default portrait orientation.
    return YES;
}


#pragma mark -
#pragma mark Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0){
        return PAD_MENU_INFO_HEIGHT;
    }
    return PAD_MENU_HEIGHT;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
//    return 10;
    return [mainMenuItems count];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0){
        cell.backgroundColor = [UIColor colorWithRed:.508f green:.508f blue:.508f alpha:0.1f];
    }
    else{
//        cell.backgroundColor = [UIColor colorWithRed:.141f green:.141f blue:.141f alpha:1];
        cell.backgroundColor = [UIColor clearColor];
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell=nil;
    cell = [tableView dequeueReusableCellWithIdentifier:@"mainMenuCell"];
    [[NSBundle mainBundle] loadNibNamed:@"cellViewIPad" owner:self options:NULL];
    if (cell==nil){
        cell = resultMenuCell;
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height)];
        [backgroundView setBackgroundColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.4f]];
        cell.selectedBackgroundView = backgroundView;
        if (indexPath.row == 0){
            [backgroundView setBackgroundColor:[UIColor colorWithRed:.508f green:.508f blue:.508f alpha:0.1f]];
            cell.selectedBackgroundView = backgroundView;
            int cellHeight = PAD_MENU_INFO_HEIGHT;
            int cellHeightPad = cellHeight - 4;
            UIImageView *xbmc_logo = [[UIImageView alloc] initWithFrame:CGRectMake(232, (int)((cellHeight/2) - (cellHeightPad/2)) - 1, 73, cellHeightPad)];
            xbmc_logo. alpha = .25f;
            [xbmc_logo setImage:[UIImage imageNamed:@"xbmc_logo"]];
            [xbmc_logo setHighlightedImage:[UIImage imageNamed:@"xbmc_logo"]];
            [xbmc_logo setContentMode:UIViewContentModeScaleAspectFit];
            [cell insertSubview:xbmc_logo atIndex:0];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }
    }
    mainMenu *item = [mainMenuItems objectAtIndex:indexPath.row];
    UIImageView *icon = (UIImageView*) [cell viewWithTag:1];
    UILabel *upperTitle = (UILabel*) [cell viewWithTag:2];
    UILabel *title = (UILabel*) [cell viewWithTag:3];
    UIImageView *line = (UIImageView*) [cell viewWithTag:4];
    NSString *iconName = item.icon;
    [upperTitle setFont:[UIFont fontWithName:@"Roboto-Regular" size:12]];
    [upperTitle setText:item.upperLabel];
    if (indexPath.row == 0){
        iconName = @"connection_off";
        if ([AppDelegate instance].serverOnLine){
            iconName = @"connection_on";
        }
        line.hidden = YES;
        int cellHeight = PAD_MENU_INFO_HEIGHT;
        int cellHeightPad = cellHeight - 4;
        [title setText:@""];
        [icon setFrame:CGRectMake(icon.frame.origin.x, (int)((cellHeight / 2) - (cellHeightPad / 2)), cellHeightPad, cellHeightPad)];
    }
    else{
        [title setFont:[UIFont fontWithName:@"Roboto-Regular" size:20]];
        [title setText:[item.mainLabel uppercaseString]];
    }
    [icon setImage:[UIImage imageNamed:iconName]];
    if ([AppDelegate instance].serverOnLine){
        [icon setAlpha:1];
        [upperTitle setAlpha:1];
        [title setAlpha:1];
    }
    else if (indexPath.row != 0){
        [icon setAlpha:0.3];
        [upperTitle setAlpha:0.3];
        [title setAlpha:0.3];
    }
    return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![AppDelegate instance].serverOnLine) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    mainMenu *item = [mainMenuItems objectAtIndex:indexPath.row];
    if (item.family == 2){
        [[AppDelegate instance].windowController.stackScrollViewController offView];
    }
    else{
        if (lastSelected==indexPath.row){
            [[AppDelegate instance].windowController.stackScrollViewController offView];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            lastSelected=-1;
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollOnScreen" object: nil]; 
        if (item.family == 1){
            DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:item withFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height) bundle:nil];
            [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:detailViewController invokeByController:self isStackStartView:TRUE];
            [[AppDelegate instance].windowController.stackScrollViewController enablePanGestureRecognizer];
        }   
        else if (item.family == 3){
            RemoteController *remoteController=[[RemoteController alloc] initWithNibName:@"RemoteController" bundle:nil]; 
            [remoteController.view setFrame:CGRectMake(0, 0, STACKSCROLL_WIDTH, self.view.frame.size.height)];
            [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:remoteController invokeByController:self isStackStartView:TRUE];
            [[AppDelegate instance].windowController.stackScrollViewController disablePanGestureRecognizer:remoteController.panFallbackImageView];
        }
        lastSelected = (int)indexPath.row;
    }
}

- (void)setLastSelected:(int)selection{
    lastSelected = selection;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
}


- (void)dealloc {
//    [_tableView release];
//    [super dealloc];
}


@end

