//
//  DetailViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import "DetailViewController.h"
#import "mainMenu.h"
#import "DSJSONRPC.h"
#import "UIImageView+WebCache.h"
#import "GlobalData.h"

@interface DetailViewController ()
- (void)configureView;
@end

@implementation DetailViewController

@synthesize detailItem = _detailItem;
@synthesize activityIndicatorView;
//@synthesize detailDescriptionLabel = _detailDescriptionLabel;

int realcount=0;

#pragma mark - Table Management
-(void)alphaImage:(UIImageView *)image AnimDuration:(float)seconds Alpha:(float)alphavalue{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	image.alpha = alphavalue;
    [UIView commitAnimations];
}

- (void)AnimTable:(UITableView *)tV AnimDuration:(float)seconds Alpha:(float)alphavalue XPos:(int)X{
//	CGContextRef context1 = UIGraphicsGet/CurrentContext();

	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	tV.alpha = alphavalue;
	CGRect frame;
	frame = [tV frame];
	frame.origin.x = X;
	tV.frame = frame;
    [UIView commitAnimations];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    int h=76;
    mainMenu *item = self.detailItem;
    if (item.rowHeight!=0)
        h=item.rowHeight;
    return h;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [richResults count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"jsonDataCellIdentifier";
    jsonDataCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
            [[NSBundle mainBundle] loadNibNamed:@"jsonDataCell" owner:self options:nil];
            cell = jsonCell;
    }
    mainMenu *item = self.detailItem;
//    int imageWidth=53;
    CGRect frame=cell.urlImageView.frame;
//    if (item.thumbWidth!=0){
        frame.size.width=item.thumbWidth;
//    }
//    else {
//        frame.size.width=imageWidth;
//    }
    cell.urlImageView.frame=frame;
//    cell.urlImageView.alpha=0;
    [(UILabel*) [cell viewWithTag:1] setText:[[richResults objectAtIndex:indexPath.row] objectForKey:@"label"]];
    [(UILabel*) [cell viewWithTag:2] setText:[[richResults objectAtIndex:indexPath.row] objectForKey:@"genre"]];
    [(UILabel*) [cell viewWithTag:3] setText:[[richResults objectAtIndex:indexPath.row] objectForKey:@"year"]];
    [(UILabel*) [cell viewWithTag:4] setText:[[richResults objectAtIndex:indexPath.row] objectForKey:@"runtime"]];
    [(UILabel*) [cell viewWithTag:5] setText:[[richResults objectAtIndex:indexPath.row] objectForKey:@"rating"]];
    NSString *stringURL = [[richResults objectAtIndex:indexPath.row] objectForKey:@"thumbnail"];
    NSURL *imageUrl = [NSURL URLWithString: stringURL];
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    UIImage *cachedImage = [manager imageWithURL:imageUrl];
    if (cachedImage){
        cell.urlImageView.image=cachedImage;
        //[cell.activityIndicatorView stopAnimating];
    }
    else{
        cell.urlImageView.image=nil;
        [cell.urlImageView setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:item.defaultThumb] ];
      //  [cell.activityIndicatorView startAnimating];
    }
  //  [self alphaImage:cell.urlImageView AnimDuration:0.1 Alpha:1.0];
    return cell;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIImage *myImage = [UIImage imageNamed:@"tableUp.png"];
	UIImageView *imageView = [[UIImageView alloc] initWithImage:myImage] ;
	imageView.frame = CGRectMake(0,0,480,8);
	return imageView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 4;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIImage *myImage = [UIImage imageNamed:@"tableDown.png"];
	UIImageView *imageView = [[UIImageView alloc] initWithImage:myImage] ;
	imageView.frame = CGRectMake(0,0,480,8);
	return imageView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 4;
}
#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
}

- (void)configureView{
    // Update the user interface for the detail item.

    if (self.detailItem) {
//        CGRect frame = CGRectMake(0, 0, 320, 44);
//        UILabel *label = [[UILabel alloc] initWithFrame:frame] ;
//        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//        label.backgroundColor = [UIColor clearColor];
//        label.font = [UIFont fontWithName:@"Optima-Bold" size:22];
//        label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0];
//        label.textAlignment = UITextAlignmentCenter;
//        label.textColor = [UIColor whiteColor];
//        label.text = [[NSString alloc] initWithFormat:@"%@", [self.detailItem mainLabel]];
//        [label sizeToFit];
//        self.navigationItem.titleView = label; 
        self.navigationItem.title = [self.detailItem mainLabel];
        if ([richResults count]){
            self.navigationItem.title =[[NSString alloc] initWithFormat:@"%@", [self.detailItem mainLabel]];
        }
    }
}
-(void)countDownload:(int)total { // DA VERIFICARE SE NECESSARIO RAFFORZARE QUESTO METODO
//    NSLog(@"COUNT %d %d", realcount, total);
    if (realcount==total-1 || total==0){
        [richResults sortUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"label" ascending:YES]]];
        [activityIndicatorView stopAnimating];
        self.navigationItem.title =[[NSString alloc] initWithFormat:@"%@ (%d)", [self.detailItem mainLabel], total];
        [dataList reloadData];
        [self AnimTable:dataList AnimDuration:0.3 Alpha:1.0 XPos:0];
    }
    realcount++;
}
# pragma JSON DATA Management
//[[NSArray alloc] initWithObjects:@"year", @"runtime", @"file", @"playcount", @"rating", @"plot", @"fanart", @"thumbnail", @"resume", @"trailer", nil], @"properties",
-(void) retrieveData:(NSString*) methodToCall parameters:(NSDictionary*)parameters{
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, obj.serverPass, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC 
     callMethod:methodToCall
     withParameters:parameters
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         int total=0;
         if (error==nil && methodError==nil){
//             NSLog(@"DATO RICEVUTO %@", methodResult);
             if( [NSJSONSerialization isValidJSONObject:methodResult]){
                 NSString *itemid = @"";
                 if (((NSNull *)[[self.detailItem mainFields] objectForKey:@"itemid"] != [NSNull null])){
                     itemid = [[self.detailItem mainFields] objectForKey:@"itemid"]; 
                 }
                 NSArray *videoLibraryMovies = [methodResult objectForKey:itemid];
                 total=[videoLibraryMovies count];
                 //if (!total) [self countDownload:0];
                 NSString *serverURL=[NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];

                 for (int i=0; i<total; i++) {
                     NSString *label=[NSString stringWithFormat:@"%@",[[videoLibraryMovies objectAtIndex:i] objectForKey:[[self.detailItem mainFields] objectForKey:@"row1"]]];
                     NSString *genre=[NSString stringWithFormat:@"%@",[[videoLibraryMovies objectAtIndex:i] objectForKey:[[self.detailItem mainFields] objectForKey:@"row2"]]];
                     NSString *year=[(NSNumber *)[[videoLibraryMovies objectAtIndex:i] objectForKey:[[self.detailItem mainFields] objectForKey:@"row3"]] stringValue];
                     NSString *runtime=@"";
                     if ([[[videoLibraryMovies objectAtIndex:i] objectForKey:[[self.detailItem mainFields] objectForKey:@"row4"]] intValue]){
                         runtime=[NSString stringWithFormat:@"%d min",[[[videoLibraryMovies objectAtIndex:i] objectForKey:[[self.detailItem mainFields] objectForKey:@"row4"]] intValue]];
                     }
                     NSString *rating=[NSString stringWithFormat:@"%.1f",[(NSNumber *)[[videoLibraryMovies objectAtIndex:i] objectForKey:[[self.detailItem mainFields] objectForKey:@"row5"]] floatValue]];
                     
                     NSString *thumbnailPath=[[videoLibraryMovies objectAtIndex:i] objectForKey:@"thumbnail"];
                     
                     NSString *stringURL = [NSString stringWithFormat:@"http://%@%@", serverURL, thumbnailPath];
                     [richResults	addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                               label, @"label",
                                               genre, @"genre",
                                               year, @"year",
                                               runtime, @"runtime",
                                               rating, @"rating",
                                               stringURL, @"thumbnail",
                                               nil]];
//                     NSLog(@"URL: %@", stringURL);
//                     [self countDownload:total];
//                     if (thumbnailPath!=nil && ![thumbnailPath isEqualToString:@""]){
//                         [jsonRPC 
//                          callMethod:@"Files.PrepareDownload" 
//                          withParameters:[NSDictionary dictionaryWithObjectsAndKeys: thumbnailPath, @"path", nil]
//                          onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
//                              if (error==nil && methodError==nil){
//                                  //             NSLog(@"DATO RICEVUTO %@", methodResult); 
////                                  NSString *serverURL=[NSString stringWithFormat:@"%@:%@", obj.serverIP, obj.serverPort];
//                                  NSString *stringURL = [NSString stringWithFormat:@"%@://%@/%@",(NSArray*)[methodResult objectForKey:@"protocol"], serverURL, [(NSDictionary*)[methodResult objectForKey:@"details"] objectForKey:@"path"]];
//                                  
//                                  NSLog(@"%@ %@", thumbnailPath, stringURL);
//                                  [richResults	addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
//                                                           label, @"label",
//                                                           genre, @"genre",
//                                                           year, @"year",
//                                                           runtime, @"runtime",
//                                                           rating, @"rating",
//                                                           stringURL, @"thumbnail",
//                                                           nil]];
//                              }
//                              else {
//                                  NSLog(@"ERROR DOWNLOAD:%@ METHOD:%@ STRING '%@'", error, methodError, thumbnailPath);
//                              }
//                              [self countDownload:total];
//                          }];
//                     }
//                     else {
//                         [richResults addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
//                                                   label, @"label",
//                                                   genre, @"genre",
//                                                   year, @"year",
//                                                   runtime, @"runtime",
//                                                   rating, @"rating",
//                                                   nil, @"thumbnail",
//                                                   nil]];
//                         [self countDownload:total];
//                     }
                 }
                 [activityIndicatorView stopAnimating];
                 self.navigationItem.title =[[NSString alloc] initWithFormat:@"%@ (%d)", [self.detailItem mainLabel], [richResults count]];
                 [dataList reloadData];
                 [self AnimTable:dataList AnimDuration:0.3 Alpha:1.0 XPos:0];
            }
            else {
              NSLog(@"NON E' JSON %@", methodResult);
                [activityIndicatorView stopAnimating];
                [self AnimTable:dataList AnimDuration:0.3 Alpha:1.0 XPos:0];
            }
         }
         else {
             NSLog(@"ERROR:%@ METHOD:%@", error, methodError);
             [activityIndicatorView stopAnimating];
             [self AnimTable:dataList AnimDuration:0.3 Alpha:1.0 XPos:0];
//             [self countDownload:total];
         }
     }];
    
    
}

# pragma Life-Cycle
-(void)viewWillAppear:(BOOL)animated{
    realcount=0;
    [self configureView];
    [activityIndicatorView startAnimating];
    if ([self.detailItem mainMethod]!=nil){
        [self retrieveData:[self.detailItem mainMethod] parameters:[self.detailItem mainParameters]];
    }
    else {
        [activityIndicatorView stopAnimating];
        [self AnimTable:dataList AnimDuration:0.3 Alpha:1.0 XPos:0];
    }
    NSIndexPath* selection = [dataList indexPathForSelectedRow];
	if (selection)
		[dataList deselectRowAtIndexPath:selection animated:NO];
}

-(void)viewDidDisappear:(BOOL)animated{
    [richResults removeAllObjects];
    [self configureView];
    [dataList reloadData];
    [self AnimTable:dataList AnimDuration:0.3 Alpha:1.0 XPos:320];
}
- (void)viewDidLoad{
    [super viewDidLoad];
    richResults= [[NSMutableArray alloc] init ]; 
}

- (void)viewDidUnload{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.detailItem = nil;
    jsonRPC=nil;
    richResults=nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}
							
@end
