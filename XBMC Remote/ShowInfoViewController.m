//
//  ShowInfoViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 27/3/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import "ShowInfoViewController.h"
#import "mainMenu.h"
#import "NowPlaying.h"
#import "GlobalData.h"
#import "SDImageCache.h"
#import "UIImageView+WebCache.h"
#import <QuartzCore/QuartzCore.h>

@interface ShowInfoViewController ()
- (void)configureView;
@end

@implementation ShowInfoViewController

@synthesize detailItem = _detailItem;

@synthesize nowPlaying;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

double round(double d){
    return floor(d + 0.5);
}

int count=0;

- (void)configureView{
    // Update the user interface for the detail item.
    if (self.detailItem) {
        NSDictionary *item=self.detailItem;
        CGRect frame = CGRectMake(0, 0, 140, 40);
        UILabel *viewTitle = [[UILabel alloc] initWithFrame:frame] ;
        viewTitle.numberOfLines=0;
        viewTitle.font = [UIFont boldSystemFontOfSize:11];
        viewTitle.minimumFontSize=6;
        viewTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        viewTitle.backgroundColor = [UIColor clearColor];
        viewTitle.shadowColor = [UIColor colorWithWhite:0.0 alpha:0];
        viewTitle.textAlignment = UITextAlignmentCenter;
        viewTitle.textColor = [UIColor whiteColor];
        viewTitle.text = [item objectForKey:@"label"];
        [viewTitle sizeThatFits:CGSizeMake(140, 40)];
        self.navigationItem.titleView = viewTitle;
        self.navigationItem.title = [item objectForKey:@"label"];
        
        
        UIBarButtonItem *playbackButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(addPlayback)];
        
        UIImage* queueImg = [UIImage imageNamed:@"button_playlist.png"];
//        CGRect frameimg = CGRectMake(0, 0, queueImg.size.width, queueImg.size.height);
//        UIButton *queueButton = [[UIButton alloc] initWithFrame:frameimg];
//        [queueButton setBackgroundImage:queueImg forState:UIControlStateNormal];
//        [queueButton addTarget:self action:@selector(showNowPlaying) forControlEvents:UIControlEventTouchUpInside];
      //  UIBarButtonItem *queueButtonItem =[[UIBarButtonItem alloc] initWithCustomView:queueButton];
        
        UIBarButtonItem *queueButtonItem =[[UIBarButtonItem alloc] initWithImage:queueImg style:UIBarButtonItemStyleBordered target:self action:@selector(addQueue)];
        
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects: playbackButtonItem, queueButtonItem, nil];
        
        UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromRight:)];
        rightSwipe.numberOfTouchesRequired = 1;
        rightSwipe.cancelsTouchesInView=NO;
        rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:rightSwipe];
//        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects: playbackButton, nil];
    }
    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFromLeft:)];
    leftSwipe.numberOfTouchesRequired = 1;
    leftSwipe.cancelsTouchesInView=NO;
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:leftSwipe];
}

-(IBAction)scrollDown:(id)sender{
    CGPoint bottomOffset = CGPointMake(0, scrollView.contentSize.height - scrollView.bounds.size.height);
    [scrollView setContentOffset:bottomOffset animated:YES];
}

-(void)showNowPlaying{
    if (!alreadyPush){
        self.nowPlaying=nil;
        self.nowPlaying = [[NowPlaying alloc] initWithNibName:@"NowPlaying" bundle:nil];
        self.nowPlaying.detailItem = self.detailItem; 
        
        [self.navigationController pushViewController:self.nowPlaying animated:YES];
        self.navigationItem.rightBarButtonItem.enabled=YES;
        alreadyPush=YES;
    }
}

-(void)moveLabel:(NSArray *)objects posY:(int)y{
    int count=[objects count];
    CGRect frame;
    for (int i = 0; i < count; i++){
        if ([[objects objectAtIndex:i] isKindOfClass:[UIImageView class]]){
            UIImageView *label=[objects objectAtIndex:i];
            frame=label.frame;
            frame.origin.y=frame.origin.y - y;
            label.frame=frame;
        }
        if ([[objects objectAtIndex:i] isKindOfClass:[UILabel class]]){
            UILabel *label=[objects objectAtIndex:i];
            frame=label.frame;
            frame.origin.y=frame.origin.y - y;
            label.frame=frame;
        }
        
    }
}

int h=0;
-(void)createInfo{
    NSDictionary *item=self.detailItem;
//    NSLog(@"ITEM %@", item);
    int scrollViewDefaultHeight=660;
    if ([[item objectForKey:@"family"] isEqualToString:@"episodeid"] || [[item objectForKey:@"family"] isEqualToString:@"studio"]){
        int deltaY=0;
        int coverHeight=0;
        int shiftY=40;
        CGRect frame;
        if ([[item objectForKey:@"family"] isEqualToString:@"studio"]){
            coverHeight=70;
            deltaY=jewelView.frame.size.height - coverHeight;
            shiftY=0;
            label1.text=@"EPISODES";
            label3.text=@"GENRE";
            label4.text=@"STUDIO";
            jewelView.hidden=YES;
            frame=coverView.frame;
            frame.origin.x=0;
            frame.origin.y=12;
            frame.size.width=320;
            frame.size.height=59;
            coverView.frame=frame;
            directorLabel.text=[[item objectForKey:@"showtitle"] length]==0 ? @"-" : [item objectForKey:@"showtitle"];
            genreLabel.text=[[item objectForKey:@"premiered"] length]==0 ? @"-" : [item objectForKey:@"premiered"];
            runtimeLabel.text=[[item objectForKey:@"genre"] length]==0 ? @"-" : [item objectForKey:@"genre"];
            studioLabel.text=[[item objectForKey:@"studio"] length]==0 ? @"-" : [item objectForKey:@"studio"];
            self.navigationItem.rightBarButtonItems=nil;
        }
        
        else if ([[item objectForKey:@"family"] isEqualToString:@"episodeid"]){
            coverHeight=200;
            jewelView.hidden=NO;
            deltaY=jewelView.frame.size.height - coverHeight;
            label1.text=@"TV SHOW";
            label3.text=@"DIRECTOR";
            label4.text=@"WRITER";
            parentalRatingLabelUp.hidden=YES;
            parentalRatingLabel.hidden=YES;
            
            frame=label6.frame;
            frame.origin.y=frame.origin.y-40;
            label6.frame=frame;
            
            jewelView.image=[UIImage imageNamed:@"jewel_tv.9.png"];
            frame=jewelView.frame;
            frame.size.height=coverHeight;
            jewelView.frame=frame;
            
            frame=coverView.frame;
            frame.origin.x=11;
            frame.origin.y=17;
            frame.size.width=297;
            frame.size.height=167;
            coverView.frame=frame;
            directorLabel.text=[[item objectForKey:@"showtitle"] length]==0 ? @"-" : [item objectForKey:@"showtitle"];
            genreLabel.text=[[item objectForKey:@"firstaired"] length]==0 ? @"-" : [item objectForKey:@"firstaired"];
            runtimeLabel.text=[[item objectForKey:@"director"] length]==0 ? @"-" : [item objectForKey:@"director"];
            studioLabel.text=[[item objectForKey:@"writer"] length]==0 ? @"-" : [item objectForKey:@"writer"];
        }
        scrollViewDefaultHeight=scrollViewDefaultHeight - deltaY - shiftY;
        [self moveLabel:[NSArray arrayWithObjects:starsView, voteLabel, numVotesLabel, label1, label2, label3, label4, label5, label6, directorLabel, genreLabel, runtimeLabel, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel, nil] posY:deltaY];
        
        
        
        label2.text=@"FIRST AIRED";
        label5.text=@"SUMMARY";
        
        frame=starsView.frame;
        frame.origin.x=frame.origin.x+29;
        starsView.frame=frame;
        
        frame=voteLabel.frame;
        frame.origin.x=frame.origin.x+29;
        voteLabel.frame=frame;
        
        
        
        
    }
    else if ([[item objectForKey:@"family"] isEqualToString:@"albumid"]){
        int shiftY=40;
        int coverHeight=290;
        scrollViewDefaultHeight=600;
        [self moveLabel:[NSArray arrayWithObjects:starsView, voteLabel, numVotesLabel, label1, label2, label3, label4, label5, label6, directorLabel, genreLabel, runtimeLabel, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel, nil] posY:40];
        jewelView.hidden=NO;
        int deltaY=jewelView.frame.size.height - coverHeight;
        label1.text=@"ARTIST";
        label2.text=@"YEAR";
        label3.text=@"GENRE";
        label4.text=@"ALBUM LABEL";
        label5.text=@"DESCRIPTION";
        label6.text=@"";
        
        starsView.hidden=YES;
        voteLabel.hidden=YES;
        numVotesLabel.hidden=YES;

        parentalRatingLabelUp.hidden=YES;
        parentalRatingLabel.hidden=YES;
        
        CGRect frame=label6.frame;
        frame.origin.y=frame.origin.y-40;
        label6.frame=frame;
        
        jewelView.image=[UIImage imageNamed:@"jewel_cd.9.png"];
        frame=jewelView.frame;
        frame.size.height=coverHeight;
        jewelView.frame=frame;
        
        frame=coverView.frame;
        frame.origin.x=42;
        frame.origin.y=22;
        frame.size.width=256;
        frame.size.height=256;
        coverView.frame=frame;
        directorLabel.text=[[item objectForKey:@"artist"] length]==0 ? @"-" : [item objectForKey:@"artist"];
        genreLabel.text=[[item objectForKey:@"year"] length]==0 ? @"-" : [item objectForKey:@"year"];
        runtimeLabel.text=[[item objectForKey:@"genre"] length]==0 ? @"-" : [item objectForKey:@"genre"];
        studioLabel.text=[[item objectForKey:@"writer"] length]==0 ? @"-" : [item objectForKey:@"writer"];
        scrollViewDefaultHeight=scrollViewDefaultHeight - deltaY - shiftY;
        [self moveLabel:[NSArray arrayWithObjects:starsView, voteLabel, numVotesLabel, label1, label2, label3, label4, label5, label6, directorLabel, genreLabel, runtimeLabel, studioLabel, summaryLabel, parentalRatingLabelUp, parentalRatingLabel, nil] posY:deltaY];
        
//        frame=starsView.frame;
//        frame.origin.x=frame.origin.x+29;
//        starsView.frame=frame;
//        
//        frame=voteLabel.frame;
//        frame.origin.x=frame.origin.x+29;
//        voteLabel.frame=frame;
        
    }
    else {
        directorLabel.text=[[item objectForKey:@"director"] length]==0 ? @"-" : [item objectForKey:@"director"];
        genreLabel.text=[[item objectForKey:@"genre"] length]==0 ? @"-" : [item objectForKey:@"genre"];
        runtimeLabel.text=[[item objectForKey:@"runtime"] length]==0 ? @"-" : [item objectForKey:@"runtime"];
        studioLabel.text=[[item objectForKey:@"studio"] length]==0 ? @"-" : [item objectForKey:@"studio"];
    }
    NSString *thumbnailPath=[item objectForKey:@"thumbnail"];
    NSURL *imageUrl = [NSURL URLWithString: thumbnailPath];
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    UIImage *cachedImage = [manager imageWithURL:imageUrl];
    if (cachedImage){
        coverView.image=cachedImage;
    }
    else{
        [coverView setImageWithURL:[NSURL URLWithString:thumbnailPath] placeholderImage:[UIImage imageNamed:@""]];
    }
    
    NSString *fanartPath=[item objectForKey:@"fanart"];    
    NSURL *fanartUrl = [NSURL URLWithString: fanartPath];
    UIImage *cachedFanart = [manager imageWithURL:fanartUrl];
    if (cachedFanart){
        fanartView.image=cachedFanart;
    }
    else{
        [fanartView setImageWithURL:[NSURL URLWithString:fanartPath] placeholderImage:[UIImage imageNamed:@""]];
    }

   [self alphaImage:fanartView AnimDuration:1.5 Alpha:0.1f];// cool

    voteLabel.text=[[item objectForKey:@"rating"] length]==0 ? @"N.A." : [item objectForKey:@"rating"];
    starsView.image=[UIImage imageNamed:[NSString stringWithFormat:@"stars_%.0f.png", round([[item objectForKey:@"rating"] doubleValue])]];
    
    NSString *numVotes=[[item objectForKey:@"votes"] length]==0 ? @"" : [item objectForKey:@"votes"];
    if ([numVotes length]!=0){
        NSString *numVotesPlus=([numVotes isEqualToString:@"1"]) ? @"vote" : @"votes";
        numVotesLabel.text=[NSString stringWithFormat:@"(%@ %@)",numVotes, numVotesPlus];
    }
    
    CGRect frame=summaryLabel.frame;
    frame.size.height=2000;
    summaryLabel.frame=frame;
    summaryLabel.text=[[item objectForKey:@"plot"] length]==0 ? @"-" : [item objectForKey:@"plot"];
    if ([[item objectForKey:@"family"] isEqualToString:@"albumid"]){
        summaryLabel.text=[[item objectForKey:@"description"] length]==0 ? @"-" : [item objectForKey:@"description"];

    }
    [summaryLabel sizeToFit];
    
    frame=parentalRatingLabel.frame;
    frame.origin.y=frame.origin.y+summaryLabel.frame.size.height-20;
    parentalRatingLabel.frame=frame;
    
    frame=parentalRatingLabelUp.frame;
    frame.origin.y=frame.origin.y+summaryLabel.frame.size.height-20;
    parentalRatingLabelUp.frame=frame;
    
    frame=parentalRatingLabel.frame;
    frame.size.height=2000;
    parentalRatingLabel.frame=frame;
    parentalRatingLabel.text=[[item objectForKey:@"mpaa"] length]==0 ? @"-" : [item objectForKey:@"mpaa"];
    [parentalRatingLabel sizeToFit];
    
    frame=label6.frame;
    frame.origin.y=frame.origin.y+summaryLabel.frame.size.height+parentalRatingLabel.frame.size.height-40;
    label6.frame=frame;
    
    int startY=scrollViewDefaultHeight+summaryLabel.frame.size.height+parentalRatingLabel.frame.size.height;
    
    if (![[item objectForKey:@"family"] isEqualToString:@"albumid"]){// TRANSFORM IN SHOW_CAST BOOLEAN
        NSArray *cast=[item objectForKey:@"cast"];
        GlobalData *obj=[GlobalData getInstance]; 
        NSString *serverURL=[NSString stringWithFormat:@"%@:%@/vfs/", obj.serverIP, obj.serverPort];
        int castWidth=50;
        int castHeight=50;
        int offsetX=10;
        for (NSDictionary *actor in cast){
            NSString *stringURL = [NSString stringWithFormat:@"http://%@%@", serverURL, [actor objectForKey:@"thumbnail"]];
            UIImageView *actorImage=[[UIImageView alloc] initWithFrame:CGRectMake(offsetX, startY, castWidth, castHeight)];
            [actorImage setClipsToBounds:YES];
            [actorImage setContentMode:UIViewContentModeScaleAspectFill];
            [actorImage setImageWithURL:[NSURL URLWithString:stringURL] placeholderImage:[UIImage imageNamed:@"person.png"]];
            [actorImage.layer setBorderColor: [[UIColor whiteColor] CGColor]];
            [actorImage.layer setBorderWidth: 1.0];
            
            [scrollView addSubview:actorImage];
            
            UILabel *actorName=[[UILabel alloc] initWithFrame:CGRectMake(castWidth+offsetX+10, startY, 320 - (castWidth+offsetX+20) , 16)];
            actorName.text=[actor objectForKey:@"name"];
            [actorName setFont:[UIFont fontWithName:@"Optima-Regular" size:14]];
            [actorName setBackgroundColor:[UIColor clearColor]];
            [actorName setTextColor:[UIColor whiteColor]];
            [scrollView addSubview:actorName];
            
            UILabel *actorRole=[[UILabel alloc] initWithFrame:CGRectMake(castWidth+offsetX+10, startY+20, 320 - (castWidth+offsetX+20) , 16)];
            actorRole.text=@"";
            if ([[actor objectForKey:@"role"] length]!=0)
                actorRole.text=[NSString stringWithFormat:@"as %@", [actor objectForKey:@"role"]];
            
            [actorRole setFont:[UIFont fontWithName:@"Optima-Regular" size:14]];
            [actorRole setBackgroundColor:[UIColor clearColor]];
            [actorRole setTextColor:[UIColor grayColor]];
            [scrollView addSubview:actorRole];
            
            startY=startY+castHeight+10;
        }
        if ([cast count]==0){
            UILabel *noCast=[[UILabel alloc] initWithFrame:CGRectMake(offsetX, startY-4, 297 , 20)];
            noCast.text=@"-";
            [noCast setFont:[UIFont fontWithName:@"Optima-Regular" size:14]];
            [noCast setBackgroundColor:[UIColor clearColor]];
            [noCast setTextColor:[UIColor whiteColor]];
            [scrollView addSubview:noCast];
            startY+=20;
        }
    }
    scrollView.contentSize=CGSizeMake(320, startY);

//    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimer) userInfo:nil repeats:YES];
}

//- (void) onTimer {
//    
//    // Updates the variable h, adding 100 (put your own value here!)
//    h += 10; 
//    
//    //This makes the scrollView scroll to the desired position  
//    scrollView.contentOffset = CGPointMake(0, h);  
//    
//}

- (void) scrollViewDidScroll: (UIScrollView *) theScrollView{
    if (arrow_continue_down.alpha && theScrollView.contentOffset.y>40){
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:1];
        arrow_continue_down.alpha=0;
        [UIView commitAnimations];
    }
    else if (arrow_continue_down.alpha==0 && theScrollView.contentOffset.y<40){
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:1];
        arrow_continue_down.alpha=0.5;
        [UIView commitAnimations];
    }
}

-(void)alphaImage:(UIImageView *)image AnimDuration:(float)seconds Alpha:(float)alphavalue{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:seconds];
	image.alpha = alphavalue;
    [UIView commitAnimations];
}

#pragma mark - Gestures
- (void)handleSwipeFromLeft:(id)sender {
    [self showNowPlaying];
}

# pragma  mark - JSON Data

-(void)addQueue{
    self.navigationItem.rightBarButtonItem.enabled=NO;
    [activityIndicatorView startAnimating];
    NSDictionary *item = self.detailItem;
    [jsonRPC callMethod:@"Playlist.Add" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[item objectForKey:@"playlistid"], @"playlistid", [NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:[item objectForKey:@"family"]], [item objectForKey:@"family"], nil], @"item", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error!=nil || methodError!=nil){
//            NSLog(@" errore %@",methodError);
        }
        [activityIndicatorView stopAnimating];
        self.navigationItem.rightBarButtonItem.enabled=YES;
    }];
}

-(void)addPlayback{
    self.navigationItem.rightBarButtonItem.enabled=NO;
    [activityIndicatorView startAnimating];
    NSDictionary *item = self.detailItem;
    [jsonRPC callMethod:@"Playlist.Clear" withParameters:[NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:@"playlistid"], @"playlistid", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
        if (error==nil && methodError==nil){
            [jsonRPC callMethod:@"Playlist.Add" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[item objectForKey:@"playlistid"], @"playlistid", [NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:[item objectForKey:@"family"]], [item objectForKey:@"family"], nil], @"item", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                if (error==nil && methodError==nil){
                    [jsonRPC callMethod:@"Player.Open" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys: [item objectForKey:@"playlistid"], @"playlistid", [NSNumber numberWithInt: 0], @"position", nil], @"item", nil] onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
                        if (error==nil && methodError==nil){
                            [activityIndicatorView stopAnimating];
                            [self showNowPlaying];
                        }
                        else {
                            [activityIndicatorView stopAnimating];
                            self.navigationItem.rightBarButtonItem.enabled=YES;
//                            NSLog(@"terzo errore %@",methodError);
                        }
                    }];
                }
                else {
                    [activityIndicatorView stopAnimating];
//                    NSLog(@"secondo errore %@",methodError);
                    self.navigationItem.rightBarButtonItem.enabled=YES;

                }
            }];
        }
        else {
            [activityIndicatorView stopAnimating];
//            NSLog(@"ERRORE %@", methodError);
            self.navigationItem.rightBarButtonItem.enabled=YES;
        }
    }];
}
# pragma  mark - Gestures
- (void)handleSwipeFromRight:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

# pragma  mark - Lyfe Cycle

- (void)setDetailItem:(id)newDetailItem{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        // Update the view.
        [self configureView];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    alreadyPush=NO;
}

- (void)viewDidLoad{
    GlobalData *obj=[GlobalData getInstance];     
    [[SDImageCache sharedImageCache] clearMemory];
    //    [manager cancelForDelegate:self];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, obj.serverPass, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [self createInfo];
    
    [super viewDidLoad];
}

- (void)viewDidUnload{
    [super viewDidUnload];
}

-(void)dealloc{
    nowPlaying=nil;
    jsonRPC=nil;
    fanartView=nil;
    coverView=nil;
    scrollView=nil;
//    NSLog(@"eccomi");
    
//    self.detailItem = nil;
//    jsonRPC=nil;
//    [richResults removeAllObjects];
//    richResults=nil;
//    [self.sections removeAllObjects];
//    self.sections=nil;
//    dataList=nil;
//    jsonCell=nil;
//    activityIndicatorView=nil;  
//    manager=nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
//    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
//}

@end
