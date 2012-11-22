//
//  PlayFileViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 4/4/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSJSONRPC.h"

@interface PlayFileViewController : UIViewController {
    IBOutlet UIWebView *webPlayView;
    DSJSONRPC *jsonRPC;
}

@property (strong, nonatomic) id detailItem;

@end
