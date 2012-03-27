//
//  SettingsPanel.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 27/3/12.
//  Copyright (c) 2012 Korec s.r.l. All rights reserved.
//

#import "SettingsPanel.h"

@implementation SettingsPanel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSArray *nib = [[NSBundle mainBundle] 
						loadNibNamed:@"SettingsPanel"
						owner:self
						options:nil];
		
		self = [nib objectAtIndex:0];

    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
