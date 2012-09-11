//
//  AppInfoViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 16/4/12.
//  Copyright (c) 2012 joethefox inc.All rights reserved.
//

#import "AppInfoViewController.h"

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
        [audioPlayer prepareToPlay];
        [audioPlayer play];
    }
}

- (BOOL)canBecomeFirstResponder {
    return NO;
}

-(IBAction)CloseView{
    [audioPlayer stop];
    [self dismissModalViewControllerAnimated:YES];
}

-(void)viewWillAppear:(BOOL)animated{
    creditsMask.hidden = YES;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle]
                                         pathForResource:@"sign"
                                         ofType:@"mp3"]];
    NSError *error;
    audioPlayer = [[AVAudioPlayer alloc]
                   initWithContentsOfURL:url
                   error:&error];
    if (!error){
        audioPlayer.delegate = self;
    }
}

- (void)viewDidUnload{
    creditsMask = nil;
    creditsSign = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
