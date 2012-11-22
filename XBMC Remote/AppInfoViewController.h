//
//  AppInfoViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 16/4/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface AppInfoViewController : UIViewController <AVAudioPlayerDelegate>{
    AVAudioPlayer *audioPlayer;
    IBOutlet UIScrollView *creditsScrollView;
    __weak IBOutlet UIImageView *creditsMask;
    __weak IBOutlet UIImageView *creditsSign;
}

@end
