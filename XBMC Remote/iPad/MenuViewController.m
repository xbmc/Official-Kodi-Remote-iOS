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

#import "MenuViewController.h"
#import "DataViewController.h"
#import "AppDelegate.h"
#import "ViewControllerIPad.h"
#import "StackScrollViewController.h"
#import "mainMenu.h"


@implementation MenuViewController
@synthesize tableView = _tableView;

#pragma mark -
#pragma mark View lifecycle

- (id)initWithFrame:(CGRect)frame mainMenu:(NSMutableArray *)menu{
    if (self = [super init]) {
		[self.view setFrame:frame]; 
		_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
        [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
		[_tableView setDelegate:self];
		[_tableView setDataSource:self];
		[_tableView setBackgroundColor:[UIColor clearColor]];
        mainMenuItems=menu;
        UIView* footerView =  [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
		_tableView.tableFooterView = footerView;
//        [footerView release];
        
		[self.view addSubview:_tableView];
		
		UIView* verticalLineView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width, -5, 1, self.view.frame.size.height)];
		[verticalLineView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
		[verticalLineView setBackgroundColor:[UIColor darkGrayColor]];
		[self.view addSubview:verticalLineView];
		[self.view bringSubviewToFront:verticalLineView];
//        [verticalLineView release];
		
	}
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

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
    return 70;
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


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    
    
    
    UITableViewCell *cell=nil;
        cell = [tableView dequeueReusableCellWithIdentifier:@"mainMenuCell"];
        [[NSBundle mainBundle] loadNibNamed:@"cellViewIPad" owner:self options:NULL];
        if (cell==nil)
            cell = resultMenuCell;
        mainMenu *item = [mainMenuItems objectAtIndex:indexPath.row];
        [(UIImageView*) [cell viewWithTag:1] setImage:[UIImage imageNamed:item.icon]];
        [(UILabel*) [cell viewWithTag:2] setText:item.upperLabel];   
        [(UILabel*) [cell viewWithTag:3] setText:item.mainLabel]; 
//        if (serverOnLine){
            [(UIImageView*) [cell viewWithTag:1] setAlpha:1];
            [(UIImageView*) [cell viewWithTag:2] setAlpha:1];
            [(UIImageView*) [cell viewWithTag:3] setAlpha:1];
            cell.selectionStyle=UITableViewCellSelectionStyleBlue;
//        }
//        else {
//            [(UIImageView*) [cell viewWithTag:1] setAlpha:0.3];
//            [(UIImageView*) [cell viewWithTag:2] setAlpha:0.3];
//            [(UIImageView*) [cell viewWithTag:3] setAlpha:0.3];
//            cell.selectionStyle=UITableViewCellSelectionStyleGray;
//            
//        }
        
        return cell;
    
    
    
    
    
    
    
//    
//    static NSString *CellIdentifier = @"Cell";
//    
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
//		UIView* bgView = [[UIView alloc] init];
//		[bgView setBackgroundColor:[UIColor colorWithWhite:2 alpha:0.2]];
//		[cell setSelectedBackgroundView:bgView];
//    }
//    
//    // Configure the cell...
//	cell.textLabel.text = [NSString stringWithFormat:@"Menu %d", indexPath.row +1];
//	[cell.textLabel setTextColor:[UIColor whiteColor]];
//
//
//    return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DataViewController *dataViewController = [[DataViewController alloc] initWithFrame:CGRectMake(0, 0, 477, self.view.frame.size.height)];
	[[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:dataViewController invokeByController:self isStackStartView:TRUE];
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

