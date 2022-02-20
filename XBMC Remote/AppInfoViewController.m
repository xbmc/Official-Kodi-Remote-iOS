//
//  AppInfoViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 16/4/12.
//  Copyright (c) 2012 joethefox inc.All rights reserved.
//

#import "AppInfoViewController.h"
#import "AppDelegate.h"
#import "Utilities.h"

@interface AppInfoViewController ()

@end

@implementation UITextView (DisableCopyPaste)

- (BOOL)canBecomeFirstResponder {
    return NO;
}

@end

@implementation AppInfoViewController

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//    }
    return self;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    UITouch *touch = [touches anyObject];
    if ([touch tapCount] > 10 && touch.view == creditsSign && creditsMask.hidden) {
        creditsMask.hidden = NO;
        if (audioPlayer == nil) {
            NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle]
                                                 pathForResource:@"sign"
                                                 ofType:@"mp3"]];
            NSError *error;
            audioPlayer = [[AVAudioPlayer alloc]
                           initWithContentsOfURL:url
                           error:&error];
            if (!error) {
                audioPlayer.delegate = self;
                [audioPlayer prepareToPlay];
            }
        }
        audioPlayer.currentTime = 0;
        [audioPlayer play];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer*)player successfully:(BOOL)flag {
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(setActive:withOptions:error:)]) {
        NSError *err;
        [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&err];
    }
    creditsMask.hidden = YES;
}

- (BOOL)canBecomeFirstResponder {
    return NO;
}

- (IBAction)CloseView {
    [audioPlayer stop];
    audioPlayer = nil;
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(setActive:withOptions:error:)]) {
        NSError *err;
        [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&err];
    }
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    creditsMask.hidden = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    creditsMask.hidden = YES;
    [audioPlayer stop];
    audioPlayer.currentTime = 0;
    audioPlayer = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = 0;
    appName.text = LOCALIZED_STR(@"Official XBMC Remote\nfor iOS");
    appVersion.text = [Utilities getAppVersionString];
    appDescription.text = LOCALIZED_STR(@"Official XBMC Remote app uses art coming from http://fanart.tv, download and execute the \"artwork downloader\" XBMC add-on to unlock the beauty of additional artwork!\n\nXBMC logo, Zappy mascot and Official XBMC Remote icons are property of XBMC\nhttp://www.xbmc.org/contribute");
    appGreeting.text = LOCALIZED_STR(@"enjoy!");
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
