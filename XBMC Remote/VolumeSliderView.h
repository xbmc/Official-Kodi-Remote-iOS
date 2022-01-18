//
//  VolumeSliderView.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 27/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSJSONRPC.h"

@interface VolumeSliderView : UIView {
    IBOutlet UIView *volumeView;
    IBOutlet UISlider *volumeSlider;
    IBOutlet UILabel *volumeLabel;
    IBOutlet UIButton *muteButton;
    IBOutlet UIButton *plusButton;
    IBOutlet UIButton *minusButton;
    BOOL isMuted;
    UIColor *muteIconColor;
}

- (id)initWithFrame:(CGRect)frame leftAnchor:(CGFloat)leftAnchor;

- (IBAction)slideVolume:(id)sender;

- (void)startTimer;

- (void)stopTimer;

@property (nonatomic, strong) NSTimer* timer;

@property (nonatomic, strong) NSTimer* holdVolumeTimer;


@end
