//
//  WebTwitterViewController.h
//  inLombardia
//
//  Created by Giovanni Messina on 26/2/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController <UIActionSheetDelegate>{
    IBOutlet UIWebView *Twitterweb;
    UIActivityIndicatorView *TwitterwebLoadIndicator;
    IBOutlet UILabel *tweetURL;
    IBOutlet UIBarButtonItem *webBackButton;
    IBOutlet UIBarButtonItem *webForwardButton;
    IBOutlet UIBarButtonItem *webActionButton;
    UILabel *topNavigationLabel;
}

@property (nonatomic, retain) NSURLRequest *urlRequest;


@end
