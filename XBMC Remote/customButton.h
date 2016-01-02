//
//  customButton.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 8/4/14.
//  Copyright (c) 2014 joethefox inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface customButton : NSObject

@property (nonatomic, retain) NSMutableArray *buttons;

- (void)loadData;
- (void)saveData;

@end
