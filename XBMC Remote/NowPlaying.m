//
//  NowPlaying.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 24/3/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import "NowPlaying.h"
#import "mainMenu.h"
#import "UIImageView+WebCache.h"
#import <QuartzCore/QuartzCore.h>
#import "GlobalData.h"
#import "VolumeSliderView.h"

@interface NowPlaying ()

@end

@implementation NowPlaying

@synthesize detailItem = _detailItem;
float startx=14;
float barwidth=280;
float cellBarWidth=45;

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

-(void)fadeView:(UIView *)view hidden:(BOOL)value{
//    [UIView beginAnimations:nil context:nil];
//    [UIView setAnimationDuration:0.1];
//    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    view.hidden=value;
//    [UIView commitAnimations];
}

#pragma  mark - JSON management

int lastSelected=-1;

-(void)playbackInfo{
    [jsonRPC callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            if( [methodResult count] > 0){
                NSNumber *response = [[methodResult objectAtIndex:0] objectForKey:@"playerid"];
                [jsonRPC 
                 callMethod:@"Player.GetItem" 
                 withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                                 response, @"playerid",
                                 [[NSArray alloc] initWithObjects:@"album", @"artist",@"title", @"thumbnail", nil], @"properties",
                                 nil] 
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                     if (error==nil && methodError==nil){
//                         NSLog(@"Risposta %@", methodResult);
                         if( [NSJSONSerialization isValidJSONObject:methodResult]){
                             NSDictionary *nowPlayingInfo = [methodResult objectForKey:@"item"];
                             if ([nowPlayingInfo count]){
                                 NSString *album=[NSString stringWithFormat:@"%@",[nowPlayingInfo  objectForKey:@"album"]];
                                 NSString *title=[NSString stringWithFormat:@"%@",[nowPlayingInfo  objectForKey:@"title"]];
                                 NSString *artist=[NSString stringWithFormat:@"%@",[nowPlayingInfo objectForKey:@"artist"]];
//                                 NSNumber *timeduration=[nowPlayingInfo objectForKey:@"duration"];
                                 albumName.text=album;
                                 songName.text=title;
                                 artistName.text=artist;
                                 NSString *type=[nowPlayingInfo objectForKey:@"type"];
                                 NSString *jewelImg=@"";
                                 if ([type isEqualToString:@"song"]){
                                     jewelImg=@"jewel_cd.9.png";
                                     CGRect frame=thumbnailView.frame;
                                     frame.origin.x=50;
                                     frame.origin.y=39;
                                     frame.size.width=237;
                                     frame.size.height=245;
                                     thumbnailView.frame=frame;
                                 }
                                 else if ([type isEqualToString:@"movie"]){
                                     CGRect frame=thumbnailView.frame;
                                     frame.origin.x=50;
                                     frame.origin.y=39;
                                     frame.size.width=237;
                                     frame.size.height=245;
                                     thumbnailView.frame=frame;
                                     jewelImg=@"jewel_dvd.9.png";
                                 }
                                 else if ([type isEqualToString:@"episode"]){
                                     jewelImg=@"jewel_tv.9.png";
                                     CGRect frame=thumbnailView.frame;
                                     frame.origin.x=20;
                                     frame.origin.y=78;
                                     frame.size.width=280;
                                     frame.size.height=158;
                                     thumbnailView.frame=frame;
                                     
                                 }
                                 jewelView.image=[UIImage imageNamed:jewelImg];
//                                 NSLog(@"TIPO %@", type);
//                                 duration.text=[self convertTimeFromSeconds:timeduration];
                             }
                             GlobalData *obj=[GlobalData getInstance]; 
                             NSString *serverURL=[NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];

                             NSString *thumbnailPath=[nowPlayingInfo objectForKey:@"thumbnail"];
                             
                             NSString *stringURL = [NSString stringWithFormat:@"http://%@%@", serverURL, thumbnailPath];
                             
                             NSURL *imageUrl = [NSURL URLWithString: stringURL];
//                             NSLog(@"%@", thumbnailPath);
//                             thumbnailView.image=[UIImage im];
                             SDWebImageManager *manager = [SDWebImageManager sharedManager];
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
                             thumbnailView.image=[UIImage imageNamed:@"coverbox_back.png"];
                             //                                      NSLog(@"SONO IO ERROR:%@ METHOD:%@", error, methodError);
                         }
                             
                         
                     }
                     else {
                         NSLog(@"ci deve essere un secondo problema %@", methodError);
                     }
                 }];
             
                [jsonRPC 
                 callMethod:@"Player.GetProperties" 
                 withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                                 response, @"playerid",
                                 [[NSArray alloc] initWithObjects:@"percentage", @"time", @"totaltime", nil], @"properties",
                                 nil] 
                 onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                     if (error==nil && methodError==nil){
                         if( [NSJSONSerialization isValidJSONObject:methodResult]){
//                             NSLog(@"risposta %@", methodResult);
                             if ([methodResult count]){
                                 
                                 float newx=barwidth * [(NSNumber*) [methodResult objectForKey:@"percentage"] floatValue] / 100;
                                 if (newx<1)
                                     newx=1;
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
                                     [self fadeView:timePlaying hidden:NO];
//                                     timePlaying.hidden=NO;
//                                     UIImageView *coverView=(UIImageView*) [cell viewWithTag:4];
//                                     coverView.alpha=0.6;
                                 }

//                                 NSLog(@"time %@", actualTime);
                             }
                         }
                     }
                     else {
                         NSLog(@"ci deve essere un secondo problema %@", methodError);
                     }
                 }];
            }
            else{
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
//                NSLog(@"Nothing is playing");
            }
        }
        else {
//            NSLog(@"ci deve essere un primo problema %@", methodError);
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

        }
    }];
    
    [jsonRPC 
     callMethod:@"XBMC.GetInfoLabels" 
     withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                     [[NSArray alloc] initWithObjects:@"MusicPlayer.Codec",@"MusicPlayer.SampleRate",@"MusicPlayer.BitRate", @"MusicPlayer.PlaylistPosition", nil], @"labels",
                     nil] 
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (error==nil && methodError==nil){
//             NSLog(@"RISULTATO %@", methodResult);
             NSNumber *playlistPosition = [methodResult objectForKey:@"MusicPlayer.PlaylistPosition"];
             if ([playlistPosition intValue]!=lastSelected){
                 
                 NSString *codec=[[methodResult objectForKey:@"MusicPlayer.Codec"] isEqualToString:@""] ? @"-" : [NSString stringWithFormat:@"%@", [methodResult objectForKey:@"MusicPlayer.Codec"]] ;
                 songCodec.text=codec;
                 
                 NSString *bitrate=[[methodResult objectForKey:@"MusicPlayer.BitRate"] isEqualToString:@""] ? @"-" : [NSString stringWithFormat:@"%@ kbit/s", [methodResult objectForKey:@"MusicPlayer.BitRate"]] ;
                 songBitRate.text=bitrate;
                 
                 NSString *samplerate=[[methodResult objectForKey:@"MusicPlayer.SampleRate"] isEqualToString:@""] ? @"-" : [NSString stringWithFormat:@"%@ MHz", [methodResult objectForKey:@"MusicPlayer.SampleRate"]];
                 songSampleRate.text=samplerate;
                 
                 if ([playlistData count]>=[playlistPosition intValue]){
                     if ([playlistPosition intValue]){
                         if (lastSelected!=[playlistPosition intValue]){
                             NSIndexPath* selection = [playlistTableView indexPathForSelectedRow];
                             if (selection){
                                 UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:selection];
                                 UIView *timePlaying=(UIView*) [cell viewWithTag:5];
                                 [self fadeView:timePlaying hidden:YES];
//                                 timePlaying.hidden=YES;
                                 UIImageView *coverView=(UIImageView*) [cell viewWithTag:4];
                                 coverView.alpha=1.0;
                             }
                             NSIndexPath *newSelection=[NSIndexPath indexPathForRow:[playlistPosition intValue]-1 inSection:0];
                             [playlistTableView selectRowAtIndexPath:newSelection animated:YES scrollPosition:UITableViewScrollPositionMiddle];
                             UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:newSelection];
                             UIView *timePlaying=(UIView*) [cell viewWithTag:5];
                             [self fadeView:timePlaying hidden:NO];
//                             timePlaying.hidden=NO;
                             lastSelected=[playlistPosition intValue];
                         }
                     }
                     else {
                         NSIndexPath* selection = [playlistTableView indexPathForSelectedRow];
                         if (selection){
                             [playlistTableView deselectRowAtIndexPath:selection animated:YES];
                             UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:selection];
                             UIView *timePlaying=(UIView*) [cell viewWithTag:5];
                             [self fadeView:timePlaying hidden:YES];
//                             timePlaying.hidden=YES;
                             UIImageView *coverView=(UIImageView*) [cell viewWithTag:4];
                             coverView.alpha=1.0;
                         }
                     }
                     
                 }
             }
         }
         else {
             NSLog(@"ERROR %@", methodError);
         }
     }];                                            
}

-(void)playbackAction:(NSString *)action params:(NSArray *)parameters{
    [jsonRPC callMethod:@"Player.GetActivePlayers" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            if( [methodResult count] > 0){
                NSNumber *response = [[methodResult objectAtIndex:0] objectForKey:@"playerid"];
                NSMutableArray *commonParams=[NSMutableArray arrayWithObjects:response, @"playerid", nil];
                if (parameters!=nil)
                    [commonParams addObjectsFromArray:parameters];
                [jsonRPC callMethod:action withParameters:[self indexKeyedDictionaryFromArray:commonParams] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                    if (error==nil && methodError==nil){
//                        NSLog(@"comando %@ eseguito ", action);
                    }
                    else {
                        NSLog(@"ci deve essere un secondo problema %@", methodError);
                    }
                }];
            }
        }
        else {
            NSLog(@"ci deve essere un primo problema %@", methodError);
        }
    }];
}

-(void)createPlaylist{
    /*
     {"method":"Playlist.GetItems","id":23,"jsonrpc":"2.0","params":{"properties":["thumbnail","runtime"],"playlistid":1}}
     {"method":"Playlist.GetItems","id":23,"jsonrpc":"2.0","params":{"properties":["thumbnail","duration","artist","album"],"playlistid":0}}
     
     */
    GlobalData *obj=[GlobalData getInstance]; 
    [jsonRPC callMethod:@"Playlist.GetItems" 
         withParameters:[NSDictionary dictionaryWithObjectsAndKeys: 
                         [[NSArray alloc] initWithObjects:@"thumbnail", @"duration",@"artist", @"album", nil], @"properties",
                         [NSNumber numberWithInt:0], @"playlistid",
                         nil] 
           onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
               int total=0;
               if (error==nil && methodError==nil){
                   if( [NSJSONSerialization isValidJSONObject:methodResult]){
//                       NSLog(@"%@", methodResult);
                       NSArray *playlistItems = [methodResult objectForKey:@"items"];
                       total=[playlistItems count];
                       //                       NSLog(@"TOTAL %d", total);
                       NSString *serverURL=[NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
                       for (int i=0; i<total; i++) {
                           NSString *idItem=[NSString stringWithFormat:@"%d",[[playlistItems objectAtIndex:i] objectForKey:@"id"]];
                           NSString *label=[NSString stringWithFormat:@"%@",[[playlistItems objectAtIndex:i] objectForKey:@"label"]];
                           NSString *artist=[NSString stringWithFormat:@"%@",[[playlistItems objectAtIndex:i] objectForKey:@"artist"]];
                           NSString *album=[NSString stringWithFormat:@"%@",[[playlistItems objectAtIndex:i] objectForKey:@"album"]];
                           NSNumber *itemDurationSec=[NSString stringWithFormat:@"%@",[[playlistItems objectAtIndex:i] objectForKey:@"duration"]];
                           NSString *durationTime=[self convertTimeFromSeconds:itemDurationSec];
                           
                           NSString *thumbnail=[NSString stringWithFormat:@"%@",[[playlistItems objectAtIndex:i] objectForKey:@"thumbnail"]];
                           NSString *stringURL = [NSString stringWithFormat:@"http://%@%@", serverURL, thumbnail];
                           
                           [playlistData addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                    idItem, @"idItem",
                                                    label, @"label",
                                                    artist, @"artist",
                                                    album, @"album",
                                                    durationTime, @"duration",
                                                    stringURL, @"thumbnail",
                                                    nil]];
                           
                       }
                       //NSLog(@"DATACOUNT: %d", [playlistData count]);
                       [playlistTableView reloadData];
                   }
               }
               else {
                   NSLog(@"ci deve essere un primo problema %@", methodError);
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
                             anim=UIViewAnimationTransitionFlipFromLeft;
                             anim2=UIViewAnimationTransitionFlipFromLeft;
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
                             anim=UIViewAnimationTransitionFlipFromRight;
                             anim2=UIViewAnimationTransitionFlipFromRight;
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
            [self playbackAction:action params:nil];
            [timeCursor.layer removeAllAnimations];
            [timeBar.layer removeAllAnimations];
            [self animCursor:startx];
            [self resizeBar:0];
            break;
            
        case 2:
            action=@"Player.PlayPause";
            params=nil;
            [self playbackAction:action params:nil];
            break;
            
        case 3:
            action=@"Player.Stop";
            params=nil;
            [self playbackAction:action params:nil];
            break;
            
        case 4:
            action=@"Player.GoNext";
            params=nil;
            [self playbackAction:action params:nil];
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
            [self playbackAction:action params:params];
            break;
            
        case 7:
            action=@"Player.Seek";
            params=[NSArray arrayWithObjects:@"smallforward", @"value", nil];
            [self playbackAction:action params:params];
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
    }
    if(![touch.view isEqual:volumeSliderView]){
        [self toggleViewToolBar:volumeSliderView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:TRUE];
    }
    
}

#pragma mark Table MAnagement

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
    [(UILabel*) [cell viewWithTag:1] setText:[item objectForKey:@"label"]];
    [(UILabel*) [cell viewWithTag:2] setText:[NSString stringWithFormat:@"%@ - %@",[item objectForKey:@"album"], [item objectForKey:@"artist"]]];
    [(UILabel*) [cell viewWithTag:3] setText:[item objectForKey:@"duration"]];
    NSString *stringURL = [item objectForKey:@"thumbnail"];
    [(UIImageView*) [cell viewWithTag:4] setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:@"nocover_music.png"]];
    UIView *timePlaying=(UIView*) [cell viewWithTag:5];
    [self fadeView:timePlaying hidden:YES];
//    timePlaying.hidden=YES;
    return cell;
}
-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:indexPath];
    UIImageView *coverView=(UIImageView*) [cell viewWithTag:4];
    coverView.alpha=1.0;
    UIView *timePlaying=(UIView*) [cell viewWithTag:5];
    [self fadeView:timePlaying hidden:YES];
    //timePlaying.hidden=YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [jsonRPC 
     callMethod:@"Player.Open" 
     withParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                     [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithInt:indexPath.row], @"position", [NSNumber numberWithInt:0], @"playlistid",                 nil], @"item", nil]
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (error==nil && methodError==nil){
             UITableViewCell *cell = [playlistTableView cellForRowAtIndexPath:indexPath];
             UIView *timePlaying=(UIView*) [cell viewWithTag:5];
             [self fadeView:timePlaying hidden:NO];
//             timePlaying.hidden=NO;
         }
         else {
             NSLog(@"EROR %@", methodError);
         }
     }
     ];
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return NO;
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


#pragma mark - Life Cycle

-(void)viewWillAppear:(BOOL)animated{
    [self playbackInfo];
    [self createPlaylist];
    [volumeSliderView startTimer]; 
    lastSelected=-1;
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateInfo) userInfo:nil repeats:YES];
    
}
-(void)viewWillDisappear:(BOOL)animated{
    [timer invalidate];
    [volumeSliderView stopTimer];
//    [self toggleViewToolBar:volumeSliderView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:TRUE];
    
}
- (void)viewDidLoad{
    [super viewDidLoad];
    volumeSliderView = [[VolumeSliderView alloc] 
                        initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 206.0f)];
    CGRect frame=volumeSliderView.frame;
    frame.origin.x=258;
    frame.origin.y=-206;
    volumeSliderView.frame=frame;
    [self.view addSubview:volumeSliderView];
    UIImage* volumeImg = [UIImage imageNamed:@"volume.png"];
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:volumeImg style:UIBarButtonItemStyleBordered target:self action:@selector(toggleVolume)];
    self.navigationItem.rightBarButtonItem = settingsButton;
    GlobalData *obj=[GlobalData getInstance]; 
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, obj.serverPass, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    playlistData = [[NSMutableArray alloc] init ]; 
}

- (void)viewDidUnload{
    [super viewDidUnload];
    volumeSliderView = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)dealloc{
    volumeSliderView=nil;
    self.detailItem = nil;
    playlistData=nil;
    jsonRPC=nil;
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
//    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
//}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
