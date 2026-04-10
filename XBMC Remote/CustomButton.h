//
//  CustomButton.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 8/4/14.
//  Copyright (c) 2014 joethefox inc. All rights reserved.
//

@import Foundation;

@interface CustomButton : NSObject

@property (nonatomic, strong) NSMutableArray *buttons;

- (void)saveData;

@end
