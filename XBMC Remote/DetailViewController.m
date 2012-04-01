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
//#import "ShowInfoViewController.h"
#import "DetailViewController.h"
#import "NowPlaying.h"


@interface DetailViewController ()
- (void)configureView;
@end

@implementation DetailViewController

@synthesize detailItem = _detailItem;
@synthesize activityIndicatorView;
//@synthesize showInfoViewController;
@synthesize sections;
@synthesize detailViewController;
@synthesize nowPlaying;
//@synthesize detailDescriptionLabel = _detailDescriptionLabel;
#define SECTIONS_START_AT 0

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


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.sections allKeys] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{    
    return [[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section]] count];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if ([self.detailItem enableSection]  && [richResults count]>SECTIONS_START_AT){
    return [[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    else {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *identifier = @"jsonDataCellIdentifier";
    jsonDataCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"jsonDataCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    mainMenu *Menuitem = self.detailItem;
    CGRect frame=cell.urlImageView.frame;
    frame.size.width=Menuitem.thumbWidth;
    cell.urlImageView.frame=frame;
    NSDictionary *item = [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
//   cell.urlImageView.alpha=0;
    [(UILabel*) [cell viewWithTag:1] setText:[item objectForKey:@"label"]];
    [(UILabel*) [cell viewWithTag:2] setText:[item objectForKey:@"genre"]];
    
    if (![self.detailItem enableSection] || [richResults count]<SECTIONS_START_AT){ // TOGLIERE L'IF E SPOSTARE SU APP DELEGATE. CONDIZIONE DEBOLE
        cell.lineSeparator.hidden=YES;
        UILabel *label=(UILabel*) [cell viewWithTag:3];
        CGRect frame;
        frame=label.frame;
        frame.origin.x=272;
        label.frame=frame;
        UILabel *title=(UILabel*) [cell viewWithTag:1];
        frame=title.frame;
        frame.size.width=252;
        title.frame=frame;
//        frame.size.width=235; // track n.
//        frame.origin.x=78;// track n.

        NSString *duration=[self convertTimeFromSeconds:[item objectForKey:@"runtime"]];
        [(UILabel*) [cell viewWithTag:3] setText:duration];
        
//        [(UILabel*) [cell viewWithTag:7] setText:[NSString stringWithFormat:@"%d.", indexPath.row+1]];// track n.
    }
    else
        [(UILabel*) [cell viewWithTag:3] setText:[item objectForKey:@"year"]];
    [(UILabel*) [cell viewWithTag:4] setText:[item objectForKey:@"runtime"]];
    [(UILabel*) [cell viewWithTag:5] setText:[item objectForKey:@"rating"]];
    NSString *stringURL = [item objectForKey:@"thumbnail"];
    
//    NSURL *imageUrl = [NSURL URLWithString: stringURL];
//    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageUrl]];
   
//    cell.urlImageView.image=[UIImage imageNamed:Menuitem.defaultThumb];    
   [cell.urlImageView setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:Menuitem.defaultThumb] ];
    
//    UIImage *cachedImage = [manager imageWithURL:imageUrl];
//    if (cachedImage){
//        cell.urlImageView.image=cachedImage;
//    }
//    else{
//        cell.urlImageView.image=nil;
//        [cell.urlImageView setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:Menuitem.defaultThumb] ];
//    }
//  [self alphaImage:cell.urlImageView AnimDuration:0.1 Alpha:1.0];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    self.detailViewController=nil;
    mainMenu *MenuItem=self.detailItem;
    NSDictionary *methods=[self indexKeyedDictionaryFromArray:MenuItem.subItem.mainMethod];
    if ([methods objectForKey:@"method"]!=nil){
//    if (MenuItem.subItem.mainMethod!=nil){
        NSDictionary *item = [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
        MenuItem.subItem.mainLabel=@"";
        MenuItem.subItem.upperLabel=[item objectForKey:@"label"];
        NSMutableDictionary *parameters=[self indexKeyedMutableDictionaryFromArray:[MenuItem.subItem mainParameters]];        
        [[parameters objectForKey:@"parameters"] setObject:[item objectForKey:[[self.detailItem mainFields] objectForKey:@"row6"]] forKey:[[self.detailItem mainFields] objectForKey:@"row6"]];
        self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
        self.detailViewController.detailItem = MenuItem.subItem;
        [self.navigationController pushViewController:self.detailViewController animated:YES];
    }
    else {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
        [queuing startAnimating];
        [self addPlayback:indexPath];
    }
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
//    mainMenu *MenuItem=self.detailItem;
//    NSDictionary *methods=[self indexKeyedDictionaryFromArray:MenuItem.subItem.mainMethod];
//    
//    if ([methods objectForKey:@"method"]==nil){
//        UIImage *myImage = [UIImage imageNamed:@"footer.png"];
//        UIImageView *imageView = [[UIImageView alloc] initWithImage:myImage] ;
//
//        imageView.frame = CGRectMake(0,0,320,50);
//        return imageView;
//    }
//    else {
        UIImage *myImage = [UIImage imageNamed:@"tableDown.png"];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:myImage] ;
        imageView.frame = CGRectMake(0,0,320,1);
        return imageView;

//    }
//	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
//    mainMenu *MenuItem=self.detailItem;
//    NSDictionary *methods=[self indexKeyedDictionaryFromArray:MenuItem.subItem.mainMethod];
//    if ([methods objectForKey:@"method"]==nil){
//        return 44;
//    }else {
//        return 1;
//    }
    return 1;
}

#pragma mark - Long Press
-(IBAction)handleLongPress{
    if (lpgr.state == UIGestureRecognizerStateBegan){
        CGPoint p = [lpgr locationInView:dataList];
        
        NSIndexPath *indexPath = [dataList indexPathForRowAtPoint:p];
        if (indexPath == nil)
            NSLog(@"long press on table view but not on a row");
        else{
            NSLog(@"long press on table view at row %d", indexPath.row);
             NSDictionary *item = [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
            
            
            NSString *title=[NSString stringWithFormat:@"%@\n%@", [item objectForKey:@"label"], [item objectForKey:@"genre"]];
            UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:title
                                                                delegate:self
                                                       cancelButtonTitle:@"Annulla"
                                                  destructiveButtonTitle:nil
                                                       otherButtonTitles:@"Queue", @"Play",
                                     nil];
            [action showInView:self.view];
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
	if (buttonIndex==0){
		NSLog(@"Queue");
	}
    else if (buttonIndex==1){
        NSLog(@"Play");
    }
	else{
		NSLog(@"Cancel");
	}
}

#pragma mark - Life Cycle

- (void)setDetailItem:(id)newDetailItem{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        // Update the view.
        [self configureView];
    }
}

- (void)configureView{
    if (self.detailItem) {
        NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[self.detailItem mainParameters]];
        self.navigationItem.title = [parameters objectForKey:@"label"];
        if (![self.detailItem enableSection]){ // CONDIZIONE DEBOLE!!!
            UIColor *shadowColor = [[UIColor alloc] initWithRed:0.0 green:0.0 blue:0.0 alpha:0.5] ;
            UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 244, 44)];
            titleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            UILabel *topNavigationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, -1, 240, 44)];
            topNavigationLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            topNavigationLabel.text=[self.detailItem upperLabel];
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
            [titleView addSubview:topNavigationLabel];
            self.navigationItem.title = [self.detailItem upperLabel]; 
            self.navigationItem.titleView = titleView;
        }
//        UIImage* volumeImg = [UIImage imageNamed:@"button_now_playing.png"];
        UIImage* volumeImg = [UIImage imageNamed:@"button_now_playing_empty.png"];
        CGRect frameimg = CGRectMake(0, 0, volumeImg.size.width, volumeImg.size.height);
        UIButton *nowPlayingButton = [[UIButton alloc] initWithFrame:frameimg];
        [nowPlayingButton setBackgroundImage:volumeImg forState:UIControlStateNormal];
        [nowPlayingButton addTarget:self action:@selector(showNowPlaying) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *nowPlayingButtonItem =[[UIBarButtonItem alloc] initWithCustomView:nowPlayingButton];
        self.navigationItem.rightBarButtonItem=nowPlayingButtonItem;
   }
}

-(void)showNowPlaying{
    self.nowPlaying=nil;
    self.nowPlaying = [[NowPlaying alloc] initWithNibName:@"NowPlaying" bundle:nil];

    
    self.nowPlaying.detailItem = self.detailItem;

    [self.navigationController pushViewController:self.nowPlaying animated:YES];
}

# pragma JSON DATA Management
//[[NSArray alloc] initWithObjects:@"year", @"runtime", @"file", @"playcount", @"rating", @"plot", @"fanart", @"thumbnail", @"resume", @"trailer", nil], @"properties",

-(void)addPlayback:(NSIndexPath *)indexPath{
     NSDictionary *item = [[self.sections valueForKey:[[[self.sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    [jsonRPC callMethod:@"Playlist.Clear" withParameters:[NSDictionary dictionaryWithObjectsAndKeys: [[self.detailItem mainFields] objectForKey:@"playlistid"], @"playlistid", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            [jsonRPC callMethod:@"Playlist.Add" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[[self.detailItem mainFields] objectForKey:@"playlistid"], @"playlistid", [NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:[[self.detailItem mainFields] objectForKey:@"row8"]], [[self.detailItem mainFields] objectForKey:@"row8"], nil], @"item", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                if (error==nil && methodError==nil){
                    [jsonRPC callMethod:@"Player.Open" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: [[self.detailItem mainFields] objectForKey:@"playlistid"], @"playlistid", [NSNumber numberWithInt: indexPath.row], @"position", nil], @"item", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
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
                            NSLog(@"terzo errore %@",methodError);
                        }
                    }];
                }
                else {
                    UITableViewCell *cell = [dataList cellForRowAtIndexPath:indexPath];
                    UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
                    [queuing stopAnimating];
                    NSLog(@"secondo errore %@",methodError);
                }
            }];
        }
        else {
            UITableViewCell *cell = [dataList cellForRowAtIndexPath:indexPath];
            UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
            [queuing stopAnimating];
            NSLog(@"ERRORE %@", methodError);
        }
    }];
}

-(void)SimpleAction:(NSString *)action params:(NSDictionary *)parameters{
    [jsonRPC callMethod:action withParameters:parameters onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
    }];
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

-(void) retrieveData:(NSString *)methodToCall parameters:(NSDictionary*)parameters{

    GlobalData *obj=[GlobalData getInstance]; 
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
                                               [[videoLibraryMovies objectAtIndex:i] objectForKey:[[self.detailItem mainFields] objectForKey:@"row6"]], [[self.detailItem mainFields] objectForKey:@"row6"],
                                               [[videoLibraryMovies objectAtIndex:i] objectForKey:[[self.detailItem mainFields] objectForKey:@"row8"]], [[self.detailItem mainFields] objectForKey:@"row8"],
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
                 if ([self.detailItem enableSection] && [richResults count]>SECTIONS_START_AT){// 
                     NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[self.detailItem mainParameters]];

                     self.navigationItem.title =[NSString stringWithFormat:@"%@ (%d)", [parameters objectForKey:@"label"], [richResults count]];
                     BOOL found;
                     NSCharacterSet * set = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ"] invertedSet];
                     NSCharacterSet * numberset = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
                     for (NSDictionary *item in richResults){        
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
                     
                     for (NSDictionary *item in richResults){
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
                     for (NSDictionary *item in richResults){
                          [[self.sections objectForKey:@""] addObject:item];
                     }
                 }
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
    NSIndexPath* selection = [dataList indexPathForSelectedRow];
	if (selection)
		[dataList deselectRowAtIndexPath:selection animated:NO];
}

//-(void)viewDidDisappear:(BOOL)animated{
//    [richResults removeAllObjects];
//    [self configureView];
//    [dataList reloadData];
//    [self AnimTable:dataList AnimDuration:0.3 Alpha:1.0 XPos:320];
//}
- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad{
    manager = [SDWebImageManager sharedManager];
    GlobalData *obj=[GlobalData getInstance];     
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, obj.serverPass, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    self.sections = [[NSMutableDictionary alloc] init];
    richResults= [[NSMutableArray alloc] init ]; 
    [self configureView];
    [activityIndicatorView startAnimating];
    NSDictionary *methods=[self indexKeyedDictionaryFromArray:[self.detailItem mainMethod]];
    NSDictionary *parameters=[self indexKeyedDictionaryFromArray:[self.detailItem mainParameters]];
    if ([methods objectForKey:@"method"]!=nil){
        [self retrieveData:[methods objectForKey:@"method"] parameters:[parameters objectForKey:@"parameters"]];
    }
    else {
        [activityIndicatorView stopAnimating];
        [self AnimTable:dataList AnimDuration:0.3 Alpha:1.0 XPos:0];
    }
    [super viewDidLoad];
}

- (void)viewDidUnload{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.detailItem = nil;
    jsonRPC=nil;
    richResults=nil;
}

-(void)dealloc{
    self.detailItem = nil;
    jsonRPC=nil;
    [richResults removeAllObjects];
    richResults=nil;
    [self.sections removeAllObjects];
    self.sections=nil;
    dataList=nil;
    jsonCell=nil;
    activityIndicatorView=nil;  
    manager=nil;
    nowPlaying=nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}
							
@end
