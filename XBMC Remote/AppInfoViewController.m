//
//  AppInfoViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 16/4/12.
//  Copyright (c) 2012 joethefox inc.All rights reserved.
//

#import "AppInfoViewController.h"
#import "AppDelegate.h"

@interface AppInfoViewController ()

@end

@implementation UITextView (DisableCopyPaste)

- (BOOL)canBecomeFirstResponder{
    return NO;
}

@end

@implementation AppInfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//    }
    return self;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event{
    UITouch *touch = [touches  anyObject];
    if ([touch tapCount] > 15 && touch.view==creditsSign && creditsMask.hidden){
        creditsMask.hidden = NO;
        if (audioPlayer == nil){
            NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle]
                                                 pathForResource:@"sign"
                                                 ofType:@"mp3"]];
            NSError *error;
            audioPlayer = [[AVAudioPlayer alloc]
                           initWithContentsOfURL:url
                           error:&error];
            if (!error){
                audioPlayer.delegate = self;
                [audioPlayer prepareToPlay];
            }
        }
        [audioPlayer setCurrentTime:0];
        [audioPlayer play];
    }
}

- (BOOL)canBecomeFirstResponder {
    return NO;
}

-(IBAction)CloseView{
    [audioPlayer stop];
    audioPlayer = nil;
    [self dismissModalViewControllerAnimated:YES];
}

-(void)viewWillAppear:(BOOL)animated{
    creditsMask.hidden = YES;
}

-(void)viewDidDisappear:(BOOL)animated{
    creditsMask.hidden = YES;
    [audioPlayer stop];
    [audioPlayer setCurrentTime:0];
    audioPlayer = nil;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")){
        self.edgesForExtendedLayout = 0;
    }
    [appName setText:NSLocalizedString(@"Official XBMC Remote\nfor iOS", nil)];
    [appVersion setText:[NSString stringWithFormat:@"v%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]];
    [appDescription setText:NSLocalizedString(@"Official XBMC Remote app uses art coming from http://fanart.tv, download and execute the \"artwork downloader\" XBMC add-on to unlock the beauty of additional artwork!\n\nXBMC logo, Zappy mascot and Official XBMC Remote icons are property of XBMC\nhttp://www.xbmc.org/contribute", nil)];
    [appGreeting setText:NSLocalizedString(@"enjoy!", nil)];
}

- (void)viewDidUnload{
    creditsMask = nil;
    creditsSign = nil;
    audioPlayer = nil;
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
