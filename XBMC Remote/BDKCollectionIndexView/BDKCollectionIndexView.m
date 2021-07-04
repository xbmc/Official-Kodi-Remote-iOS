#import "BDKCollectionIndexView.h"
#import "Utilities.h"
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

#define DEFAULT_ALPHA 0.3
#define INDEX_HEIGHT_IPHONE 14  // tested for iPod and Xs and 12 Pro and 6s (10.x)
#define INDEX_HEIGHT_IPAD 24 // tested for iPad Pro 12.9" and iPad Pro 9.7" and iPad 8G and iPad 5G

@interface BDKCollectionIndexView ()

/** A component that shows up under the letters to indicate the view is handling a touch or a pan.
 */
@property (strong, nonatomic) UIView *touchStatusView;

/** The collection of label subviews that are displayed (one for each index title).
 */
@property (strong, nonatomic) NSArray *indexLabels;

/** A gesture recognizer that handles panning.
 */
//@property (strong, nonatomic) UIPanGestureRecognizer *panner;

/** A gesture recognizer that handles tapping.
 */
@property (strong, nonatomic) UILongPressGestureRecognizer *tapper;

/** A gesture recognizer that handles panning.
 */
@property (readonly) CGFloat theDimension;

/** Handles events sent by the long press gesture recognizer.
 *  @param recognizer the sender of the event; usually a UILongPressGestureRecognizer.
 */
- (void)handleTap:(UILongPressGestureRecognizer*)recognizer;

/** Handles logic for determining which label is under a given touch point, and sets `currentIndex` accordingly.
 *  @param point the touch point.
 */
- (void)setNewIndexForPoint:(CGPoint)point;

/** Handles setting the alpha component level for the background color on the `touchStatusView`.
 *  @param flag if `YES`, the `touchStatusView` is set to be visible and dark-ish.
 */
- (void)setBackgroundVisibility:(BOOL)flag;

@end

@implementation BDKCollectionIndexView

@synthesize currentIndex = _currentIndex, direction = _direction, theDimension = _theDimension;

+ (id)indexViewWithFrame:(CGRect)frame indexTitles:(NSArray*)indexTitles {
    return [[self alloc] initWithFrame:frame indexTitles:indexTitles];
}

- (id)initWithFrame:(CGRect)frame indexTitles:(NSArray*)indexTitles {
    if (self = [super initWithFrame:frame]) {
        if (CGRectGetWidth(frame) > CGRectGetHeight(frame))
            _direction = BDKCollectionIndexViewDirectionHorizontal;
        else _direction = BDKCollectionIndexViewDirectionVertical;

        _currentIndex = -1;
        _endPadding = 16;
        _labelPadding = 4;

        _tapper = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [_tapper setMinimumPressDuration:0];
        
        [self addGestureRecognizer:_tapper];

        [self addSubview:self.touchStatusView];

        self.indexTitles = indexTitles;
        
        self.alpha = DEFAULT_ALPHA;
    }

    return self;
}

- (void)layoutSubviews {

    CGFloat maxLength = 0.0;
    CGFloat cumulativeLength = 0.0;
    switch (_direction) {
        case BDKCollectionIndexViewDirectionHorizontal:
            _theDimension = CGRectGetHeight(self.frame);
            maxLength = CGRectGetWidth(self.frame) - (self.endPadding * 2);
            cumulativeLength = self.endPadding;
            break;
        case BDKCollectionIndexViewDirectionVertical:
            _theDimension = CGRectGetWidth(self.frame);
            if (IS_IPHONE) {
                maxLength = self.indexLabels.count * INDEX_HEIGHT_IPHONE;
            }
            else {
                maxLength = self.indexLabels.count * INDEX_HEIGHT_IPAD;
            }
            cumulativeLength = (CGRectGetHeight(self.frame) - maxLength)/2;
            break;
    }

    self.touchStatusView.frame = CGRectInset(self.bounds, 2, -2);
//    self.touchStatusView.layer.cornerRadius = floorf(self.theDimension / 2.75);
    self.touchStatusView.layer.cornerRadius = 0;

    CGSize labelSize = CGSizeMake(self.theDimension, self.theDimension);

    CGFloat otherDimension = floorf(maxLength / self.indexLabels.count);
    for (UILabel *label in self.indexLabels) {
        switch (self.direction) {
            case BDKCollectionIndexViewDirectionHorizontal:
                labelSize.width = otherDimension;
                label.frame = (CGRect) {{cumulativeLength, 0}, labelSize};
                cumulativeLength += CGRectGetWidth(label.frame);
                break;
            case BDKCollectionIndexViewDirectionVertical:
                labelSize.height = otherDimension;
                label.frame = (CGRect) {{self.labelPadding, cumulativeLength + 4}, labelSize};
                cumulativeLength += CGRectGetHeight(label.frame);
                break;
        }
    }
}

#pragma mark - Properties

- (UIView*)touchStatusView {
    if (_touchStatusView) {
        return _touchStatusView;
    }
    _touchStatusView = [[UIView alloc] initWithFrame:CGRectInset(self.bounds, 2, 2)];
    _touchStatusView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    _touchStatusView.layer.cornerRadius = 0;
    _touchStatusView.layer.masksToBounds = YES;
    return _touchStatusView;
}

- (void)setIndexTitles:(NSArray*)indexTitles {
    if (_indexTitles == indexTitles) {
        return;
    }
    _indexTitles = indexTitles;
    [self.indexLabels makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self buildIndexLabels];
}

- (NSString*)currentIndexTitle {
    return self.indexTitles[self.currentIndex];
}

- (void)setEndPadding:(CGFloat)endPadding {
    if (_endPadding == endPadding) {
        return;
    }
    _endPadding = endPadding;

    [self.indexTitles makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self buildIndexLabels];
}

#pragma mark - Subviews

- (void)buildIndexLabels {

    NSMutableArray *workingLabels = [NSMutableArray arrayWithCapacity:self.indexTitles.count];
    for (NSString *indexTitle in self.indexTitles) {
        if (![indexTitle isEqualToString:@"🔍"]) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.text = indexTitle;
            label.font = [UIFont boldSystemFontOfSize:11];
            label.minimumScaleFactor = 11.0/11.0;
            label.adjustsFontSizeToFitWidth = YES;
            label.backgroundColor = [UIColor clearColor];
            label.textColor = [UIColor systemBlueColor];
            label.shadowColor = [UIColor clearColor];
            label.shadowOffset = CGSizeMake(0, 1);
            label.textAlignment = NSTextAlignmentCenter;
            [self addSubview:label];
            [workingLabels addObject:label];
        }
    }
    self.indexLabels = [NSArray arrayWithArray:workingLabels];
}

- (void)setNewIndexForPoint:(CGPoint)point {
    for (UILabel *view in self.indexLabels) {
        if (CGRectContainsPoint(view.frame, point)) {
            NSUInteger newIndex = [self.indexTitles indexOfObject:view.text];
            if (newIndex != _currentIndex) {
                _currentIndex = newIndex;
                [self sendActionsForControlEvents:UIControlEventValueChanged];
            }
        }
    }
}

- (void)setBackgroundVisibility:(BOOL)flag {
    CGFloat alpha = flag ? 0.5 : 0;
    self.touchStatusView.backgroundColor = [Utilities getGrayColor:0 alpha:alpha];
}

#pragma mark - Gestures

- (void)handleTap:(UILongPressGestureRecognizer*)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self setBackgroundVisibility:NO];
        self.alpha = DEFAULT_ALPHA;
        [[NSNotificationCenter defaultCenter] postNotificationName: @"BDKCollectionIndexViewGestureRecognizerStateEnded" object: nil];
    }
    else {
        [self setBackgroundVisibility:YES];
        self.alpha = 1.0;
        [[NSNotificationCenter defaultCenter] postNotificationName: @"BDKCollectionIndexViewGestureRecognizerStateBegin" object: nil];
    }
    [self setNewIndexForPoint:[recognizer locationInView:self]];
}

@end
