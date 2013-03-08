//
//  ActorCell.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 8/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ActorCell : UITableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier castWidth:(int)castWidth castHeight:(int)castHeight size:(int)size castFontSize:(int)castFontSize;

@property (nonatomic, readonly) UIImageView *actorThumbnail;
@property (nonatomic, readonly) UILabel *actorName;
@property (nonatomic, readonly) UILabel *actorRole;

@end
