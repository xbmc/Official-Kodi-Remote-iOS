# BDKCollectionIndexView

> An index-title-scrubber-bar, for use with a `UICollectionView` (or even a `PSTCollectionView`). Gives a collection view the index title bar for `-sectionIndexTitles` that a `UITableView` gets for (almost) free. A huge thank you to @Yang from [this Stack Overflow post][so], which saved my bacon here.

## The problem

When you're using a `UITableView` and you define the `UITableViewDataSource` method `-sectionIndexTitlesForTableView:`, you get a sweet right-hand-side view for scrubbing through a long table view of fields, separated by sections. The titles are the names of the sections, by default (or at least letters based on the section names).

![UITableView with section index titles](http://s3.media.squarespace.com/production/1368321/16106782/_ULITs-nDV7k/TPRg9P_NtHI/AAAAAAAAEi8/gFWaiTD3Ygw/s1600/Apple%2BDefault%2BSection%2BTitle%2BViews.png)

Unfortunately, you get jack when you use a `UICollectionView` (or in my case, a [`PSTCollectionView`][pst]). There's no similar method defined on the `UICollectionViewDataSource` protocol. Stack Overflow to the rescue!

## The solution

This solution was presented by [Yang][ya] on [Stack Overflow][so]. Just roll your own! By subclassing `UIControl`, laying out a series of `UILabel` views in a vertical (or horizontal) fashion, and watching over them with a `UITapGestureRecognizer` and `UIPanGestureRecognizer`, you can get your own `sectionIndexTitles` bar thing. [I've written a gist that covers the header and implementation][gst] in full, based on Yang's proposal. I use it in a controller like so.

``` objective-c
@property (strong, nonatomic) BDKCollectionIndexView *indexView;

- (BDKCollectionIndexView *)indexView {
    if (_indexView) return _indexView;
    CGFloat indexWidth = 28;
    CGRect frame = CGRectMake(CGRectGetWidth(self.collectionView.frame) - indexWidth,
                              CGRectGetMinY(self.collectionView.frame),
                              indexWidth,
                              CGRectGetHeight(self.collectionView.frame));
    _indexView = [BDKCollectionIndexView indexViewWithFrame:frame indexTitles:@[]];
    _indexView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                   UIViewAutoresizingFlexibleLeftMargin);
    [_indexView addTarget:self
                   action:@selector(indexViewValueChanged:)
         forControlEvents:UIControlEventValueChanged];
    return _indexView;
}
```

When my collection view has loaded data in it, I set the `indexTitles` property of my `self.indexView` (I'm using a `NSFetchedResultsController` in a parent class that also serves a sub-class that manages a `UITableView`; go-go-gadget code reuse!).

``` objective-c
self.indexView.indexTitles = self.resultsController.sectionIndexTitles;
```

Then I merely watch for changes using this method (which was assigned to watch for `UIControlEventValueChanged`).

``` objective-c
- (void)indexViewValueChanged:(BDKCollectionIndexView *)sender {
    NSIndexPath *path = [NSIndexPath indexPathForItem:0 inSection:sender.currentIndex];

    // If you're using UICollectionView, substitute "PST" for "UI" and you're all set.
    [self.collectionView scrollToItemAtIndexPath:path
                                atScrollPosition:PSTCollectionViewScrollPositionTop
                                        animated:NO];

    // I bump the y-offset up by 45 points here to account for aligning the top of
    // the section header view with the top of the collectionView frame. It's
    // hardcoded, but you get the idea.
    self.collectionView.contentOffset = CGPointMake(self.collectionView.contentOffset.x,
                                                    self.collectionView.contentOffset.y - 45);
}
```

Again, big thanks to @Yang for [the solution on which this is based][so].

[so]:      http://stackoverflow.com/a/14443540/194869
[pst]:     https://github.com/steipete/PSTCollectionView
[ya]:      http://stackoverflow.com/users/45018/yang
[gst]:     https://gist.github.com/kreeger/4755877