//
//  DetailViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "DetailViewController.h"
#import "mainMenu.h"
#import "DSJSONRPC.h"
#import "UIImageView+WebCache.h"
#import "GlobalData.h"
#import "ShowInfoViewController.h"
#import "DetailViewController.h"
#import "NowPlaying.h"
#import "PlayFileViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "SDImageCache.h"
#import "WebViewController.h"
#import "AppDelegate.h"
#import "ViewControllerIPad.h"
#import "StackScrollViewController.h"

@interface DetailViewController ()
- (void)configureView;
@end

@implementation DetailViewController

@synthesize detailItem = _detailItem;
@synthesize activityIndicatorView;
@synthesize sections;
@synthesize detailViewController;
@synthesize nowPlaying;
@synthesize showInfoViewController;
@synthesize playFileViewController;
@synthesize filteredListContent;
@synthesize richResults;
@synthesize webViewController;
//@synthesize detailDescriptionLabel = _detailDescriptionLabel;
#define SECTIONS_START_AT 100
#define SHOW_ONLY_VISIBLE_THUMBNAIL_START_AT 50
#define MAX_NORMAL_BUTTONS 4

- (id)initWithFrame:(CGRect)frame {
    if (self = [super init]) {
		[self.view setFrame:frame]; 
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil withItem:(mainMenu *)item withFrame:(CGRect)frame bundle:(NSBundle *)nibBundleOrNil{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.detailItem = item;
        [self.view setFrame:frame]; 
    }
    return self;
}

- (NSString *)convertTimeFromSeconds:(NSNumber *)seconds {
    NSString *result = @"";    
    int secs = [seconds intValue];
    int tempHour    = 0;
    int tempMinute  = 0;
    int tempSecond  = 0;
    NSString *hour      = @"";
    NSString *minute    = @"";
    NSString *second    = @"";    
    tempHour    = secs / 3600;
    tempMinute  = secs / 60 - tempHour * 60;
    tempSecond  = secs - (tempHour * 3600 + tempMinute * 60);
    hour    = [[NSNumber numberWithInt:tempHour] stringValue];
    minute  = [[NSNumber numberWithInt:tempMinute] stringValue];
    second  = [[NSNumber numberWithInt:tempSecond] stringValue];
    if (tempHour < 10) {
        hour = [@"0" stringByAppendingString:hour];
    } 
    if (tempMinute < 10) {
        minute = [@"0" stringByAppendingString:minute];
    }
    if (tempSecond < 10) {
        second = [@"0" stringByAppendingString:second];
    }
    if (tempHour == 0) {
        result = [NSString stringWithFormat:@"%@:%@", minute, second];
        
    } else {
        result = [NSString stringWithFormat:@"%@:%@:%@",hour, minute, second];
    }
    return result;    
}

- (NSDictionary *) indexKeyedDictionaryFromArray:(NSArray *)array {
    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
    int numelement=[array count];
    for (int i=0;i<numelement-1;i+=2){
        [mutableDictionary setObject:[array objectAtIndex:i] forKey:[array objectAtIndex:i+1]];
    }
    return (NSDictionary *)mutableDictionary;
}

- (NSMutableDictionary *) indexKeyedMutableDictionaryFromArray:(NSArray *)array {
    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
    int numelement=[array count];
    for (int i=0;i<numelement-1;i+=2){
        [mutableDictionary setObject:[array objectAtIndex:i] forKey:[array objectAtIndex:i+1]];
    }
    return (NSMutableDictionary *)mutableDictionary;
}
#pragma mark - Tabbar management

-(IBAction)showMore:(id)sender{
//    if ([sender tag]==choosedTab) return;
    [activityIndicatorView startAnimating];
    NSArray *buttonsIB=[NSArray arrayWithObjects:button1, button2, button3, button4, button5, nil];
    if (choosedTab<[buttonsIB count]){
        [[buttonsIB objectAtIndex:choosedTab] setSelected:NO];
    }
    choosedTab=MAX_NORMAL_BUTTONS;
    [[buttonsIB objectAtIndex:choosedTab] setSelected:YES];
    [self AnimTable:dataList AnimDuration:0.3 Alpha:1.0 XPos:viewWidth];
    int i;
    int count = [[self.detailItem mainParameters] count];
    NSMutableArray *mainMenu = [[NSMutableArray alloc] init];
    int numIcons = [[self.detailItem mainButtons] count];
    for (i = MAX_NORMAL_BUTTONS; i < count; i++){
        NSString *icon = @"";
        if (i < numIcons){
            icon = [[self.detailItem mainButtons] objectAtIndex:i];
        }
        [mainMenu addObject: 
         [NSDictionary dictionaryWithObjectsAndKeys:
          [NSString stringWithFormat:@"%@",[[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:i]] objectForKey:@"morelabel"]], @"label", 
          icon, @"icon",
          nil]];
    }
    if (moreItemsViewController == nil){
        moreItemsViewController = [[MoreItemsViewController alloc] initWithFrame:CGRectMake(dataList.bounds.size.width, 0, dataList.bounds.size.width, dataList.bounds.size.height) mainMenu:mainMenu];
        [moreItemsViewController.view setBackgroundColor:[UIColor clearColor]];
        [moreItemsViewController viewWillAppear:FALSE];
        [moreItemsViewController viewDidAppear:FALSE];
        [detailView addSubview:moreItemsViewController.view];
    }
    [self AnimView:moreItemsViewController.view AnimDuration:0.3 Alpha:1.0 XPos:0];
    self.navigationItem.title = [NSString stringWithFormat:@"More (%d)", (count - MAX_NORMAL_BUTTONS)];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.3];
        topNavigationLabel.alpha = 0;
        [UIView commitAnimations];
        topNavigationLabel.text = [NSString stringWithFormat:@"More (%d)", (count - MAX_NORMAL_BUTTONS)];
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.1];
        topNavigationLabel.alpha = 1;
        [UIView commitAnimations];
    }
    [activityIndicatorView stopAnimating];
}


- (void) handleTabHasChanged:(NSNotification*) notification{
    NSArray *buttons=[self.detailItem mainButtons];
    if (![buttons count]) return;
    NSIndexPath *choice=notification.object;
    choosedTab = 0;
    int selectedIdx = MAX_NORMAL_BUTTONS + choice.row;
    selectedMoreTab.tag=selectedIdx;
    [self changeTab:selectedMoreTab];
}

-(IBAction)changeTab:(id)sender{
    if ([sender tag]==choosedTab) return;
    [self AnimView:moreItemsViewController.view AnimDuration:0.3 Alpha:1.0 XPos:viewWidth];
    numTabs=[[self.detailItem mainMethod] count];
    int newChoosedTab=[sender tag];
    if (newChoosedTab>=numTabs){
        newChoosedTab=0;
    }
    if (newChoosedTab==choosedTab) return;
    [activityIndicatorView startAnimating];
    NSArray *buttonsIB=[NSArray arrayWithObjects:button1, button2, button3, button4, button5, nil];
    if (choosedTab<[buttonsIB count]){
        [[buttonsIB objectAtIndex:choosedTab] setSelected:NO];
    }
    else {
        [[buttonsIB objectAtIndex:MAX_NORMAL_BUTTONS] setSelected:NO];
    }
    choosedTab=newChoosedTab;
    if (choosedTab<[buttonsIB count]){
        [[buttonsIB objectAtIndex:choosedTab] setSelected:YES];
    }
    [self AnimTable:dataList AnimDuration:0.3 Alpha:1.0 XPos:viewWidth];
    if ([self.richResults count] && (dataList.dragging == YES || dataList.decelerating == YES)){
        NSArray *visiblePaths = [dataList indexPathsForVisibleRows];
        [dataList scrollToRowAtIndexPath:[visiblePaths objectAtIndex:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    self.navigationItem.title = [[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]] objectForKey:@"label"];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.3];
        topNavigationLabel.alpha = 0;
        [UIView commitAnimations];
        topNavigationLabel.text = [[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]] objectForKey:@"label"];
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.1];
        topNavigationLabel.alpha = 1;
        [UIView commitAnimations];
    }
    NSDictionary *methods=[self indexKeyedDictionaryFromArray:[[self.detailItem mainMethod] objectAtIndex:choosedTab]];
    NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
    if ([methods objectForKey:@"method"]!=nil){
        [self retrieveData:[methods objectForKey:@"method"] parameters:[parameters objectForKey:@"parameters"]];
    }
    else {
        [activityIndicatorView stopAnimating];
        [self AnimTable:dataList AnimDuration:0.3 Alpha:1.0 XPos:0];
        [self loadImagesForOnscreenRows];
    }
}

#pragma mark - Table Animation 

-(void)alphaImage:(UIImageView *)image AnimDuration:(float)seconds Alpha:(float)alphavalue{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	image.alpha = alphavalue;
    [UIView commitAnimations];
}

-(void)alphaView:(UIView *)view AnimDuration:(float)seconds Alpha:(float)alphavalue{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	view.alpha = alphavalue;
    [UIView commitAnimations];
}

- (void)AnimTable:(UITableView *)tV AnimDuration:(float)seconds Alpha:(float)alphavalue XPos:(int)X{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	tV.alpha = alphavalue;
	CGRect frame;
	frame = [tV frame];
	frame.origin.x = X;
	tV.frame = frame;
    [UIView commitAnimations];
}

- (void)AnimView:(UIView *)view AnimDuration:(float)seconds Alpha:(float)alphavalue XPos:(int)X{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	view.alpha = alphavalue;
	CGRect frame;
	frame = [view frame];
	frame.origin.x = X;
	view.frame = frame;
    [UIView commitAnimations];
}

#pragma mark - Cell Formatting 


int cellWidth=0;
int originYear=0;
int labelPosition=0;
-(void)choseParams{ // DA OTTIMIZZARE TROPPI IF!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    mainMenu *Menuitem = self.detailItem;
    NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
    if ([[parameters objectForKey:@"defaultThumb"] length]!=0){
        defaultThumb= [parameters objectForKey:@"defaultThumb"];
    }
    else {
        defaultThumb=[self.detailItem defaultThumb];
    }
    if ([parameters objectForKey:@"rowHeight"]!=0)
        cellHeight =[[parameters objectForKey:@"rowHeight"] intValue];
    else if (Menuitem.rowHeight!=0){
        cellHeight=Menuitem.rowHeight;
    }
    else {
        cellHeight=76;
    }

    if ([parameters objectForKey:@"thumbWidth"]!=0)
        thumbWidth =[[parameters objectForKey:@"thumbWidth"] intValue];
    else if (Menuitem.thumbWidth!=0){
        thumbWidth=Menuitem.thumbWidth;
    }
    else {
        thumbWidth=53;
    }
    labelPosition=thumbWidth+8;
    int newWidthLabel=0;
    
    
    if (Menuitem.originLabel && ![parameters objectForKey:@"thumbWidth"])
        labelPosition=Menuitem.originLabel;
    // CHECK IF THERE ARE SECTIONS
    if ([self.richResults count]<SECTIONS_START_AT || ![self.detailItem enableSection]){
        newWidthLabel = viewWidth - 8 - labelPosition;
        Menuitem.originYearDuration = viewWidth - 72;
    }
    else{
        newWidthLabel=viewWidth - 38 - labelPosition;
        Menuitem.originYearDuration = viewWidth - 100;
    }
    
    Menuitem.widthLabel=newWidthLabel;
    
}


#pragma mark - Table Management

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return cellHeight;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.searchDisplayController.searchResultsTableView){
        return 1;
    }
	else{
        return [[self.sections allKeys] count];
        
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{ 
    if (tableView == self.searchDisplayController.searchResultsTableView){
        int numResult=[self.filteredListContent count];
        if (numResult){
            if (numResult!=1)
                return [NSString stringWithFormat:@"%d results", [self.filteredListContent count]];
            else {
                return @"1 result";
            }
        }
        else {
            return @"";
        }
    }
    else {
        if(section == 0){return nil;}
        return [[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.filteredListContent count];
    }
	else {
        return [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section]] count];  
    }
}

-(NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index{
    if (index==0){
        [tableView scrollRectToVisible:tableView.tableHeaderView.frame animated:NO];
        return  index -1 ;
    }
    return index;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (tableView == self.searchDisplayController.searchResultsTableView){
        return nil;
    }
    else {
        if ([self.detailItem enableSection]  && [self.richResults count]>SECTIONS_START_AT){
            return [[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        }
        else {
            return nil;
        }
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {    
	cell.backgroundColor = [UIColor whiteColor];
//    cell.accessoryView.
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *identifier = @"jsonDataCellIdentifier";
    jsonDataCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"jsonDataCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    

    mainMenu *Menuitem = self.detailItem;
    NSDictionary *mainFields=[[Menuitem mainFields] objectAtIndex:choosedTab];
    
/* future - need to be tweaked: doesn't work on file mode. mainLabel need to be resized */
//    NSDictionary *methods=[self indexKeyedDictionaryFromArray:[[Menuitem.subItem mainMethod] objectAtIndex:choosedTab]];
//    if ([methods objectForKey:@"method"]!=nil){ // THERE IS A CHILD
//        cell.accessoryType =  UITableViewCellAccessoryDisclosureIndicator; 
//    }
/* end future */
    CGRect frame=cell.urlImageView.frame;
    frame.size.width=thumbWidth;
    cell.urlImageView.frame=frame;
    NSDictionary *item=nil;
    int checkNum=numResults;
    if (tableView == self.searchDisplayController.searchResultsTableView){
        checkNum=numFilteredResults;
        item = [self.filteredListContent objectAtIndex:indexPath.row];
    }
	else{
        item = [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    }
    UILabel *title=(UILabel*) [cell viewWithTag:1];
    UILabel *runtimeyear=(UILabel*) [cell viewWithTag:3];
    UILabel *rating=(UILabel*) [cell viewWithTag:5];

    frame=title.frame;
    frame.origin.x=labelPosition;
    title.frame=frame;
    
    [title setText:[item objectForKey:@"label"]];
    [(UILabel*) [cell viewWithTag:2] setText:[item objectForKey:[mainFields objectForKey:@"row2"]]];
    
    frame=title.frame;
    frame.size.width=Menuitem.widthLabel;
    title.frame=frame;
    
    frame=runtimeyear.frame;
    frame.origin.x=Menuitem.originYearDuration;
    runtimeyear.frame=frame;
    
    frame=rating.frame;
    frame.origin.x=Menuitem.originYearDuration;
    rating.frame=frame;
    if ([[Menuitem.showRuntime objectAtIndex:choosedTab] boolValue]){
        NSString *duration=@"";
        if (!Menuitem.noConvertTime){
            duration=[self convertTimeFromSeconds:[item objectForKey:@"runtime"]];
        }
        else {
            duration=[item objectForKey:@"runtime"];
        }
        [runtimeyear setText:duration];        
    }
    else {
        [runtimeyear setText:[item objectForKey:@"year"]];
    }
    [(UILabel*) [cell viewWithTag:4] setText:[item objectForKey:@"runtime"]];
    [rating setText:[item objectForKey:@"rating"]];
    
    
    NSString *stringURL = [item objectForKey:@"thumbnail"];
    NSString *displayThumb=defaultThumb;
    if ([[item objectForKey:@"filetype"] length]!=0){
//        NSLog(@"FILETYPE %@ %@", [item objectForKey:@"filetype"], stringURL);

        displayThumb=stringURL;
    }
    //dataList.dragging == NO && 
    // NOT CONSIDERING AT THE MOMENT THE SEARCH RESULT TABLE
    if ((dataList.decelerating == NO && self.searchDisplayController.searchResultsTableView.decelerating == NO) || checkNum<SHOW_ONLY_VISIBLE_THUMBNAIL_START_AT){ 
//        NSURL *imageUrl = [NSURL URLWithString: stringURL];    
//        UIImage *cachedImage = [manager imageWithURL:imageUrl];
//        if (cachedImage){
//            cell.urlImageView.image=cachedImage;
//        }
//        else {    
            [cell.urlImageView setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:displayThumb] ];
//        }
    }
    else {
        cell.urlImageView.image=[UIImage imageNamed:displayThumb];  
    }
// TEST
//    cell.urlImageView.image=[UIImage imageNamed:Menuitem.defaultThumb];  
    //  [self alphaImage:cell.urlImageView AnimDuration:0.1 Alpha:1.0];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    self.detailViewController=nil;
    mainMenu *MenuItem=self.detailItem;
    NSDictionary *methods=[self indexKeyedDictionaryFromArray:[[MenuItem.subItem mainMethod] objectAtIndex:choosedTab]];
    if ([methods objectForKey:@"method"]!=nil){ // THERE IS A CHILD
        NSDictionary *mainFields=[[MenuItem mainFields] objectAtIndex:choosedTab];
        NSDictionary *item = nil;
        if (tableView == self.searchDisplayController.searchResultsTableView){
            item = [self.filteredListContent objectAtIndex:indexPath.row];
        }
        else{
            item = [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
        }
        MenuItem.subItem.mainLabel=@"";
        MenuItem.subItem.upperLabel=[item objectForKey:@"label"];
        
        NSMutableDictionary *parameters=[self indexKeyedMutableDictionaryFromArray:[[MenuItem.subItem mainParameters] objectAtIndex:choosedTab]]; 
        if ([[parameters objectForKey:@"parameters"] objectForKey:@"properties"]!=nil){ // CHILD IS LIBRARY MODE
            NSString *key=@"null";
            if ([item objectForKey:[mainFields objectForKey:@"row15"]]!=nil){
                key=[mainFields objectForKey:@"row15"];
            }  
            NSMutableArray *newParameters=[NSMutableArray arrayWithObjects:
                                           [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [item objectForKey:[mainFields objectForKey:@"row6"]],[mainFields objectForKey:@"row6"],
                                            [[parameters objectForKey:@"parameters"] objectForKey:@"properties"], @"properties",
                                            [[parameters objectForKey:@"parameters"] objectForKey:@"sort"],@"sort",
                                            [item objectForKey:[mainFields objectForKey:@"row15"]], key,
                                            nil], @"parameters", [parameters objectForKey:@"label"], @"label", 
                                           nil];
            
            [[MenuItem.subItem mainParameters] replaceObjectAtIndex:choosedTab withObject:newParameters];
            MenuItem.subItem.chooseTab=choosedTab;
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
                self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
                self.detailViewController.detailItem = MenuItem.subItem;
                [self.navigationController pushViewController:self.detailViewController animated:YES];
            }
            else{
                DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:MenuItem.subItem withFrame:CGRectMake(0, 0, 477, self.view.frame.size.height) bundle:nil];                
                [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:FALSE];
                
            }
            
        }
        else { // CHILD IS FILEMODE
            if ([[item objectForKey:@"filetype"] length]!=0){ // WE ARE ALREADY IN BROWSING FILES MODE
                if ([[item objectForKey:@"filetype"] isEqualToString:@"directory"]){
                    [parameters removeAllObjects];
                    parameters=[self indexKeyedMutableDictionaryFromArray:[[MenuItem mainParameters] objectAtIndex:choosedTab]]; 
                    NSMutableArray *newParameters=[NSMutableArray arrayWithObjects:
                                                   [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                    [item objectForKey:[mainFields objectForKey:@"row6"]],@"directory",
                                                    [[parameters objectForKey:@"parameters"] objectForKey:@"media"], @"media",
                                                    [[parameters objectForKey:@"parameters"] objectForKey:@"sort"],@"sort",
                                                    nil], @"parameters", [parameters objectForKey:@"label"], @"label", @"nocover_filemode.png", @"defaultThumb", @"35", @"rowHeight", @"35", @"thumbWidth", @"icon_song",@"fileThumb",
                                                   nil];
                    MenuItem.upperLabel=[NSString stringWithFormat:@"%@",[item objectForKey:@"label"]];

                    [[MenuItem mainParameters] replaceObjectAtIndex:choosedTab withObject:newParameters];
                    MenuItem.chooseTab=choosedTab;
                    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
                        self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
                        self.detailViewController.detailItem = MenuItem;
                        [self.navigationController pushViewController:self.detailViewController animated:YES];
                    }
                    else{
                        DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:MenuItem withFrame:CGRectMake(0, 0, 477, self.view.frame.size.height) bundle:nil];                
                        [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:FALSE];
                    }

                }
                else if ([[item objectForKey:@"genre"] isEqualToString:@"file"]){
                    [self addPlayback:indexPath position:indexPath.row];
                    return;
                }
                else
                    return;
            }
            else{ // WE ENTERING FILEMODE
                NSMutableArray *newParameters=[NSMutableArray arrayWithObjects:
                                               [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                [item objectForKey:[mainFields objectForKey:@"row6"]],@"directory",
                                                [[parameters objectForKey:@"parameters"] objectForKey:@"media"], @"media",
                                                [[parameters objectForKey:@"parameters"] objectForKey:@"sort"],@"sort",

                                                nil], @"parameters", [parameters objectForKey:@"label"], @"label", @"nocover_filemode.png", @"defaultThumb", @"35", @"rowHeight", @"35", @"thumbWidth",
                                               nil];
                [[MenuItem.subItem mainParameters] replaceObjectAtIndex:choosedTab withObject:newParameters];
                MenuItem.subItem.chooseTab=choosedTab;
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
                    
                    self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
                    self.detailViewController.detailItem = MenuItem.subItem;
                    [self.navigationController pushViewController:self.detailViewController animated:YES];
                }
                else{
                    DetailViewController *iPadDetailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" withItem:MenuItem.subItem withFrame:CGRectMake(0, 0, 477, self.view.frame.size.height) bundle:nil];                
                    [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadDetailViewController invokeByController:self isStackStartView:FALSE];
                }
            }
        }
    }
    else {

        if (MenuItem.showInfo){
            [self showInfo:indexPath];
        }
        else {
            [self addPlayback:indexPath position:indexPath.row];
        }
    }
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
        UIImage *myImage = [UIImage imageNamed:@"blank.png"];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:myImage] ;
        imageView.frame = CGRectMake(0,0,viewWidth,1);
        return imageView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1;
}

#pragma mark -
#pragma mark Deferred image loading (UIScrollViewDelegate)

- (void)loadImagesForOnscreenRows{
    int checkNum=numResults;
    if ([self.searchDisplayController isActive]){
        checkNum=numFilteredResults;
    }
    if (checkNum>=SHOW_ONLY_VISIBLE_THUMBNAIL_START_AT){//[self.searchDisplayController isActive]
    
        NSArray *visiblePaths = nil;
        if ([self.searchDisplayController isActive]){
            visiblePaths = [self.searchDisplayController.searchResultsTableView indexPathsForVisibleRows];
        }
        else {
            visiblePaths = [dataList indexPathsForVisibleRows];
        }
        for (NSIndexPath *indexPath in visiblePaths){
            UITableViewCell *cell = nil;
            NSDictionary *item = nil;
            if ([self.searchDisplayController isActive]){
                cell = [self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:indexPath];
                item = [self.filteredListContent objectAtIndex:indexPath.row];

            }
            else {
                cell = [dataList cellForRowAtIndexPath:indexPath];
                item = [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
            }
            UIImageView *thumb=(UIImageView*) [cell viewWithTag:6];
            NSString *stringURL = [item objectForKey:@"thumbnail"];
            NSURL *imageUrl = [NSURL URLWithString: stringURL];    
            UIImage *cachedImage = [manager imageWithURL:imageUrl];
            NSString *displayThumb=defaultThumb;
            if ([[item objectForKey:@"filetype"] length]!=0){
                displayThumb=stringURL;
            }
            if (cachedImage){
                thumb.image=cachedImage;
            }
            else {            
                [thumb setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:displayThumb]];
            }
        }
    }
}
// Load images for all onscreen rows when scrolling is finished
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (!decelerate && numResults>=SHOW_ONLY_VISIBLE_THUMBNAIL_START_AT){
        [self loadImagesForOnscreenRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (numResults>=SHOW_ONLY_VISIBLE_THUMBNAIL_START_AT){
        [self loadImagesForOnscreenRows];
    }
}

//- (void)scrollViewDidScroll:(UIScrollView *)activeScrollView {  
//    activeScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
//    NSLog(@"SPEED: %f", activeScrollView.decelerationRate);
//}

#pragma mark -
#pragma mark Content Filtering


- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope{
	/*
	 Update the filtered array based on the search text and scope.
	 */
	[self.filteredListContent removeAllObjects]; // First clear the filtered array.
	
	/*
	 Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
	 */
	for (NSDictionary *item in richResults){
//		if ([scope isEqualToString:@"All"] || [[NSString stringWithFormat:@"%@",[item objectForKey:@"label"]] isEqualToString:scope])
//		{
//			NSComparisonResult result = [[NSString stringWithFormat:@"%@",[item objectForKey:@"label"]] compare:searchText options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) range:NSMakeRange(0, [searchText length])];
//            if (result == NSOrderedSame)
//			{
//				[self.filteredListContent addObject:item];
//            }
        
        NSRange range = [[NSString stringWithFormat:@"%@",[item objectForKey:@"label"]] rangeOfString:searchText options:NSCaseInsensitiveSearch];
        if (range.location != NSNotFound) {
            [self.filteredListContent addObject:item];
        }
//		}
	}
    numFilteredResults=[self.filteredListContent count];
}


#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods
UILongPressGestureRecognizer *longPressGesture;

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller {
    //[controller.searchResultsTableView setDelegate:self];
    controller.searchResultsTableView.backgroundColor = [UIColor blackColor]; 
    longPressGesture = [UILongPressGestureRecognizer new];
    [longPressGesture addTarget:self action:@selector(handleLongPress)];
    [self.searchDisplayController.searchResultsTableView addGestureRecognizer:longPressGesture];
//    [self.searchDisplayController.searchResultsTableView.setN
}

-(void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    if (longPressGesture) {
        [self.searchDisplayController.searchResultsTableView removeGestureRecognizer:longPressGesture];
        longPressGesture = nil;
    }
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString{
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}



#pragma mark - Long Press & Action sheet

NSIndexPath *selected;

-(IBAction)handleLongPress{
    if (lpgr.state == UIGestureRecognizerStateBegan || longPressGesture.state == UIGestureRecognizerStateBegan){
        CGPoint p = [lpgr locationInView:dataList];
        NSIndexPath *indexPath = [dataList indexPathForRowAtPoint:p];
        CGPoint p2 = [longPressGesture locationInView:self.searchDisplayController.searchResultsTableView];
        NSIndexPath *indexPath2 = [self.searchDisplayController.searchResultsTableView indexPathForRowAtPoint:p2];
        CGPoint selectedPoint;
        if (indexPath != nil || indexPath2 != nil ){
            selected=indexPath;
            selectedPoint=[lpgr locationInView:self.view];

            NSArray *sheetActions=[[self.detailItem sheetActions] objectAtIndex:choosedTab];
            int numActions=[sheetActions count];
            if (numActions){
                NSDictionary *item = nil;
                if ([self.searchDisplayController isActive]){
                    selected=indexPath2;
                    selectedPoint=[longPressGesture locationInView:self.view];
                    item = [self.filteredListContent objectAtIndex:indexPath2.row];
                }
                else{
                    item = [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
                }
//                if ([[item objectForKey:@"filetype"] isEqualToString:@"directory"]) { // DOESN'T WORK AT THE MOMENT IN XBMC?????
//                    return;
//                }                
                NSString *title=[NSString stringWithFormat:@"%@\n%@", [item objectForKey:@"label"], [item objectForKey:@"genre"]];
                UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:title
                                                                    delegate:self
                                                           cancelButtonTitle:nil
                                                      destructiveButtonTitle:nil
                                                           otherButtonTitles:nil
                                         ];
                for (int i = 0; i < numActions; i++) {
                    [action addButtonWithTitle:[sheetActions objectAtIndex:i]];
                }
                action.cancelButtonIndex = [action addButtonWithTitle:@"Cancel"];
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
                    [action showInView:self.view];
                }
                else{
                   [action showFromRect:CGRectMake(selectedPoint.x, selectedPoint.y, 1, 1) inView:self.view animated:YES];
                }
            }
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    NSArray *sheetActions=[[self.detailItem sheetActions] objectAtIndex:choosedTab];
    if (buttonIndex!=actionSheet.cancelButtonIndex){    
        if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:@"Play"]){
            [self addPlayback:selected position:0];
        }
        else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:@"Queue"]){
            [self addQueue:selected];
        }
        else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:@"Queue after current"]){
            [self addQueue:selected afterCurrentItem:YES];
        }
        else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:@"View Details"]){
            [self showInfo:selected];
        }
        else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:@"Stream to iPhone"]){
            [self addStream:selected];
        }
        else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:@"Search Wikipedia"]){
            [self searchWeb:selected serviceURL:@"http://en.m.wikipedia.org/wiki?search=%@"];
        }
        else if ([[sheetActions objectAtIndex:buttonIndex] isEqualToString:@"Search last.fm charts"]){
            [self searchWeb:selected serviceURL:@"http://m.last.fm/music/%@/+charts?subtype=tracks&rangetype=6month&go=Go"];
        }
    }
}

-(void)searchWeb:(NSIndexPath *)indexPath serviceURL:(NSString *)serviceURL{
//    if (self.webViewController == nil){
//        self.webViewController = [[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
//    }
    self.webViewController = nil;
    self.webViewController = [[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
    NSDictionary *item = nil;
    if ([self.searchDisplayController isActive]){
        item = [self.filteredListContent objectAtIndex:indexPath.row];
    }
    else{
        item = [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    }
    NSString *query = [[item objectForKey:@"label"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *url = [NSString stringWithFormat:serviceURL, query]; 
	NSURL *_url = [NSURL URLWithString:url];    
    
    self.webViewController.urlRequest = [NSURLRequest requestWithURL:_url];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        [self.navigationController pushViewController:self.webViewController animated:YES];
    }
    else{
        CGRect frame=self.webViewController.view.frame;
        frame.size.width=477;
        self.webViewController.view.frame=frame;
        [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:self.webViewController invokeByController:self isStackStartView:FALSE];
    }
 
}

#pragma mark - Gestures

- (void)handleSwipeFromLeft:(id)sender {
    [self showNowPlaying];
}

- (void)handleSwipeFromRight:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - View Configuration

- (void)setDetailItem:(id)newDetailItem{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        // Update the view.
        [self configureView];
    }
}

- (void)configureView{
    if (self.detailItem) {
        NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
        self.navigationItem.title = [parameters objectForKey:@"label"];
        UIColor *shadowColor = [[UIColor alloc] initWithRed:0.0 green:0.0 blue:0.0 alpha:0.5] ;
        topNavigationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, -1, 240, 44)];
        topNavigationLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;;
        topNavigationLabel.backgroundColor = [UIColor clearColor];
        topNavigationLabel.font = [UIFont boldSystemFontOfSize:11];
        topNavigationLabel.minimumFontSize=8.0;
        topNavigationLabel.numberOfLines=2;
        topNavigationLabel.adjustsFontSizeToFitWidth = YES;
        topNavigationLabel.textAlignment = UITextAlignmentLeft;
        topNavigationLabel.textColor = [UIColor whiteColor];
        topNavigationLabel.shadowColor = shadowColor;
        topNavigationLabel.shadowOffset    = CGSizeMake (0.0, -1.0);
        topNavigationLabel.highlightedTextColor = [UIColor blackColor];
        topNavigationLabel.opaque=YES;
        if (![self.detailItem enableSection]){ // CONDIZIONE DEBOLE!!!
            UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 244, 44)];
//            titleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            topNavigationLabel.text=[self.detailItem upperLabel];
            [titleView addSubview:topNavigationLabel];
            self.navigationItem.title = [self.detailItem upperLabel]; 
            self.navigationItem.titleView = titleView;
        }
        else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
            UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 244, 44)];
            titleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            topNavigationLabel.textAlignment = UITextAlignmentRight;
            topNavigationLabel.font = [UIFont boldSystemFontOfSize:14];
            [titleView addSubview:topNavigationLabel];
            titleView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
            [titleView setFrame:CGRectMake(320, 373, -16, 40)];
            [self.view addSubview:titleView];
        }
        UIImage* volumeImg = [UIImage imageNamed:@"button_now_playing_empty.png"];
        CGRect frameimg = CGRectMake(0, 0, volumeImg.size.width, volumeImg.size.height);
        UIButton *nowPlayingButton = [[UIButton alloc] initWithFrame:frameimg];
        [nowPlayingButton setBackgroundImage:volumeImg forState:UIControlStateNormal];
        [nowPlayingButton addTarget:self action:@selector(showNowPlaying) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *nowPlayingButtonItem =[[UIBarButtonItem alloc] initWithCustomView:nowPlayingButton];
        self.navigationItem.rightBarButtonItem=nowPlayingButtonItem;
        
        UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromLeft:)];
        leftSwipe.numberOfTouchesRequired = 1;
        leftSwipe.cancelsTouchesInView=NO;
        leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
        [self.view addGestureRecognizer:leftSwipe];
        
        UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromRight:)];
        rightSwipe.numberOfTouchesRequired = 1;
        rightSwipe.cancelsTouchesInView=NO;
        rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:rightSwipe];
   }
}

#pragma mark - WebView for playback

- (void)webViewDidStartLoad: (UIWebView *)webView{
//    NSLog(@"START");
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
//    NSLog(@"Loading: %@", [request URL]);
    return YES;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
//    NSLog(@"didFinish: %@; stillLoading:%@", [[webView request]URL],
//          (webView.loading?@"NO":@"YES"));
//    if (webView.loading)
//        return;
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
//    NSLog(@"didFail: %@; stillLoading:%@", [[webView request]URL],
//          (webView.loading?@"NO":@"YES"));
}

-(void)showNowPlaying{
    if (!alreadyPush){
        //self.nowPlaying=nil;
        if (self.nowPlaying == nil){
            self.nowPlaying = [[NowPlaying alloc] initWithNibName:@"NowPlaying" bundle:nil];
        }
        self.nowPlaying.detailItem = self.detailItem;
        [self.navigationController pushViewController:self.nowPlaying animated:YES];
        alreadyPush=YES;
    }
}

# pragma mark - Playback Management

-(void)addStream:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [dataList cellForRowAtIndexPath:indexPath];
    UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
    [queuing startAnimating];
    NSDictionary *item = nil;
    if ([self.searchDisplayController isActive]){
        item = [self.filteredListContent objectAtIndex:indexPath.row];
    }
    else{
        item = [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    }
    [jsonRPC callMethod:@"Files.PrepareDownload" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[item objectForKey:@"file"], @"path", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            if( [methodResult count] > 0){
                GlobalData *obj=[GlobalData getInstance];     
                //NSDictionary *itemid = [methodResult objectForKey:@"details"]; 
               // ;
                NSString *serverURL=[NSString stringWithFormat:@"%@:%@", obj.serverIP, obj.serverPort];
                NSString *stringURL = [NSString stringWithFormat:@"%@://%@/%@",(NSArray*)[methodResult objectForKey:@"protocol"], serverURL, [(NSDictionary*)[methodResult objectForKey:@"details"] objectForKey:@"path"]];                
               // NSLog(@"RESULT %@", stringURL);
                NSURLRequest *request = [[NSURLRequest alloc] initWithURL: [NSURL URLWithString: stringURL] cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 10];  
                CGRect frame=webPlayView.frame;
                frame.origin.y=cell.frame.origin.y;
                webPlayView.frame=frame;   
                //NSLog(@"%d", webPlayView.loading);
                [webPlayView loadRequest:request];  
                
//                playerViewController =[[MPMoviePlayerController alloc] initWithContentURL: [NSURL URLWithString: stringURL]];
//                [playerViewController prepareToPlay];
//                [playerViewController.view setFrame: self.view.bounds];  // player's frame must match parent's
//                [self.view addSubview: playerViewController.view];
//                [playerViewController play];
                
                //MPMoviePlayerController *playerViewController;
//                NSURL *movieURL = [NSURL URLWithString:stringURL];
//                playerViewController = [[MPMoviePlayerController alloc] initWithContentURL:movieURL];
////                playerViewController.controlStyle = MPMovieControlStyleFullscreen;
//                playerViewController.shouldAutoplay = YES;
                
//                [[playerViewController view] setFrame: self.view.bounds]; // 2X the native resolution
//                [self.view addSubview: [playerViewController view]];
//                [playerViewController play];
                
//                NSString *medialink = @"http://someWebAddress.mp3";
//                self.player = [[[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:medialink]] autorelease];
//                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerDidFinish:) name:@"MPMoviePlayerPlaybackDidFinishNotification" object:self.player];
//                [self.player play];
                
                [queuing stopAnimating];
            }
        }
        else {
//            NSLog(@"ci deve essere un primo problema %@", methodError);
            [queuing stopAnimating];
        }
    }];
}

-(void)addQueue:(NSIndexPath *)indexPath{
    [self addQueue:indexPath afterCurrentItem:NO];
}

-(void)addQueue:(NSIndexPath *)indexPath afterCurrentItem:(BOOL)afterCurrent{
    UITableViewCell *cell = [dataList cellForRowAtIndexPath:indexPath];
    UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
    [queuing startAnimating];
    NSDictionary *item = nil;
    if ([self.searchDisplayController isActive]){
        item = [self.filteredListContent objectAtIndex:indexPath.row];
    }
    else{
        item = [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    }
    
    NSDictionary *mainFields=[[self.detailItem mainFields] objectAtIndex:choosedTab];
    NSString *key=[mainFields objectForKey:@"row9"];
    if ([[item objectForKey:@"filetype"] isEqualToString:@"directory"]){
        key=@"directory";
    }
    if (afterCurrent){
        [jsonRPC 
         callMethod:@"Player.GetProperties" 
         withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                         [mainFields objectForKey:@"playlistid"], @"playerid",
                         [[NSArray alloc] initWithObjects:@"percentage", @"time", @"totaltime", @"partymode", @"position", nil], @"properties",
                         nil] 
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
             if (error==nil && methodError==nil){
                 if( [NSJSONSerialization isValidJSONObject:methodResult]){
                     if ([methodResult count]){
                         [queuing stopAnimating];            
                         int newPos = [[methodResult objectForKey:@"position"] intValue] + 1;
                         NSString *action2=@"Playlist.Insert";
                         NSDictionary *params2=[NSDictionary dictionaryWithObjectsAndKeys:
                                                [mainFields objectForKey:@"playlistid"], @"playlistid",
                                                [NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:[mainFields objectForKey:@"row9"]], key, nil],@"item",
                                                [NSNumber numberWithInt:newPos],@"position",
                                                nil];
                         [jsonRPC callMethod:action2 withParameters:params2 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                             if (error==nil && methodError==nil){
                                 [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil]; 
                             }
                         
                         }];
                     }
                     else{
                         [self addToPlaylist:mainFields currentItem:item currentKey:key currentActivityIndicator:queuing];
                     }
                 }
                 else{
                     [self addToPlaylist:mainFields currentItem:item currentKey:key currentActivityIndicator:queuing];
                 }
             }
             else {
                [self addToPlaylist:mainFields currentItem:item currentKey:key currentActivityIndicator:queuing];
             }
         }];
    }
    else {
        [self addToPlaylist:mainFields currentItem:item currentKey:key currentActivityIndicator:queuing];
    }
}

-(void)addToPlaylist:(NSDictionary *)mainFields currentItem:(NSDictionary *)item currentKey:(NSString *)key currentActivityIndicator:(UIActivityIndicatorView *)queuing{
    [jsonRPC callMethod:@"Playlist.Add" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[mainFields objectForKey:@"playlistid"], @"playlistid", [NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:[mainFields objectForKey:@"row9"]], key, nil], @"item", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        [queuing stopAnimating];
        if (error==nil && methodError==nil){
            [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil]; 
        }
    }];
    
}

-(void)openFile:(NSDictionary *)params index:(NSIndexPath *) indexPath{
    [jsonRPC callMethod:@"Player.Open" withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            UITableViewCell *cell = [dataList cellForRowAtIndexPath:indexPath];
            UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
            [queuing stopAnimating];
            [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil]; 

            //                [self showNowPlaying];
        }
        else {
            UITableViewCell *cell = [dataList cellForRowAtIndexPath:indexPath];
            UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
            [queuing stopAnimating];
            //                            NSLog(@"terzo errore %@",methodError);
        }
    }];
}
-(void)addPlayback:(NSIndexPath *)indexPath position:(int)pos{
    NSDictionary *mainFields=[[self.detailItem mainFields] objectAtIndex:choosedTab];
    if ([mainFields count]==0){
        return;
    }
    NSDictionary *item = nil;
    if ([self.searchDisplayController isActive]){
        item = [self.filteredListContent objectAtIndex:indexPath.row];
    }
    else{
        item = [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    }

    UITableViewCell *cell = [dataList cellForRowAtIndexPath:indexPath];
    UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
    [queuing startAnimating];
    if ([[mainFields objectForKey:@"playlistid"] intValue]==2){
        [jsonRPC callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
            int currentPlayerID=0;
            if ([methodResult count]){
                currentPlayerID=[[[methodResult objectAtIndex:0] objectForKey:@"playerid"] intValue];
            }
            if (currentPlayerID==1) { // xbmc bug
                [jsonRPC callMethod:@"Player.Stop" withParameters:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:1], @"playerid", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                    if (error==nil && methodError==nil) {
                        [self openFile:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:@"file"], @"file", nil], @"item", nil] index:indexPath];
                    }
                    else {
                        UITableViewCell *cell = [dataList cellForRowAtIndexPath:indexPath];
                        UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
                        [queuing stopAnimating];
                    }
                }];
            }
            else {
                [self openFile:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:@"file"], @"file", nil], @"item", nil] index:indexPath];
            }
        }];
    }
    else{
        [jsonRPC callMethod:@"Playlist.Clear" withParameters:[NSDictionary dictionaryWithObjectsAndKeys: [mainFields objectForKey:@"playlistid"], @"playlistid", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
            if (error==nil && methodError==nil){
                
                [jsonRPC callMethod:@"Playlist.Add" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[mainFields objectForKey:@"playlistid"], @"playlistid", [NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:[mainFields objectForKey:@"row8"]], [mainFields objectForKey:@"row8"], nil], @"item", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                    if (error==nil && methodError==nil){
                        [[NSNotificationCenter defaultCenter] postNotificationName: @"XBMCPlaylistHasChanged" object: nil];
                        [jsonRPC callMethod:@"Player.Open" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: [mainFields objectForKey:@"playlistid"], @"playlistid", [NSNumber numberWithInt: pos], @"position", nil], @"item", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                            if (error==nil && methodError==nil){
                                UITableViewCell *cell = [dataList cellForRowAtIndexPath:indexPath];
                                UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
                                [queuing stopAnimating];
                                [self showNowPlaying];
                            }
                            else {
                                UITableViewCell *cell = [dataList cellForRowAtIndexPath:indexPath];
                                UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
                                [queuing stopAnimating];
                                //                            NSLog(@"terzo errore %@",methodError);
                            }
                        }];
                    }
                    else {
                        UITableViewCell *cell = [dataList cellForRowAtIndexPath:indexPath];
                        UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
                        [queuing stopAnimating];
                        //                    NSLog(@"secondo errore %@",methodError);
                    }
                }];
            }
            else {
                UITableViewCell *cell = [dataList cellForRowAtIndexPath:indexPath];
                UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
                [queuing stopAnimating];
                //            NSLog(@"ERRORE %@", methodError);
            }
        }];
    }
}

-(void)SimpleAction:(NSString *)action params:(NSDictionary *)parameters{
    [jsonRPC callMethod:action withParameters:parameters onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
    }];
}

-(void)showInfo:(NSIndexPath *)indexPath{
    NSDictionary *item = nil;
    if ([self.searchDisplayController isActive]){
        item = [self.filteredListContent objectAtIndex:indexPath.row];
    }
    else{
        item = [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        self.showInfoViewController=nil;
        self.showInfoViewController = [[ShowInfoViewController alloc] initWithNibName:@"ShowInfoViewController" bundle:nil];
        self.showInfoViewController.detailItem = item;
        [self.navigationController pushViewController:self.showInfoViewController animated:YES];
    }
    else{
        ShowInfoViewController *iPadShowViewController = [[ShowInfoViewController alloc] initWithNibName:@"ShowInfoViewController" withItem:item withFrame:CGRectMake(0, 0, 477, self.view.frame.size.height) bundle:nil];                
        [[AppDelegate instance].windowController.stackScrollViewController addViewInSlider:iPadShowViewController invokeByController:self isStackStartView:FALSE];
    }
}

//-(void)playbackAction:(NSString *)action params:(NSArray *)parameters{
//    [jsonRPC callMethod:@"Playlist.GetPlaylists" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
//        if (error==nil && methodError==nil){
////            NSLog(@"RISPOSRA %@", methodResult);
//            if( [methodResult count] > 0){
//                NSNumber *response = [[methodResult objectAtIndex:0] objectForKey:@"playerid"];
////                NSMutableArray *commonParams=[NSMutableArray arrayWithObjects:response, @"playerid", nil];
////                if (parameters!=nil)
////                    [commonParams addObjectsFromArray:parameters];
////                [jsonRPC callMethod:action withParameters:nil onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
////                    if (error==nil && methodError==nil){
////                        //                        NSLog(@"comando %@ eseguito ", action);
////                    }
////                    else {
////                        NSLog(@"ci deve essere un secondo problema %@", methodError);
////                    }
////                }];
//            }
//        }
//        else {
//            NSLog(@"ci deve essere un primo problema %@", methodError);
//        }
//    }];
//}

# pragma mark - JSON DATA Management
-(void) retrieveData:(NSString *)methodToCall parameters:(NSDictionary*)parameters{
    GlobalData *obj=[GlobalData getInstance]; 
    [self alphaView:noFoundView AnimDuration:0.2 Alpha:0.0];    
//    NSLog(@"INIZIO");
//    NSLog(@" METHOD %@ PARAMETERS %@", methodToCall, parameters);
    [jsonRPC 
     callMethod:methodToCall
     withParameters:parameters
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         int total=0;
         if (error==nil && methodError==nil){
//             NSLog(@"FINITO");
//             NSLog(@"DATO RICEVUTO %@", methodResult);
             [self.richResults removeAllObjects];
             [self.sections removeAllObjects];
             [dataList reloadData];
             
             if( [NSJSONSerialization isValidJSONObject:methodResult]){
                 NSString *itemid = @"";
                 NSDictionary *mainFields=[[self.detailItem mainFields] objectAtIndex:choosedTab];
                 //                 NSLog(@"ROW6 %@", [mainFields objectForKey:@"row6"]);
                 if (((NSNull *)[mainFields objectForKey:@"itemid"] != [NSNull null])){
                     itemid = [mainFields objectForKey:@"itemid"]; 
                 }
                 
                 NSArray *videoLibraryMovies = [methodResult objectForKey:itemid];
                 if (((NSNull *)videoLibraryMovies != [NSNull null])){
                     total=[videoLibraryMovies count];
                 }
                 
                 if (total==0){
                     [self alphaView:noFoundView AnimDuration:0.2 Alpha:1.0];
                 }
                 else {
                     [self alphaView:noFoundView AnimDuration:0.2 Alpha:0.0];
                 }
                 NSString *serverURL=[NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
                 for (int i=0; i<total; i++) {
                     NSString *label=[NSString stringWithFormat:@"%@",[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row1"]]];
                     NSString *genre=[NSString stringWithFormat:@"%@",[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row2"]]];
                     if ([genre isEqualToString:@"(null)"]) genre=@"";
                     
                     NSString *year=@"";
                     if([[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row3"]] isKindOfClass:[NSNumber class]]){
                          year=[(NSNumber *)[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row3"]] stringValue];
                     }
                     else{
                         if ([[mainFields objectForKey:@"row3"] isEqualToString:@"blank"])
                             year=@"";
                         else
                             year=[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row3"]];
                     }                     
                     NSString *runtime=@"";
                     if ([[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row4"]] intValue]){
                         runtime=[NSString stringWithFormat:@"%d min",[[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row4"]] intValue]];
                     }
                     else{
                         runtime=[NSString stringWithFormat:@"%@",[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row4"]]];
                     }
                     if ([runtime isEqualToString:@"(null)"]) runtime=@"";

                     
                     NSString *rating=[NSString stringWithFormat:@"%.1f",[(NSNumber *)[[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row5"]] floatValue]];
                     
                     if ([rating isEqualToString:@"0.0"])
                         rating=@"";
                     
                     NSString *thumbnailPath=[[videoLibraryMovies objectAtIndex:i] objectForKey:@"thumbnail"];
                     NSString *fanartURL=@"";
                     NSString *stringURL = [NSString stringWithFormat:@"http://%@%@", serverURL, thumbnailPath];
                     fanartURL = [NSString stringWithFormat:@"http://%@%@", serverURL, [[videoLibraryMovies objectAtIndex:i] objectForKey:@"fanart"]];
                     NSString *filetype=@"";
                     NSString *type=@"";
                     
                     if ([[videoLibraryMovies objectAtIndex:i] objectForKey:@"filetype"]!=nil){
                         filetype=[[videoLibraryMovies objectAtIndex:i] objectForKey:@"filetype"];
                         type=[[videoLibraryMovies objectAtIndex:i] objectForKey:@"type"];;
                         if ([filetype isEqualToString:@"directory"]){
                             stringURL=@"nocover_filemode.png";
                         }
                         else if ([filetype isEqualToString:@"file"]){
                             if ([[mainFields objectForKey:@"playlistid"] intValue]==0){
                                 stringURL=@"icon_song.png";
                                 
                             }
                             else if ([[mainFields objectForKey:@"playlistid"] intValue]==1){
                                 stringURL=@"icon_video.png";
                             }
                             else if ([[mainFields objectForKey:@"playlistid"] intValue]==2){
                                 stringURL=@"icon_picture.png";
                             }
                         }
                     }
                     [self.richResults	addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                   label, @"label",
                                                   genre, @"genre",
                                                   stringURL, @"thumbnail",
                                                   fanartURL, @"fanart",
                                                   runtime, @"runtime",
                                                   [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row6"]], [mainFields objectForKey:@"row6"],
                                                   [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row8"]], [mainFields objectForKey:@"row8"],
                                                   year, @"year",
                                                   rating, @"rating",
                                                   [mainFields objectForKey:@"playlistid"], @"playlistid",
                                                   [mainFields objectForKey:@"row8"], @"family",
                                                   [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row9"]], [mainFields objectForKey:@"row9"],
                                                   [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row10"]], [mainFields objectForKey:@"row10"],
                                                   [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row11"]], [mainFields objectForKey:@"row11"],
                                                   [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row12"]], [mainFields objectForKey:@"row12"],
                                                   [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row13"]], [mainFields objectForKey:@"row13"],
                                                   [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row14"]], [mainFields objectForKey:@"row14"],
                                                   [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row15"]], [mainFields objectForKey:@"row15"],
                                                   [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row16"]], [mainFields objectForKey:@"row16"],
                                                   [[videoLibraryMovies objectAtIndex:i] objectForKey:[mainFields objectForKey:@"row17"]], [mainFields objectForKey:@"row17"],
                                                   nil]];
                 }
//                 NSLog(@"FINITO FINITO");
//                 NSLog(@"RICH RESULTS %@", richResults);
                 [dataList setContentOffset:CGPointMake(0, 44)];
                 [activityIndicatorView stopAnimating];
                 numResults=[self.richResults count];
                 if ([self.detailItem enableSection]){ 
                     NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
                     // CONDIZIONE DEBOLE!!!
                     self.navigationItem.title =[NSString stringWithFormat:@"%@ (%d)", [parameters objectForKey:@"label"], numResults];
                     if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
                         [UIView beginAnimations:nil context:nil];
                         [UIView setAnimationDuration:0.3];
                         topNavigationLabel.alpha = 0;
                         [UIView commitAnimations];
                         topNavigationLabel.text = [NSString stringWithFormat:@"%@ (%d)", [parameters objectForKey:@"label"], numResults];
                         [UIView beginAnimations:nil context:nil];
                         [UIView setAnimationDuration:0.1];
                         topNavigationLabel.alpha = 1;
                         [UIView commitAnimations];
                     }
                     // FINE CONDIZIONE
                 }
                 if ([self.detailItem enableSection] && [self.richResults count]>SECTIONS_START_AT){
                     
                     [self.sections setValue:[[NSMutableArray alloc] init] forKey:UITableViewIndexSearch];
                     BOOL found;
                     NSCharacterSet * set = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ"] invertedSet];
                     NSCharacterSet * numberset = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
                     for (NSDictionary *item in self.richResults){        
                         NSString *c = [[[item objectForKey:@"label"] substringToIndex:1] uppercaseString];
                         
                         if ([c rangeOfCharacterFromSet:numberset].location == NSNotFound){
                             c = @"#";
                         }
                         else if ([c rangeOfCharacterFromSet:set].location != NSNotFound) {
                             c = @"/";
                         }
                         found = NO;
                         for (NSString *str in [self.sections allKeys]){
                             if ([[str uppercaseString] isEqualToString:c]){
                                 found = YES;
                             }
                         }
                         if (!found){     
                             [self.sections setValue:[[NSMutableArray alloc] init] forKey:c];
                         }
                     }
                     for (NSDictionary *item in self.richResults){
                         NSString *c = [[[item objectForKey:@"label"] substringToIndex:1] uppercaseString];
                         if ([c rangeOfCharacterFromSet:numberset].location == NSNotFound){
                             [[self.sections objectForKey:@"#"] addObject:item];
                         }
                         else if ([c rangeOfCharacterFromSet:set].location != NSNotFound) {
                             [[self.sections objectForKey:@"/"] addObject:item];
                         }
                         else{
                             [[self.sections objectForKey:[[[item objectForKey:@"label"] uppercaseString] substringToIndex:1]] addObject:item];
                         }
                     }
                 }
                 else {
                     [self.sections setValue:[[NSMutableArray alloc] init] forKey:@""];
                     for (NSDictionary *item in self.richResults){
                         [[self.sections objectForKey:@""] addObject:item];
                     }
                 }
                 [self choseParams];
                 [dataList reloadData];
                 [self AnimTable:dataList AnimDuration:0.3 Alpha:1.0 XPos:0];
                 [self loadImagesForOnscreenRows];
            }
            else {
                [self.richResults removeAllObjects];
                [self.sections removeAllObjects];
                [self.sections setValue:[[NSMutableArray alloc] init] forKey:@""];
                [dataList reloadData];
                [self alphaView:noFoundView AnimDuration:0.2 Alpha:1.0];
//                NSLog(@"NON E' JSON %@", methodError);
                [activityIndicatorView stopAnimating];
                [self AnimTable:dataList AnimDuration:0.3 Alpha:1.0 XPos:0];
                [self loadImagesForOnscreenRows];
            }
         }
         else {
             [self.richResults removeAllObjects];
             [self.sections removeAllObjects];
             [self.sections setValue:[[NSMutableArray alloc] init] forKey:@""];
             [dataList reloadData];
             [self alphaView:noFoundView AnimDuration:0.2 Alpha:1.0];
//             NSLog(@"ERROR:%@ METHOD:%@", error, methodError);
             [activityIndicatorView stopAnimating];
             [self AnimTable:dataList AnimDuration:0.3 Alpha:1.0 XPos:0];
             [self loadImagesForOnscreenRows];
         }
     }];
}

# pragma mark - Life-Cycle
-(void)viewWillAppear:(BOOL)animated{
    alreadyPush=NO;
    NSIndexPath* selection = [dataList indexPathForSelectedRow];
	if (selection)
		[dataList deselectRowAtIndexPath:selection animated:NO];
    selection = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
    if (selection)
		[self.searchDisplayController.searchResultsTableView deselectRowAtIndexPath:selection animated:NO];
    [self choseParams];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [[SDImageCache sharedImageCache] clearMemory];
}

-(void)buildButtons{
    NSArray *buttons=[self.detailItem mainButtons];
    NSArray *buttonsIB=[NSArray arrayWithObjects:button1, button2, button3, button4, button5, nil];
    int i=0;
    int count=[buttons count];
    if (count>MAX_NORMAL_BUTTONS)
        count = MAX_NORMAL_BUTTONS;
    for (i=0;i<count;i++){
        NSString *imageNameOff=[NSString stringWithFormat:@"%@_off", [buttons objectAtIndex:i]];
        NSString *imageNameOn=[NSString stringWithFormat:@"%@_on", [buttons objectAtIndex:i]];
        [[buttonsIB objectAtIndex:i] setBackgroundImage:[UIImage imageNamed:imageNameOff] forState:UIControlStateNormal];
        [[buttonsIB objectAtIndex:i] setBackgroundImage:[UIImage imageNamed:imageNameOn] forState:UIControlStateSelected];
        [[buttonsIB objectAtIndex:i] setBackgroundImage:[UIImage imageNamed:imageNameOn] forState:UIControlStateHighlighted];
        [[buttonsIB objectAtIndex:i] setEnabled:YES];
    }
    [[buttonsIB objectAtIndex:choosedTab] setSelected:YES];
    if (count==0){
        buttonsView.hidden=YES;
        CGRect frame=dataList.frame;
        frame.size.height=self.view.bounds.size.height;
        dataList.frame=frame;
    }
    if ([[self.detailItem mainMethod] count]>MAX_NORMAL_BUTTONS){
        NSString *imageNameOff=@"st_more_off";
        NSString *imageNameOn=@"st_more_on";
        [[buttonsIB objectAtIndex:MAX_NORMAL_BUTTONS] setBackgroundImage:[UIImage imageNamed:imageNameOff] forState:UIControlStateNormal];
        [[buttonsIB objectAtIndex:MAX_NORMAL_BUTTONS] setBackgroundImage:[UIImage imageNamed:imageNameOn] forState:UIControlStateSelected];
        [[buttonsIB objectAtIndex:MAX_NORMAL_BUTTONS] setBackgroundImage:[UIImage imageNamed:imageNameOn] forState:UIControlStateHighlighted];
        [[buttonsIB objectAtIndex:MAX_NORMAL_BUTTONS] setEnabled:YES];
        selectedMoreTab = [[UIButton alloc] init];
    }
}

- (void)viewDidLoad{
    choosedTab=0;
    [detailView setClipsToBounds:YES];
    CGRect frame=dataList.frame;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        viewWidth=320;
    }
    else {
        viewWidth = 477;
    }
    frame.origin.x = viewWidth;
    dataList.frame=frame;
    [self buildButtons]; // TEMP ?
    [[SDImageCache sharedImageCache] clearMemory];
    numTabs=[[self.detailItem mainMethod] count];
    if ([self.detailItem chooseTab]) 
        choosedTab=[self.detailItem chooseTab];
    if (choosedTab>=numTabs){
        choosedTab=0;
    }
    manager = [SDWebImageManager sharedManager];
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    self.sections = [[NSMutableDictionary alloc] init];
    self.richResults= [[NSMutableArray alloc] init ]; 
    self.filteredListContent = [[NSMutableArray alloc] init ]; 
    [activityIndicatorView startAnimating];
    NSDictionary *methods=[self indexKeyedDictionaryFromArray:[[self.detailItem mainMethod] objectAtIndex:choosedTab]];
    NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[[self.detailItem mainParameters] objectAtIndex:choosedTab]];
    if ([methods objectForKey:@"method"]!=nil){
        [self retrieveData:[methods objectForKey:@"method"] parameters:[parameters objectForKey:@"parameters"]];
    }
    else {
        [activityIndicatorView stopAnimating];
        [self AnimTable:dataList AnimDuration:0.3 Alpha:1.0 XPos:0];
    }
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleTabHasChanged:)
                                                 name: @"tabHasChanged"
                                               object: nil];
    [super viewDidLoad];
}

- (void)viewDidUnload{
    [super viewDidUnload];
    jsonRPC=nil;
    self.richResults=nil;
    self.filteredListContent=nil;
    self.sections=nil;
    dataList=nil;
    jsonCell=nil;
    activityIndicatorView=nil;  
    manager=nil;
    nowPlaying=nil;
    playFileViewController=nil;
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

-(void)dealloc{
    jsonRPC=nil;
    [self.richResults removeAllObjects];
    [self.filteredListContent removeAllObjects];
    self.richResults=nil;
    self.filteredListContent=nil;
    [self.sections removeAllObjects];
    self.sections=nil;
    dataList=nil;
    jsonCell=nil;
    activityIndicatorView=nil;  
    manager=nil;
    nowPlaying=nil;
    playFileViewController=nil;
    self.nowPlaying = nil;
    self.webViewController=nil;
    self.showInfoViewController=nil;
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}
//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
//    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
//}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}
							
@end
