#import "BDKCollectionIndexView.h"

#import <QuartzCore/QuartzCore.h>

#define DEFAULT_ALPHA 0.3f

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
- (void)handleTap:(UILongPressGestureRecognizer *)recognizer;

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

+ (id)indexViewWithFrame:(CGRect)frame indexTitles:(NSArray *)indexTitles {
    return [[self alloc] initWithFrame:frame indexTitles:indexTitles];
}

- (id)initWithFrame:(CGRect)frame indexTitles:(NSArray *)indexTitles {
    if (self = [super initWithFrame:frame]) {
        if (CGRectGetWidth(frame) > CGRectGetHeight(frame))
            _direction = BDKCollectionIndexViewDirectionHorizontal;
        else _direction = BDKCollectionIndexViewDirectionVertical;

        _currentIndex = 0;
        _endPadding = 2;

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
    switch (_direction) {
        case BDKCollectionIndexViewDirectionHorizontal:
            _theDimension = CGRectGetHeight(self.frame);
            maxLength = CGRectGetWidth(self.frame) - (self.endPadding * 2);
            break;
        case BDKCollectionIndexViewDirectionVertical:
            _theDimension = CGRectGetWidth(self.frame);
            maxLength = CGRectGetHeight(self.frame);
            break;
    }

    self.touchStatusView.frame = CGRectInset(self.bounds, 2, 2);
    self.touchStatusView.layer.cornerRadius = floorf(self.theDimension / 2.75);

    CGFloat cumulativeLength = self.endPadding;
    CGSize labelSize = CGSizeMake(self.theDimension, self.theDimension);

    CGFloat otherDimension = floorf(maxLength / self.indexLabels.count);
    for (UILabel *label in self.indexLabels) {
        switch (self.direction) {
            case BDKCollectionIndexViewDirectionHorizontal:
                labelSize.width = otherDimension;
                label.frame = (CGRect){ { cumulativeLength, 0 }, labelSize };
                cumulativeLength += CGRectGetWidth(label.frame);
                break;
            case BDKCollectionIndexViewDirectionVertical:
                labelSize.height = otherDimension;
                label.frame = (CGRect){ { 0, cumulativeLength + 4 }, labelSize };
                cumulativeLength += CGRectGetHeight(label.frame);
                break;
        }
    }
}

#pragma mark - Properties

- (UIView *)touchStatusView {
    if (_touchStatusView) return _touchStatusView;
    _touchStatusView = [[UIView alloc] initWithFrame:CGRectInset(self.bounds, 2, 2)];
    _touchStatusView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    _touchStatusView.layer.cornerRadius = self.theDimension / 2;
    _touchStatusView.layer.masksToBounds = YES;
    return _touchStatusView;
}

- (void)setIndexTitles:(NSArray *)indexTitles {
    if (_indexTitles == indexTitles) return;
    _indexTitles = indexTitles;
    [self.indexLabels makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self buildIndexLabels];
}

- (NSString *)currentIndexTitle {
    return self.indexTitles[self.currentIndex];
}

- (void)setEndPadding:(CGFloat)endPadding {
    if (_endPadding == endPadding) return;
    _endPadding = endPadding;

    [self.indexTitles makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self buildIndexLabels];
}

#pragma mark - Subviews

- (void)buildIndexLabels {

    NSMutableArray *workingLabels = [NSMutableArray arrayWithCapacity:self.indexTitles.count];
    for (NSString *indexTitle in self.indexTitles) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.text = indexTitle;
        label.font = [UIFont boldSystemFontOfSize:11];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor colorWithRed:65.0f/255.0f green:71.0f/255.0f blue:77.0/255.0f alpha:1.0];
        label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:label];
        [workingLabels addObject:label];
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
    CGFloat alpha = flag ? 0.65 : 0;
    self.touchStatusView.backgroundColor = [UIColor colorWithRed:125.0f/255.0f green:132.0f/255.0f blue:135.0f/255.0f alpha:alpha];
}

#pragma mark - Gestures

- (void)handleTap:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded){
        [self setBackgroundVisibility:FALSE];
        self.alpha = DEFAULT_ALPHA;
    }
    else{
        [self setBackgroundVisibility:TRUE];
        self.alpha = 1.0f;
    }
    [self setNewIndexForPoint:[recognizer locationInView:self]];
}

@end