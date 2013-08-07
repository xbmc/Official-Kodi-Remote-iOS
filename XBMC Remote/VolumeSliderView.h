//
//  VolumeSliderView.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 27/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSJSONRPC.h"

@interface VolumeSliderView : UIView{
    IBOutlet UIView *volumeView;
    IBOutlet UISlider *volumeSlider;
    IBOutlet UILabel *volumeLabel;
    DSJSONRPC *jsonRPC;
    IBOutlet UIButton *plusButton;
    IBOutlet UIButton *minusButton;
    NSString *pg_thumb_name;
}

- (IBAction)slideVolume:(id)sender;

-(void)startTimer;

-(void)stopTimer;

@property (nonatomic, retain) NSTimer* timer;

@property (nonatomic, retain) NSTimer* holdVolumeTimer;


@end