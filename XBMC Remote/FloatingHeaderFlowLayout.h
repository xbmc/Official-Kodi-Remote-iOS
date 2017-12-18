//
//  FloatingHeaderFlowLayout.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 28/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FloatingHeaderFlowLayout : UICollectionViewFlowLayout {
    CGFloat searchBarHeight;
}

-(void)setSearchBarHeight:(CGFloat)height;

@end
