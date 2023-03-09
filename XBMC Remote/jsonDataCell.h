
#import <UIKit/UIKit.h>

@interface jsonDataCell : UITableViewCell {
    IBOutlet UIImageView *urlImageView;
    IBOutlet UIImageView *lineSeparator;
}

@property (nonatomic, readonly) UIImageView *urlImageView;
@property (nonatomic, readonly) UIImageView *lineSeparator;

@end
