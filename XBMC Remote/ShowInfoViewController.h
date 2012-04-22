//
//  ShowInfoViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 27/3/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSJSONRPC.h"
//
@class NowPlaying;

@interface ShowInfoViewController : UIViewController <UIScrollViewDelegate>{
    IBOutlet UIImageView *coverView;
    IBOutlet UIImageView *starsView;
    IBOutlet UILabel *voteLabel;
    IBOutlet UILabel *numVotesLabel;
    IBOutlet UIScrollView *scrollView;
    DSJSONRPC *jsonRPC;
    IBOutlet UIActivityIndicatorView *activityIndicatorView;
    IBOutlet UILabel *directorLabel;
    IBOutlet UILabel *genreLabel;
    IBOutlet UILabel *runtimeLabel;
    IBOutlet UILabel *studioLabel;
    IBOutlet UILabel *summaryLabel;
    IBOutlet UILabel *parentalRatingLabelUp;
    IBOutlet UILabel *parentalRatingLabel;
    
    IBOutlet UILabel *label1;

    IBOutlet UILabel *label2;

    IBOutlet UILabel *label3;

    IBOutlet UILabel *label4;

    IBOutlet UILabel *label5;

    IBOutlet UILabel *label6;


    IBOutlet UIButton *arrow_continue_down;
    IBOutlet UIImageView *jewelView;
    IBOutlet UIImageView *fanartView;

    BOOL alreadyPush;

}

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) NowPlaying *nowPlaying;

@end
