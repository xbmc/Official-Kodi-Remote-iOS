//
//  MoreItemsViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "MoreItemsViewController.h"
#import "AppDelegate.h"

@implementation MoreItemsViewController

@synthesize tableView = _tableView;

- (id)initWithFrame:(CGRect)frame mainMenu:(NSMutableArray *)menu{
    if (self = [super init]) {
        cellLabelOffset = 50;
		[self.view setFrame:frame];
		_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
//        [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
		[_tableView setDelegate:self];
		[_tableView setDataSource:self];
        [_tableView setBackgroundColor:[UIColor clearColor]];
        mainMenuItems=menu;
        UIView* footerView =  [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
		_tableView.tableFooterView = footerView;
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")){
            [_tableView setSeparatorInset:UIEdgeInsetsMake(0, cellLabelOffset, 0, 0)];
        }
		[self.view addSubview:_tableView];
	}
    return self;
}
#pragma mark -
#pragma mark Table view data source

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//    return 64;
//}

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
	cell.backgroundColor = [UIColor whiteColor];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *tableCellIdentifier = @"UITableViewCell";
	UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableCellIdentifier];
	}
    cell.accessoryType =  UITableViewCellAccessoryDisclosureIndicator; 

    UILabel *cellLabel = [[UILabel alloc] initWithFrame:CGRectMake(cellLabelOffset, 0, self.view.bounds.size.width - cellLabelOffset - 24, 43)];
    [cellLabel setFont:[UIFont systemFontOfSize:18]];
    [cellLabel setTextColor:[UIColor blackColor]];
    [cellLabel setHighlightedTextColor:[UIColor whiteColor]];
    NSDictionary *item = [mainMenuItems objectAtIndex:indexPath.row];
    [cellLabel setText:[item objectForKey:@"label"]];
    [cell.contentView addSubview:cellLabel];
    if (![[item objectForKey:@"icon"] isEqualToString:@""]){
        CGRect iconImageViewRect = CGRectMake(8.0f, 6.0f, 34.0f, 30.0f);
        UIImageView *iconImage = [[UIImageView alloc] initWithFrame:iconImageViewRect];
        [iconImage setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@_black", [item objectForKey:@"icon"]]]];
        [cell.contentView addSubview:iconImage];
    }
    return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[NSNotificationCenter defaultCenter] postNotificationName: @"tabHasChanged" object: indexPath]; 
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - LifeCycle

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (void)viewDidUnload{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(BOOL)shouldAutorotate{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

@end
