
#import <UIKit/UIKit.h>

@interface jsonDataCell : UITableViewCell {
//    IBOutlet UILabel *urlLabel;
    IBOutlet UIImageView *urlImageView;
    IBOutlet UIImageView *lineSeparator;
//    IBOutlet UIActivityIndicatorView *queueActivity;
}

@property (nonatomic, readonly) UIImageView *urlImageView;
@property (nonatomic, readonly) UIImageView *lineSeparator;
//@property (nonatomic, readonly) UIActivityIndicatorView *queueActivity;

@end
