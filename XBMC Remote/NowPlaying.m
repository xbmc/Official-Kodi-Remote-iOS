//
//  NowPlaying.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 24/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "NowPlaying.h"
#import "mainMenu.h"
#import "UIImageView+WebCache.h"
#import <QuartzCore/QuartzCore.h>
#import "GlobalData.h"
#import "VolumeSliderView.h"
#import "SDImageCache.h"
#import "RemoteController.h"
#import "AppDelegate.h"

@interface NowPlaying ()

@end

@implementation NowPlaying

@synthesize detailItem = _detailItem;
@synthesize remoteController;
float startx=14;
float barwidth=280;
float cellBarWidth=45;
#define SHOW_ONLY_VISIBLE_THUMBNAIL_START_AT 50

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
        CGRect frame = CGRectMake(0, 0, 320, 44);
        viewTitle = [[UILabel alloc] initWithFrame:frame] ;
        viewTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        viewTitle.backgroundColor = [UIColor clearColor];
        viewTitle.font = [UIFont boldSystemFontOfSize:14];
        viewTitle.shadowColor = [UIColor colorWithWhite:0.0 alpha:0];
        viewTitle.textAlignment = UITextAlignmentCenter;
        viewTitle.textColor = [UIColor whiteColor];
        viewTitle.text = @"Now playing";
        [viewTitle sizeToFit];
        self.navigationItem.titleView = viewTitle;
        self.navigationItem.title = @"Now playing"; // DA SISTEMARE COME PARAMETRO
        UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromRight:)];
        rightSwipe.numberOfTouchesRequired = 1;
        rightSwipe.cancelsTouchesInView=NO;
        rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:rightSwipe];
        
        UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showRemoteController)];
        leftSwipe.numberOfTouchesRequired = 1;
        leftSwipe.cancelsTouchesInView=NO;
        leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
        [self.view addGestureRecognizer:leftSwipe];
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}



# pragma mark - toolbar management

-(void)toggleViewToolBar:(UIView*)view AnimDuration:(float)seconds Alpha:(float)alphavalue YPos:(int)Y forceHide:(BOOL)hide {
	[UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:seconds];
    int actualPosY=view.frame.origin.y;
    if (actualPosY==Y || hide){
        Y=-view.frame.size.height;
    }
    view.alpha = alphavalue;
	CGRect frame;
	frame = [view frame];
	frame.origin.y = Y;
    view.frame = frame;
    [UIView commitAnimations];
}

- (void)toggleVolume{
    [self toggleViewToolBar:volumeSliderView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:FALSE];
}

-(IBAction)changePlaylist:(id)sender{
//    NSLog(@"%d", [sender tag]);
    if ([sender tag]==1 && seg_music.selected) return;
    if ([sender tag]==2 && seg_video.selected) return;
    [self editTable:nil forceClose:YES];
    if ([playlistData count] && (playlistTableView.dragging == YES || playlistTableView.decelerating == YES)){
        NSArray *visiblePaths = [playlistTableView indexPathsForVisibleRows];
        [playlistTableView  scrollToRowAtIndexPath:[visiblePaths objectAtIndex:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    if (seg_music.selected){
        lastSelected=-1;
        seg_music.selected=NO;
        seg_video.selected=YES;
        selectedPlayerID=1;
        musicPartyMode=0;
        [self createPlaylist:NO];
    }
    else {
        lastSelected=-1;
        seg_music.selected=YES;
        seg_video.selected=NO;
        selectedPlayerID=0;
        musicPartyMode=0;
        [self createPlaylist:NO];
    }
}

#pragma mark - utility

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

-(void)animCursor:(float)x{
    float time=1.0f;
    if (x==startx){
        time=0.1f;
    }
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:time];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear ];
    CGRect frame;
    frame = [timeCursor frame];
    frame.origin.x = x;
    timeCursor.frame = frame;
    [UIView commitAnimations];
}

-(void)resizeBar:(float)width{
    float time=1.0f;
    if (width==0){
        time=0.1f;
    }
    if (width>barwidth)
        width=barwidth;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:time];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    CGRect frame;
    frame = [timeBar frame];
    frame.size.width = width;
    timeBar.frame = frame;
    [UIView commitAnimations];
}

-(void)resizeCellBar:(float)width image:(UIImageView *)cellBarImage{
    float time=1.0f;
    if (width==0){
        time=0.1f;
    }
    if (width>cellBarWidth)
        width=cellBarWidth;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:time];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    CGRect frame;
    frame = [cellBarImage frame];
    frame.size.width = width;
    cellBarImage.frame = frame;
    [UIView commitAnimations];
}

-(IBAction)togglePartyMode:(id)sender{
//    if (PartyModeButton.state == UIControlStateSelected){
//        
//    }
    [PartyModeButton setSelected:YES];
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverHTTP=[NSString stringWithFormat:@"http://%@%@@%@:%@/xbmcCmds/xbmcHttp?command=ExecBuiltIn&parameter=PlayerControl(Partymode('music'))", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    NSURL *url = [NSURL  URLWithString:serverHTTP];
    NSString *requestANS = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];  
    requestANS=nil;
    [self createPlaylist:NO];
   // NSLog(@"SERVER RESPONSE : %@",requestANS);
}

-(void)fadeView:(UIView *)view hidden:(BOOL)value{
    if (value == view.hidden) {
        return;
    }
//    [UIView beginAnimations:nil context:nil];
//    [UIView setAnimationDuration:1];
//    [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:view cache:NO];
//    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    
    view.hidden=value;
//    [UIView commitAnimations];
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

- (void)AnimButton:(UIButton *)button AnimDuration:(float)seconds hidden:(BOOL)hiddenValue XPos:(int)X{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	//button.hidden = hiddenValue;
	CGRect frame;
	frame = [button frame];
	frame.origin.x = X;
	button.frame = frame;
    [UIView commitAnimations];
}

#pragma  mark - JSON management

int lastSelected=-1;
int currentPlayerID=-1;
float storePercentage;
int storedItemID;
int currentItemID;

-(void)setCoverSize:(NSString *)type{
    NSString *jewelImg=@"";
    if ([type isEqualToString:@"song"]){
        jewelImg=@"jewel_cd.9.png";
        CGRect frame=thumbnailView.frame;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            frame.origin.x=50;
            frame.origin.y=43;
            frame.size.width=237;
            frame.size.height=236;
        }
        else {
            jewelImg=@"jewel_cd.9@2x.png";
            if (portraitMode){
                frame.origin.x=76;
                frame.origin.y=60;
                frame.size.width=334;
                frame.size.height=334;
            }
            else {
                frame.origin.x=152;
                frame.origin.y=80;
                frame.size.width=435;
                frame.size.height=435;
            }
        }
        thumbnailView.frame=frame;
        songDetailsView.frame=frame;
    }
    else if ([type isEqualToString:@"movie"]){
        jewelImg=@"jewel_dvd.9.png";
        CGRect frame=thumbnailView.frame;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            frame.origin.x=82;
            frame.origin.y=39;
            frame.size.width=172;
            frame.size.height=248;
            
        }
        else{
            jewelImg=@"jewel_dvd.9@2x.png";
            if (portraitMode){
                frame.origin.x=124;
                frame.origin.y=56;
                frame.size.width=240;
                frame.size.height=346;
            }
            else {
                frame.origin.x=218;
                frame.origin.y=74;
                frame.size.width=306;
                frame.size.height=450;
            }
        }
        thumbnailView.frame=frame;
        songDetailsView.frame=frame;
    }
    else if ([type isEqualToString:@"episode"]){
        jewelImg=@"jewel_tv.9.png";
        CGRect frame=thumbnailView.frame;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            frame.origin.x=20;
            frame.origin.y=78;
            frame.size.width=280;
            frame.size.height=158;
        }
        else{
            jewelImg=@"jewel_tv.9@2x.png";
            if (portraitMode){
                frame.origin.x=28;
                frame.origin.y=106;
                frame.size.width=404;
                frame.size.height=228;
            }
            else {
                frame.origin.x=38;
                frame.origin.y=102;
                frame.size.width=630;
                frame.size.height=360;
            }
        }
        thumbnailView.frame=frame;
        songDetailsView.frame=frame;

    }
    else{
        jewelImg=@"jewel_cd.9.png";
        CGRect frame=thumbnailView.frame;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            frame.origin.x=50;
            frame.origin.y=43;
            frame.size.width=237;
            frame.size.height=236;
        }
        else {
            jewelImg=@"jewel_cd.9@2x.png";
            if (portraitMode){
                frame.origin.x=76;
                frame.origin.y=60;
                frame.size.width=334;
                frame.size.height=334;
            }
            else {
                frame.origin.x=152;
                frame.origin.y=80;
                frame.size.width=435;
                frame.size.height=435;
            }
        }
        thumbnailView.frame=frame;
        songDetailsView.frame=frame;
        
    }
    jewelView.image=[UIImage imageNamed:jewelImg];
}

-(void)nothingIsPlaying{
    currentTime.text=@"";
    [timeCursor.layer removeAllAnimations];
    [timeBar.layer removeAllAnimations];
    [self animCursor:startx];
    [self resizeBar:0];
    thumbnailView.image=nil;
    duration.text=@"";
    albumName.text=@"Nothing is playing";
    songName.text=@"";
    artistName.text=@"";
    lastSelected=-1;
    storeSelection=nil;
    [PartyModeButton setSelected:NO];
    NSIndexPath *selection=[playlistTableView indexPathForSelectedRow];
    if (selection){
        [playlistTableView deselectRowAtIndexPath:selection animated:YES];
        UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:selection];
        UIImageView *coverView=(UIImageView*) [cell viewWithTag:4];
        coverView.alpha=1.0;
        UIView *timePlaying=(UIView*) [cell viewWithTag:5];
        storeSelection=nil;
        if (timePlaying.hidden==NO)
            [self fadeView:timePlaying hidden:YES];
    }
    [self showPlaylistTable];
}

-(void)playbackInfo{
    if (![AppDelegate instance].serverOnLine) {
        playerID = -1;
        selectedPlayerID = -1;
        [self AnimTable:playlistTableView AnimDuration:0.3 Alpha:1.0 XPos:slideFrom];
        [playlistData removeAllObjects];
        [self nothingIsPlaying];
        return;
    }
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:nil] withTimeout:2.0 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            if( [methodResult count] > 0){
                NSNumber *response;
                if (((NSNull *)[[methodResult objectAtIndex:0] objectForKey:@"playerid"] != [NSNull null])){
                    response = [[methodResult objectAtIndex:0] objectForKey:@"playerid"];
                }
                currentPlayerID=[response intValue];
                if (playerID!=[response intValue] || (selectedPlayerID>-1 && playerID!=selectedPlayerID)){  // DA SISTEMARE SE AGGIUNGONO ITEM DALL'ESTERNO: FUTURA SEGNALAZIONE CON SOCKET!                    
                    if (selectedPlayerID>-1  && playerID!=selectedPlayerID){
                        playerID=selectedPlayerID;
                    }
                    else if (selectedPlayerID==-1) {
                        playerID = [response intValue];
                        [self createPlaylist:NO];
                    }
                }
                [jsonRPC 
                 callMethod:@"Player.GetItem" 
                 withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                                 response, @"playerid",
                                 [[NSArray alloc] initWithObjects:@"album", @"artist",@"title", @"thumbnail", @"track", nil], @"properties",
                                 nil] 
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                     if (error==nil && methodError==nil){
//                         NSLog(@"Risposta %@", methodResult);
                         if( [NSJSONSerialization isValidJSONObject:methodResult]){
                             NSDictionary *nowPlayingInfo = [methodResult objectForKey:@"item"];
                             if ([nowPlayingInfo  objectForKey:@"id"]==nil)
                                 currentItemID=-2;
                             else
                                 currentItemID=[[nowPlayingInfo  objectForKey:@"id"] intValue];
//                             NSLog(@"ITEMS %@ %d", [nowPlayingInfo  objectForKey:@"id"], storedItemID);

                             if (([nowPlayingInfo count] && currentItemID!=storedItemID) || [nowPlayingInfo  objectForKey:@"id"]==nil){ //
//                                 NSLog(@"aggiorno");
                                 NSString *album=[[nowPlayingInfo  objectForKey:@"album"] length]!=0 ?[NSString stringWithFormat:@"%@",[nowPlayingInfo  objectForKey:@"album"]] : @"" ;
                                 NSString *title=[[nowPlayingInfo  objectForKey:@"title"] length]!=0 ? [NSString stringWithFormat:@"%@",[nowPlayingInfo  objectForKey:@"title"]] : @"";
                                 NSString *artist=[[nowPlayingInfo objectForKey:@"artist"] length]!=0 ? [NSString stringWithFormat:@"%@",[nowPlayingInfo objectForKey:@"artist"]] : @"";
//                                 NSNumber *timeduration=[nowPlayingInfo objectForKey:@"duration"];
                                 if ([title length]==0)
                                     title=[[nowPlayingInfo  objectForKey:@"label"] length]!=0? [nowPlayingInfo  objectForKey:@"label"] : @"";
                                 albumName.text=album;
                                 songName.text=title;
                                 artistName.text=artist;
                                 NSString *type=[[nowPlayingInfo objectForKey:@"type"] length]!=0? [nowPlayingInfo objectForKey:@"type"] : @"unknown";
                                 currentType=type;
                                 [self setCoverSize:currentType];
                             }
                             GlobalData *obj=[GlobalData getInstance]; 
                             NSString *serverURL=[NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];

                             NSString *thumbnailPath=[nowPlayingInfo objectForKey:@"thumbnail"];
                             
                             NSString *stringURL = [NSString stringWithFormat:@"http://%@%@", serverURL, thumbnailPath];
                             
                             NSURL *imageUrl = [NSURL URLWithString: stringURL];
//                             NSLog(@"%@", thumbnailPath);
//                             thumbnailView.image=[UIImage im];
//                             SDWebImageManager *manager = [SDWebImageManager sharedManager];
                             UIImage *cachedImage = [manager imageWithURL:imageUrl];
                             if (cachedImage){
                                 thumbnailView.image=cachedImage;
                             }
                             else{
                                 [thumbnailView setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:@"coverbox_back.png"] ];
                             }
                             //                                      NSLog(@"Visualizzo %@", stringURL);
                         }
                         else {
                             storedItemID=-1;
                             thumbnailView.image=[UIImage imageNamed:@"coverbox_back.png"];
                             //                                      NSLog(@"SONO IO ERROR:%@ METHOD:%@", error, methodError);
                         }
                             
                         
                     }
                     else {
                         storedItemID=-1;
                         NSLog(@"ci deve essere un secondo problema %@ %@", error, methodError);
                     }
                 }];
                [jsonRPC 
                 callMethod:@"Player.GetProperties" 
                 withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                                 response, @"playerid",
                                 [[NSArray alloc] initWithObjects:@"percentage", @"time", @"totaltime", @"partymode", @"position", nil], @"properties",
                                 nil] 
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                     if (error==nil && methodError==nil){
                         if( [NSJSONSerialization isValidJSONObject:methodResult]){
//                             NSLog(@"risposta %@", methodResult);
                             if ([methodResult count]){
                                 float newx=barwidth * [(NSNumber*) [methodResult objectForKey:@"percentage"] floatValue] / 100;
                                 if (newx<1)
                                     newx=1;
                                 musicPartyMode=[[methodResult objectForKey:@"partymode"] intValue];
                                 if (musicPartyMode==YES) {
                                     [PartyModeButton setSelected:YES];
                                 }
                                 else{
                                     [PartyModeButton setSelected:NO];
                                 }

                                 [self animCursor:startx+newx];
                                 [self resizeBar:newx];
                                 NSDictionary *timeGlobal=[methodResult objectForKey:@"totaltime"];
                                 int hoursGlobal=[[timeGlobal objectForKey:@"hours"] intValue];
                                 int minutesGlobal=[[timeGlobal objectForKey:@"minutes"] intValue];
                                 int secondsGlobal=[[timeGlobal objectForKey:@"seconds"] intValue];
                                 NSString *globalTime=[NSString stringWithFormat:@"%@%02i:%02i", (hoursGlobal == 0) ? @"":[NSString stringWithFormat:@"%02i:", hoursGlobal], minutesGlobal, secondsGlobal];
                                 
                                 duration.text=globalTime;
                                 
                                 NSDictionary *time=[methodResult objectForKey:@"time"];
                                 int hours=[[time objectForKey:@"hours"] intValue];
                                 int minutes=[[time objectForKey:@"minutes"] intValue];
                                 int seconds=[[time objectForKey:@"seconds"] intValue];
                                 NSString *actualTime=[NSString stringWithFormat:@"%@%02i:%02i", (hoursGlobal == 0) ? @"":[NSString stringWithFormat:@"%02i:", hours], minutes, seconds];
                                 currentTime.text=actualTime;
                                 NSIndexPath* selection = [playlistTableView indexPathForSelectedRow];
                                 if (storeSelection)
                                     selection=storeSelection;
                                 if (selection){
                                     UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:selection];
                                     UILabel *playlistActualTime=(UILabel*) [cell viewWithTag:6];
                                     playlistActualTime.text=actualTime;
                                     UIImageView *playlistActualBar=(UIImageView*) [cell viewWithTag:7];
                                     float newx=cellBarWidth * [(NSNumber*) [methodResult objectForKey:@"percentage"] floatValue] / 100;
                                     if (newx<1)
                                         newx=1;
                                     [self resizeCellBar:newx image:playlistActualBar];
                                     UIView *timePlaying=(UIView*) [cell viewWithTag:5];
                                     if (timePlaying.hidden==YES)
                                         [self fadeView:timePlaying hidden:NO];
                                 }
                                 int playlistPosition = [[methodResult objectForKey:@"position"] intValue];
                                 if (playlistPosition>-1)
                                     playlistPosition+=1;
                                 if (musicPartyMode && [(NSNumber*) [methodResult objectForKey:@"percentage"] floatValue]<storePercentage){ // BLEAH!!!
                                     [self checkPartyMode];
                                 }
//                                 if (selection){
//                                     NSLog(@"%d %d %@", currentItemID, [[[playlistData objectAtIndex:selection.row] objectForKey:@"idItem"] intValue], selection);
//                                     
////                                     if (currentItemID!=[[[playlistData objectAtIndex:selection.row] objectForKey:@"idItem"] intValue] && [[[playlistData objectAtIndex:selection.row] objectForKey:@"idItem"] intValue]>0){
//////                                         lastSelected=-1;
//////                                         // storeSelection=0;
//////                                         currentItemID=[[[playlistData objectAtIndex:selection.row] objectForKey:@"idItem"] intValue];
////                                         [self createPlaylist:NO];
////                                     }
//                                 }
                                 
//                                 NSLog(@"CURRENT ITEMID %d PLAYLIST ID %@", currentItemID, [[playlistData objectAtIndex:selection.row] objectForKey:@"idItem"]);
                                
                                 
                                 storePercentage=[(NSNumber*) [methodResult objectForKey:@"percentage"] floatValue];
                                
                                 if (playlistPosition!=lastSelected && playlistPosition>0){
//                 NSLog(@"%d %d %d", [playlistData count], [playlistPosition intValue], lastSelected);
                                     if (([playlistData count]>=playlistPosition) && currentPlayerID==playerID){
                                         if (playlistPosition>0){
                                             if (lastSelected!=playlistPosition){
//                                                 NSLog(@"me ne accorgo %@", storeSelection);
                                                 NSIndexPath* selection = [playlistTableView indexPathForSelectedRow];
                                                 if (storeSelection)
                                                     selection=storeSelection;
                                                 if (selection){
//                                                     NSLog(@"spengo %@", selection);
                                                     UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:selection];
                                                     UIView *timePlaying=(UIView*) [cell viewWithTag:5];
                                                     if (timePlaying.hidden==NO)
                                                         [self fadeView:timePlaying hidden:YES];
                                                     //                                 timePlaying.hidden=YES;
                                                     UIImageView *coverView=(UIImageView*) [cell viewWithTag:4];
                                                     coverView.alpha=1.0;
                                                 }
                                                 NSIndexPath *newSelection=[NSIndexPath indexPathForRow:playlistPosition - 1 inSection:0];
                                                 UITableViewScrollPosition position=UITableViewScrollPositionMiddle;
                                                 if (musicPartyMode)
                                                     position=UITableViewScrollPositionNone;
                                                 [playlistTableView selectRowAtIndexPath:newSelection animated:YES scrollPosition:position];
                                                 UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:newSelection];
                                                 UIView *timePlaying=(UIView*) [cell viewWithTag:5];
                                                 if (timePlaying.hidden==YES)
                                                     [self fadeView:timePlaying hidden:NO];
                                                 storeSelection=newSelection;
                                                 //                             timePlaying.hidden=NO;
                                                 lastSelected=playlistPosition;
                                             }
                                         }
                                         else {
                                             NSIndexPath* selection = [playlistTableView indexPathForSelectedRow];
                                             if (selection){
                                                 [playlistTableView deselectRowAtIndexPath:selection animated:YES];
                                                 UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:selection];
                                                 UIView *timePlaying=(UIView*) [cell viewWithTag:5];
                                                 if (timePlaying.hidden==NO)
                                                     [self fadeView:timePlaying hidden:YES];
                                                 //                             timePlaying.hidden=YES;
                                                 UIImageView *coverView=(UIImageView*) [cell viewWithTag:4];
                                                 coverView.alpha=1.0;
                                             }
                                         }
                                     }
                                 }
//                                 NSLog(@"time %@", actualTime);
                             }
                             else{
                                 [PartyModeButton setSelected:NO];
//                                 PlayerPaused=YES; 
                             }
                         }
                         else{
                             [PartyModeButton setSelected:NO];
                             
//                            PlayerPaused=YES; 
                         }
                     }
                     else {
                         [PartyModeButton setSelected:NO];
//                         PlayerPaused=YES;
//                         NSLog(@"ci deve essere un secondo problema %@ %@",error, methodError);
                     }
                 }];
            }
            else{
                [self nothingIsPlaying];
                if (playerID==-1 && selectedPlayerID==-1){
                    playerID=-2;
                    [self createPlaylist:YES];
                }
            }
        }
        else {
//            NSLog(@"ci deve essere un primo problema %@", methodError);
            [self nothingIsPlaying];
        }
    }];
    if (currentItemID!=storedItemID){
        [jsonRPC 
         callMethod:@"XBMC.GetInfoLabels" 
         withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                         [[NSArray alloc] initWithObjects:@"MusicPlayer.Codec",@"MusicPlayer.SampleRate",@"MusicPlayer.BitRate", @"MusicPlayer.PlaylistPosition",@"VideoPlayer.VideoResolution",@"VideoPlayer.VideoAspect",@"Player.TimeRemaining", @"Player.Duration", @"VideoPlayer.PlaylistPosition", nil], @"labels",
                         nil] 
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
             if (error==nil && methodError==nil  && methodResult!=NULL){
                 //             NSLog(@"RISULTATO %@", methodResult);
                 NSNumber *playlistPosition = 0;
                 NSString *codec=@"";
                 NSString *bitrate=@"";
                 NSString *samplerate=@"";
                 if (playerID==0){
                     labelSongCodec.text=@"codec";
                     labelSongBitRate.text=@"bit rate";
                     labelSongSampleRate.text=@"sample rate";
                     playlistPosition = [methodResult objectForKey:@"MusicPlayer.PlaylistPosition"];
                     codec=[[methodResult objectForKey:@"MusicPlayer.Codec"] isEqualToString:@""] ? @"-" : [NSString stringWithFormat:@"%@", [methodResult objectForKey:@"MusicPlayer.Codec"]] ;
                     songCodec.text=codec;
                     
                     bitrate=[[methodResult objectForKey:@"MusicPlayer.BitRate"] isEqualToString:@""] ? @"-" : [NSString stringWithFormat:@"%@ kbit/s", [methodResult objectForKey:@"MusicPlayer.BitRate"]] ;
                     songBitRate.text=bitrate;
                     
                     samplerate=[[methodResult objectForKey:@"MusicPlayer.SampleRate"] isEqualToString:@""] ? @"-" : [NSString stringWithFormat:@"%@ MHz", [methodResult objectForKey:@"MusicPlayer.SampleRate"]];
                     songSampleRate.text=samplerate;
                 }
                 else {
                     labelSongCodec.text=@"resolution";
                     labelSongBitRate.text=@"aspect ratio";
                     labelSongSampleRate.text=@"";
                     
                     playlistPosition = [methodResult objectForKey:@"VideoPlayer.PlaylistPosition"];
                     codec=[[methodResult objectForKey:@"VideoPlayer.VideoResolution"] isEqualToString:@""] ? @"-" : [NSString stringWithFormat:@"%@", [methodResult objectForKey:@"VideoPlayer.VideoResolution"]] ;
                     songCodec.text=codec;
                     
                     bitrate=[[methodResult objectForKey:@"VideoPlayer.VideoAspect"] isEqualToString:@""] ? @"-" : [NSString stringWithFormat:@"%@", [methodResult objectForKey:@"VideoPlayer.VideoAspect"]] ;
                     songBitRate.text=bitrate;
                     
                     //                 samplerate=[[methodResult objectForKey:@"MusicPlayer.SampleRate"] isEqualToString:@""] ? @"-" : [NSString stringWithFormat:@"%@ MHz", [methodResult objectForKey:@"MusicPlayer.SampleRate"]];
                     //                 songSampleRate.text=samplerate;
                     songSampleRate.text=@"";
                 }
                 
                 
             }
             else {
                 //             NSLog(@"ERROR %@", methodError);
             }
         }];  
    }
    storedItemID=currentItemID;
}

-(void)playbackAction:(NSString *)action params:(NSArray *)parameters checkPartyMode:(BOOL)checkPartyMode{
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            if( [methodResult count] > 0){
                NSNumber *response = [[methodResult objectAtIndex:0] objectForKey:@"playerid"];
                NSMutableArray *commonParams=[NSMutableArray arrayWithObjects:response, @"playerid", nil];
                if (parameters!=nil)
                    [commonParams addObjectsFromArray:parameters];
                [jsonRPC callMethod:action withParameters:[self indexKeyedDictionaryFromArray:commonParams] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                    if (error==nil && methodError==nil){
                        if (musicPartyMode && checkPartyMode){
                            [self checkPartyMode];
                        }
//                        NSLog(@"comando %@ eseguito ", action);
                    }
                    else {
//                        NSLog(@"ci deve essere un secondo problema %@", methodError);
                    }
                }];
            }
        }
        else {
//            NSLog(@"ci deve essere un primo problema %@", methodError);
        }
    }];
}
-(void)alphaView:(UIView *)view AnimDuration:(float)seconds Alpha:(float)alphavalue{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	view.alpha = alphavalue;
    [UIView commitAnimations];
}

-(void)alphaButton:(UIButton *)button AnimDuration:(float)seconds show:(BOOL)show{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	button.hidden = show;
    [UIView commitAnimations];
}

-(void)createPlaylist:(BOOL)forcePlaylistID{ 
    if (![AppDelegate instance].serverOnLine) {
        playerID = -1;
        selectedPlayerID = -1;
        [self AnimTable:playlistTableView AnimDuration:0.3 Alpha:1.0 XPos:slideFrom];
        [playlistData removeAllObjects];
        [self nothingIsPlaying];
        return;
    }
    if (!musicPartyMode)
        [self AnimTable:playlistTableView AnimDuration:0.3 Alpha:1.0 XPos:slideFrom];
    [activityIndicatorView startAnimating];
    GlobalData *obj=[GlobalData getInstance]; 
    int playlistID=playerID;
    if (forcePlaylistID)
        playlistID=0;
    
    if (selectedPlayerID>-1){
        playlistID=selectedPlayerID;
        playerID=selectedPlayerID;
    }
    
    if (playlistID==0){
        playerID=0;
        seg_music.selected=YES;
        seg_video.selected=NO;
//        PartyModeButton.hidden=NO;
        [self AnimButton:PartyModeButton AnimDuration:0.3 hidden:NO XPos:8];
//        [self alphaButton:PartyModeButton AnimDuration:0.2 show:NO];
//        PartyModeButton.hidden=NO;


    }
    else if (playlistID==1){
        playerID=1;
        seg_music.selected=NO;
        seg_video.selected=YES;
        [self AnimButton:PartyModeButton AnimDuration:0.3 hidden:YES XPos:-72];

//        [self alphaButton:PartyModeButton AnimDuration:0.2 show:YES];

//        PartyModeButton.hidden=YES;

        
    }
    [self alphaView:noFoundView AnimDuration:0.2 Alpha:0.0];
    jsonRPC = nil;
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC callMethod:@"Playlist.GetItems" 
         withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                         [[NSArray alloc] initWithObjects:@"thumbnail", @"duration",@"artist", @"album", @"runtime", @"showtitle", @"season", @"episode",@"artistid", @"albumid", nil], @"properties",
                         [NSNumber numberWithInt:playlistID], @"playlistid",
                         nil] 
           onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
               int total=0;
               if (error==nil && methodError==nil){
                   [playlistData removeAllObjects];
                   [playlistTableView reloadData];
                   if( [NSJSONSerialization isValidJSONObject:methodResult]){
//                       NSLog(@"%@", methodResult);
                       NSArray *playlistItems = [methodResult objectForKey:@"items"];
                       total=[playlistItems count];
                       if (total==0){
                           [self alphaView:noFoundView AnimDuration:0.2 Alpha:1.0];
                       }
                       else {
                           [self alphaView:noFoundView AnimDuration:0.2 Alpha:0.0];
                       }
//                       NSLog(@"TOTAL %d", total);
                       NSString *serverURL=[NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
                       for (int i=0; i<total; i++) {
                           NSString *idItem=[NSString stringWithFormat:@"%@",[[playlistItems objectAtIndex:i] objectForKey:@"id"]];
//                           NSLog(@"ID1 %@ ID2 %@", idItem, [[playlistItems objectAtIndex:i] objectForKey:@"id"]);
                           NSString *label=[NSString stringWithFormat:@"%@",[[playlistItems objectAtIndex:i] objectForKey:@"label"]];
                          
                           NSString *artist=[[[playlistItems objectAtIndex:i] objectForKey:@"artist"] length]==0? @"" :[[playlistItems objectAtIndex:i] objectForKey:@"artist"];
                           NSString *album=[[[playlistItems objectAtIndex:i] objectForKey:@"album"] length]==0? @"" :[[playlistItems objectAtIndex:i] objectForKey:@"album"];
                           NSString *runtime=[[[playlistItems objectAtIndex:i] objectForKey:@"runtime"] length]==0? @"" : [NSString stringWithFormat:@"%@ min",[[playlistItems objectAtIndex:i] objectForKey:@"runtime"]];
                           NSString *showtitle=[[playlistItems objectAtIndex:i] objectForKey:@"showtitle"];
                         
                           NSString *season=[[playlistItems objectAtIndex:i] objectForKey:@"season"];
                           NSString *episode=[[playlistItems objectAtIndex:i] objectForKey:@"episode"];
                           NSString *type=[[playlistItems objectAtIndex:i] objectForKey:@"type"];


                           NSNumber *itemDurationSec=[[playlistItems objectAtIndex:i] objectForKey:@"duration"];
                           NSString *durationTime=[itemDurationSec longValue]==0 ? @"" : [self convertTimeFromSeconds:itemDurationSec];

                           NSString *thumbnail=[NSString stringWithFormat:@"%@",[[playlistItems objectAtIndex:i] objectForKey:@"thumbnail"]];
                           NSString *stringURL = [NSString stringWithFormat:@"http://%@%@", serverURL, thumbnail];
                           
                           [playlistData addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                    idItem, @"idItem",
                                                    label, @"label",
                                                    type,@"type",
                                                    artist, @"artist",
                                                    album, @"album",
                                                    durationTime, @"duration",
                                                    stringURL, @"thumbnail",
                                                    runtime,@"runtime",
                                                    showtitle,@"showtitle",
                                                    season, @"season",
                                                    episode, @"episode",
                                                    nil]];
                       }
//                       NSLog(@"DATACOUNT: %@", playlistData );
                       // SHOULD BE INCLUDED INSIDE showPlaylistTable INSTEAD?
                       
                       
                       [self showPlaylistTable];
                       if (musicPartyMode && playlistID==0){
                           [playlistTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
                       }
                       
                           

                   }
               }
               else {
//                   NSLog(@"ci deve essere un primo problema %@", methodError);
                   [self showPlaylistTable];
               }
           }];
}

-(void)showPlaylistTable{    
    numResults=[playlistData count];
    if (numResults==0)
        [self alphaView:noFoundView AnimDuration:0.2 Alpha:1.0];
    else {
        [self AnimTable:playlistTableView AnimDuration:0.3 Alpha:1.0 XPos:0];
    }
    
    [playlistTableView reloadData]; 
    [activityIndicatorView stopAnimating];
}

-(void)SimpleAction:(NSString *)action params:(NSDictionary *)parameters{
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC callMethod:action withParameters:parameters onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error!=nil || methodError!=nil){
//            NSLog(@" errore %@ %@",error, methodError);
        }
    }];
}

# pragma mark -  animations
BOOL playlistHidden=NO;
BOOL nowPlayingHidden=NO;
int anim;
int anim2;

-(void)animViews{

    [UIView animateWithDuration:0.2
                     animations:^{ 
                         if (!nowPlayingView.hidden){
                             nowPlayingView.hidden = YES;
                             transitionView=nowPlayingView;
                             transitionedView=playlistView;
                             playlistHidden = NO;
                             nowPlayingHidden = YES;
                             viewTitle.text = @"Playlist";
                             self.navigationItem.title = @"Playlist";
                             self.navigationItem.titleView.hidden=YES;
                             anim=UIViewAnimationTransitionFlipFromRight;
                             anim2=UIViewAnimationTransitionFlipFromRight;
                         }
                         else {
                             playlistView.hidden = YES;
                             transitionView=playlistView;
                             transitionedView=nowPlayingView;
                             playlistHidden = YES;
                             nowPlayingHidden = NO;
                             viewTitle.text = @"Now playing";
                             self.navigationItem.title = @"Now playing";
                             self.navigationItem.titleView.hidden=YES;
                             anim=UIViewAnimationTransitionFlipFromLeft;
                             anim2=UIViewAnimationTransitionFlipFromLeft;
                         }
                         [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
                         [UIView setAnimationTransition:anim forView:transitionView cache:YES];
                     } 
                     completion:^(BOOL finished){
                         [UIView beginAnimations:nil context:nil];
                         playlistView.hidden=playlistHidden;
                         nowPlayingView.hidden=nowPlayingHidden;
                         self.navigationItem.titleView.hidden=NO;
                         [UIView setAnimationDuration:0.5];
                         [UIView setAnimationDelegate:self];
                         [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
                         [UIView setAnimationTransition:anim2 forView:transitionedView cache:YES];
                         [UIView commitAnimations];
                     }];   
}

#pragma mark - bottom toolbar

- (IBAction)startVibrate:(id)sender {
//    NSLog(@"%d", [sender tag]);
    NSString *action;
    NSArray *params;
 
    switch ([sender tag]) {
       
        case 1:
            action=@"Player.GoPrevious";
            params=nil;
            [self playbackAction:action params:nil checkPartyMode:YES];
            [timeCursor.layer removeAllAnimations];
            [timeBar.layer removeAllAnimations];
            [self animCursor:startx];
            [self resizeBar:0];
            //storeSelection=nil;
            break;
            
        case 2:
            action=@"Player.PlayPause";
            params=nil;
            [self playbackAction:action params:nil checkPartyMode:NO];
            break;
            
        case 3:
            action=@"Player.Stop";
            params=nil;
            [self playbackAction:action params:nil checkPartyMode:NO];
            storeSelection=nil;

            break;
            
        case 4:
            action=@"Player.GoNext";
            params=nil;
            [self playbackAction:action params:nil checkPartyMode:YES];
           // storeSelection=nil;
//            [timeCursor.layer removeAllAnimations];
//            [timeBar.layer removeAllAnimations];
//            [self animCursor:startx];
//            [self resizeBar:0];
            break;
            
        case 5:
//            [self performTransition];
            
            [self animViews];       
            [self toggleViewToolBar:volumeSliderView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:TRUE];
            break;
        case 6:
            action=@"Player.Seek";
            params=[NSArray arrayWithObjects:@"smallbackward", @"value", nil];
            [self playbackAction:action params:params checkPartyMode:NO];
            break;
            
        case 7:
            action=@"Player.Seek";
            params=[NSArray arrayWithObjects:@"smallforward", @"value", nil];
            [self playbackAction:action params:params checkPartyMode:NO];
            break;
            
                    
        default:
            break;
    }
    //    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}



-(void)updateInfo{
//    NSLog(@"OGNI SECONDO");
    [self playbackInfo];
}

#pragma mark - Touch Events

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if([touch.view isEqual:jewelView]){
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        [UIView setAnimationDuration:0.1];
        if (songDetailsView.alpha==0){
            songDetailsView.alpha=0.8;
//            songDetailsView.hidden=NO;
        }
        else {
            songDetailsView.alpha=0.0;
//            songDetailsView.hidden=YES;
        }
        [UIView commitAnimations];
        [self toggleViewToolBar:volumeSliderView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:TRUE];

    }
//    if(![touch.view isEqual:volumeSliderView]){
//        [self toggleViewToolBar:volumeSliderView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:TRUE];
//    }
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [playlistData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"playlistCell"];
    if (cell==nil){
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"playlistCellView" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    NSDictionary *item = [playlistData objectAtIndex:indexPath.row];
    UIImageView *thumb=(UIImageView*) [cell viewWithTag:4]; 
    [(UILabel*) [cell viewWithTag:1] setText:[item objectForKey:@"label"]];
    [(UILabel*) [cell viewWithTag:2] setText:@""];
    if ([[item objectForKey:@"season"] intValue]>0){
//        CGRect frame=thumb.frame;
//        frame.size.width=95;
//        thumb.frame=frame;
        [(UILabel*) [cell viewWithTag:2] setText:[NSString stringWithFormat:@"%@ - %@x%@", [item objectForKey:@"showtitle"], [item objectForKey:@"season"], [item objectForKey:@"episode"]]];
    }
    else if (playerID==0){
        NSString *artist=[[item objectForKey:@"artist"] length]==0? @"" :[NSString stringWithFormat:@" - %@", [item objectForKey:@"artist"]];
        [(UILabel*) [cell viewWithTag:2] setText:[NSString stringWithFormat:@"%@%@",[item objectForKey:@"album"], artist]];

    }
    if (playerID==0)
        [(UILabel*) [cell viewWithTag:3] setText:[item objectForKey:@"duration"]];
    if (playerID==1)
        [(UILabel*) [cell viewWithTag:3] setText:[item objectForKey:@"runtime"]];
    NSString *stringURL = [item objectForKey:@"thumbnail"];
    
    
    
    if ((playlistTableView.decelerating == NO) || numResults<SHOW_ONLY_VISIBLE_THUMBNAIL_START_AT){
        //        NSURL *imageUrl = [NSURL URLWithString: stringURL];    
        //        UIImage *cachedImage = [manager imageWithURL:imageUrl];
        //        if (cachedImage){
        //            cell.urlImageView.image=cachedImage;
        //        }
        //        else {    
        [thumb setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:@"nocover_music.png"] ];
        //        }
    }
    else {
        thumb.image=[UIImage imageNamed:@"nocover_music.png"];  
    }
    
   // [thumb setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:@"nocover_music.png"]];
    
    
    
    UIView *timePlaying=(UIView*) [cell viewWithTag:5];
    if (timePlaying.hidden==NO)
        [self fadeView:timePlaying hidden:YES];
//    timePlaying.hidden=YES;
    return cell;
}
-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:indexPath];
    UIImageView *coverView=(UIImageView*) [cell viewWithTag:4];
    coverView.alpha=1.0;
    UIView *timePlaying=(UIView*) [cell viewWithTag:5];
    storeSelection=nil;
    if (timePlaying.hidden==NO)
        [self fadeView:timePlaying hidden:YES];

    //timePlaying.hidden=YES;
}

-(void)checkPartyMode{
    if (musicPartyMode){
        lastSelected=-1;
        storeSelection=0;
        [self createPlaylist:NO];
    }
 }

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:indexPath];
    UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
    storeSelection=nil;
    [queuing startAnimating];
    if (playerID==-2)
        playerID=0;
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC 
     callMethod:@"Player.Open" 
     withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                     [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithInt:indexPath.row], @"position", [NSNumber numberWithInt:playerID], @"playlistid", nil], @"item", nil]
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (error==nil && methodError==nil){
             UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
             [queuing stopAnimating];
             UIView *timePlaying=(UIView*) [cell viewWithTag:5];
             if (timePlaying.hidden==YES)
                 [self fadeView:timePlaying hidden:NO];
           //  [self checkPartyMode];
         }
         else {
//             NSLog(@"EROR %@", methodError);
             UIActivityIndicatorView *queuing=(UIActivityIndicatorView*) [cell viewWithTag:8];
             [queuing stopAnimating];
         }
     }
     ];
    
}

//- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//    UIImage *myImage = [UIImage imageNamed:@"blank.png"];
//    UIImageView *imageView = [[UIImageView alloc] initWithImage:myImage] ;
//    imageView.frame = CGRectMake(0,0,320,1);
//    return imageView;
//}
//
//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    return 1;
//}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIImage *myImage = [UIImage imageNamed:@"blank.png"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:myImage] ;
    imageView.frame = CGRectMake(0,0,320,1);
    return imageView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    if (storeSelection && storeSelection.row==indexPath.row)
        return NO;
    return YES;
}

- (BOOL)tableView:(UITableView *)tableview canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
//    UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:indexPath];
//
//    UIView *timePlaying=(UIView*) [cell viewWithTag:5];
//    if (timePlaying.hidden) return YES;
//    else return NO;
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    
    NSDictionary *objSource = [playlistData objectAtIndex:sourceIndexPath.row];
    
//    NSLog(@"SOURCE %d DESTINATION %d", sourceIndexPath.row, destinationIndexPath.row);
    
    int idItem=[[objSource objectForKey:@"idItem"] intValue];
    
    NSString *action1=@"Playlist.Remove";
    NSDictionary *params1=[NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithInt:playerID], @"playlistid",
                          [NSNumber numberWithInt:sourceIndexPath.row],@"position", 
                          nil] ;
    NSString *action2=@"Playlist.Insert";
    NSDictionary *params2=[NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithInt:playerID], @"playlistid",
                          [NSDictionary dictionaryWithObjectsAndKeys: 
                           [NSNumber numberWithInt:idItem], [NSString stringWithFormat:@"%@id", [objSource objectForKey:@"type"]], 
                           nil],@"item",
                          [NSNumber numberWithInt:destinationIndexPath.row],@"position",
                          nil];
    jsonRPC = nil;
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC callMethod:action1 withParameters:params1 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            [jsonRPC callMethod:action2 withParameters:params2];
            [playlistData removeObjectAtIndex:[sourceIndexPath row]];
            [playlistData insertObject:objSource atIndex:[destinationIndexPath row]];
//            NSLog(@"SOURCE %d DESTINATION %d STORE %d", sourceIndexPath.row, destinationIndexPath.row, storeSelection.row);

            if (sourceIndexPath.row>storeSelection.row && destinationIndexPath.row<=storeSelection.row){
                storeSelection=[NSIndexPath  indexPathForRow:storeSelection.row+1 inSection:storeSelection.section];
//                NSLog(@"INCREMENTO STORE %d", storeSelection.row);
            }
            else if (sourceIndexPath.row<storeSelection.row && destinationIndexPath.row>=storeSelection.row){
                storeSelection=[NSIndexPath  indexPathForRow:storeSelection.row-1 inSection:storeSelection.section];
//                NSLog(@"DECREMENTO STORE %d", storeSelection.row);
            }
            [playlistTableView reloadData];
        }
        else{
//            NSLog(@" errore rimozione playlist %@ %@",error, methodError);
            [playlistTableView reloadData];
            [playlistTableView selectRowAtIndexPath:storeSelection animated:YES scrollPosition:UITableViewScrollPositionMiddle];

        }
    }];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        jsonRPC = nil;
        GlobalData *obj=[GlobalData getInstance]; 
        NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
        NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
        jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
        NSString *action1=@"Playlist.Remove";
        NSDictionary *params1=[NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithInt:playerID], @"playlistid",
                               [NSNumber numberWithInt:indexPath.row],@"position", 
                               nil] ;
        [jsonRPC callMethod:action1 withParameters:params1 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
            if (error==nil && methodError==nil){
                [playlistData removeObjectAtIndex:indexPath.row];
                [playlistTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
                if ((storeSelection) && (indexPath.row<storeSelection.row)){
                        storeSelection=[NSIndexPath  indexPathForRow:storeSelection.row-1 inSection:storeSelection.section];
                }
            }
            else{
                [playlistTableView reloadData];
                [playlistTableView selectRowAtIndexPath:storeSelection animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            }
        }];
    } 
 
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (aTableView.editing) {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

-(IBAction)editTable:(id)sender forceClose:(BOOL)forceClose{
    if ([playlistData count]==0 && !playlistTableView.editing) return;
    if (playlistTableView.editing || forceClose==YES){
        [playlistTableView setEditing:NO animated:YES];
        [editTableButton setSelected:NO];
        lastSelected=-1;
        storeSelection=nil;
    }
    else{
        storeSelection = [playlistTableView indexPathForSelectedRow];
        [playlistTableView setEditing:YES animated:YES];
        [editTableButton setSelected:YES];
    }
}

#pragma mark -
#pragma mark Deferred image loading (UIScrollViewDelegate)

- (void)loadImagesForOnscreenRows{
    if ([playlistData count] > 0 && numResults>=SHOW_ONLY_VISIBLE_THUMBNAIL_START_AT){
        NSArray *visiblePaths = [playlistTableView indexPathsForVisibleRows];
        NSString *defaultThumb=@"nocover_music.png";
        for (NSIndexPath *indexPath in visiblePaths){
            UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:indexPath];
            UIImageView *thumb=(UIImageView*) [cell viewWithTag:4];
            //            [self alphaImage:thumb AnimDuration:0.1 Alpha:0.0];
            NSDictionary *item = [playlistData objectAtIndex:indexPath.row];
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
            //            [self alphaImage:thumb AnimDuration:0.1 Alpha:1.0];
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
# pragma  mark - Gestures

- (void)handleSwipeFromRight:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)showRemoteController{
    self.remoteController=nil;
    self.remoteController = [[RemoteController alloc] initWithNibName:@"RemoteController" bundle:nil];
    mainMenu *item = [[mainMenu alloc] init];
    item.mainLabel = @"Remote Control";
    self.remoteController.detailItem = item;
    [self.navigationController pushViewController:self.remoteController animated:YES];
}

#pragma mark - Interface customizations

-(void)setToolbarWidth:(int)width height:(int)height YPOS:(int)YPOS playBarWidth:(int)playBarWidth portrait:(BOOL)isPortrait{
    CGRect frame;
    barwidth = playBarWidth;
    frame=playlistToolbar.frame;
    frame.size.width=width+20;
    frame.origin.x=0;
    playlistToolbar.frame=frame;
    frame=nowPlayingView.frame;
    frame.origin.x=302;
    frame.origin.y=YPOS;
    frame.size.height=height - 84;
    frame.size.width=width - 302;
    nowPlayingView.frame=frame;
    portraitMode = isPortrait;
    [self setCoverSize:currentType];
}

-(void)setIphoneInterface{
    volumeSliderView = [[VolumeSliderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 62.0f, 296.0f)];
    CGRect frame=volumeSliderView.frame;
    frame.origin.x=258;
    frame.origin.y=-volumeSliderView.frame.size.height;
    volumeSliderView.frame=frame;
    [self.view addSubview:volumeSliderView];
    UIImage* volumeImg = [UIImage imageNamed:@"volume.png"];
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:volumeImg style:UIBarButtonItemStyleBordered target:self action:@selector(toggleVolume)];
    self.navigationItem.rightBarButtonItem = settingsButton;
    slideFrom=320;
}

-(void)setIpadInterface{
    slideFrom=-300;
    CGRect frame;
    [albumName setFont:[UIFont fontWithName:@"Optima-Regular" size:24]];
    frame=albumName.frame;
    frame.origin.y=10;
    albumName.frame=frame;
    [songName setFont:[UIFont fontWithName:@"Optima-Regular" size:18]];
    frame=songName.frame;
    frame.origin.y=frame.origin.y+6;
    songName.frame=frame;
    
    [artistName setFont:[UIFont fontWithName:@"Optima-Regular" size:16]];
    frame=artistName.frame;
    frame.origin.y=frame.origin.y+12;
    artistName.frame=frame;
    
    [currentTime setFont:[UIFont fontWithName:@"Optima-Regular" size:14]];
    [duration setFont:[UIFont fontWithName:@"Optima-Regular" size:14]];
    frame=playlistTableView.frame;
    frame.origin.x=slideFrom;
    playlistTableView.frame=frame;
    
    NSMutableArray *items = [NSMutableArray arrayWithArray:playlistToolbar.items];
    [items removeObjectAtIndex:1];
    [items removeObjectAtIndex:2];
    [items removeObjectAtIndex:3];
    [items removeObjectAtIndex:4];
    [items removeObjectAtIndex:5];
    [items removeObjectAtIndex:6];
    [items removeObjectAtIndex:7];
    [playlistToolbar setItems:items animated:YES];
    
    UIButton *buttonItem=(UIButton *)[self.view viewWithTag:5];
    [buttonItem removeFromSuperview];
    
    nowPlayingView.hidden=NO;
    playlistView.hidden=NO;
    //button.hidden=YES;
}

#pragma mark - Life Cycle

-(void)viewWillAppear:(BOOL)animated{
    [self playbackInfo];
    [volumeSliderView startTimer]; 
    lastSelected = -1;
    playerID = -1;
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateInfo) userInfo:nil repeats:YES];
    
    // TRICK TO FORCE VIEW IN PORTRAIT EVEN IF ROOT NAVIGATION WAS LANDSCAPE
    UIViewController *c = [[UIViewController alloc]init];
    [self presentModalViewController:c animated:NO];
    [self dismissModalViewControllerAnimated:NO]; 
}

-(void)viewWillDisappear:(BOOL)animated{
    [timer invalidate];
    currentItemID = -1;
    [volumeSliderView stopTimer];
//    [self toggleViewToolBar:volumeSliderView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:TRUE];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    [[SDImageCache sharedImageCache] clearMemory];
    playerID = -1;
    selectedPlayerID = -1;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self setIphoneInterface];
    }
    else{
        [self setIpadInterface];
    }
    
    playlistData = [[NSMutableArray alloc] init ];
    manager = [SDWebImageManager sharedManager];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnterForeground:)
                                                 name: @"UIApplicationWillEnterForegroundNotification"
                                               object: nil];
}

- (void) handleEnterForeground: (NSNotification*) sender;{
    [self checkPartyMode];
}

- (void)viewDidUnload{
    [super viewDidUnload];
    volumeSliderView = nil;
}

-(void)dealloc{
    volumeSliderView = nil;
    self.detailItem = nil;
    playlistData = nil;
    jsonRPC = nil;
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
//    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
//}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
