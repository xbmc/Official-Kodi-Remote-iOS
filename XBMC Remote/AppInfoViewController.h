//
//  AppInfoViewController.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 16/4/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppInfoViewController : UIViewController {
    __weak IBOutlet UILabel *appName;
    __weak IBOutlet UILabel *appVersion;
    __weak IBOutlet UITextView *appDescription;
}

@end
