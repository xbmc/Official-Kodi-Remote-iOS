//
//  RightMenuViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 9/11/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "RightMenuViewController.h"

@interface RightMenuViewController ()
@property (nonatomic, unsafe_unretained) CGFloat peekLeftAmount;
@end

@implementation RightMenuViewController
@synthesize peekLeftAmount;
@synthesize rightMenuItems = _rightMenuItems;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark -
#pragma mark Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 64;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    //    return 10;
    return [_rightMenuItems count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell=nil;
    cell = [tableView dequeueReusableCellWithIdentifier:@"mainMenuCell"];
    [[NSBundle mainBundle] loadNibNamed:@"cellViewIPad" owner:self options:NULL];
    if (cell==nil)
        cell = resultMenuCell;
//    mainMenu *item = [mainMenuItems objectAtIndex:indexPath.row];
//    [(UIImageView*) [cell viewWithTag:1] setImage:[UIImage imageNamed:item.icon]];
//    [(UILabel*) [cell viewWithTag:2] setText:item.upperLabel];
//    [(UILabel*) [cell viewWithTag:3] setFont:[UIFont fontWithName:@"DejaVuSans-Bold" size:20]];
//    [(UILabel*) [cell viewWithTag:3] setText:item.mainLabel];
//    if ([AppDelegate instance].serverOnLine){
//        [(UIImageView*) [cell viewWithTag:1] setAlpha:1];
//        [(UIImageView*) [cell viewWithTag:2] setAlpha:1];
//        [(UIImageView*) [cell viewWithTag:3] setAlpha:1];
//        cell.selectionStyle=UITableViewCellSelectionStyleBlue;
//    }
//    else {
//        [(UIImageView*) [cell viewWithTag:1] setAlpha:0.3];
//        [(UIImageView*) [cell viewWithTag:2] setAlpha:0.3];
//        [(UIImageView*) [cell viewWithTag:3] setAlpha:0.3];
//        cell.selectionStyle=UITableViewCellSelectionStyleGray;
//    }
    return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (![AppDelegate instance].serverOnLine) {
//        [tableView deselectRowAtIndexPath:indexPath animated:YES];
//        return;
//    }
//    mainMenu *item = [mainMenuItems objectAtIndex:indexPath.row];
//    if (item.family == 2){
//        [[AppDelegate instance].windowController.stackScrollViewController offView];
//    }
//    else{
//        if (lastSelected==indexPath.row){
//            [[AppDelegate instance].windowController.stackScrollViewController offView];
//            [tableView deselectRowAtIndexPath:indexPath animated:YES];
//            lastSelected=-1;
//            return;
//        }
//        [[NSNotificationCenter defaultCenter] postNotificationName: @"StackScrollOnScreen" object: nil];
//        if (item.family == 1){
//            DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:item withFrame:CGRectMake(0, 0, 477, self.view.frame.size.height) bundle:nil];
//            [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:detailViewController invokeByController:self isStackStartView:TRUE];
//            [[AppDelegate instance].windowController.stackScrollViewController enablePanGestureRecognizer];
//        }
//        else if (item.family == 3){
//            RemoteController *remoteController=[[RemoteController alloc] initWithNibName:@"RemoteController" bundle:nil];
//            [remoteController.view setFrame:CGRectMake(0, 0, 477, self.view.frame.size.height)];
//            [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:remoteController invokeByController:self isStackStartView:TRUE];
//            [[AppDelegate instance].windowController.stackScrollViewController disablePanGestureRecognizer:remoteController.panFallbackImageView];
//        }
//        lastSelected=indexPath.row;
//    }
}


#pragma mark - LifeCycle
- (void)viewDidLoad{
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor colorWithRed:.141f green:.141f blue:.141f alpha:1]];
    self.peekLeftAmount = 40.0f;
    [self.slidingViewController setAnchorLeftPeekAmount:self.peekLeftAmount];
    self.slidingViewController.underRightWidthLayout = ECVariableRevealWidth;
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

@end
