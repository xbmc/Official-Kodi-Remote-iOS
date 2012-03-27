//
//  RemoteController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 24/3/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSJSONRPC.h"
#import "VolumeSliderView.h"

@interface RemoteController : UIViewController{
    DSJSONRPC *jsonRPC;
    VolumeSliderView *volumeSliderView;
}

- (IBAction)startVibrate:(id)sender;

@property (strong, nonatomic) id detailItem;

@end
