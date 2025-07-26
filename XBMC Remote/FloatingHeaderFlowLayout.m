//
//  FloatingHeaderFlowLayout.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 28/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import "FloatingHeaderFlowLayout.h"

@implementation FloatingHeaderFlowLayout

- (NSArray*)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *layoutAttributes = [[super layoutAttributesForElementsInRect:rect] mutableCopy];
    
    NSMutableIndexSet *headersNeedingLayout = [NSMutableIndexSet indexSet];
    for (UICollectionViewLayoutAttributes *attributes in layoutAttributes) {
        if (attributes.representedElementCategory == UICollectionElementCategoryCell) {
            [headersNeedingLayout addIndex:attributes.indexPath.section];
        }
    }
    for (UICollectionViewLayoutAttributes *attributes in layoutAttributes) {
        if ([attributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
            [headersNeedingLayout removeIndex:attributes.indexPath.section];
        }
    }
    
    [headersNeedingLayout enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:idx];
        UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
        if (attributes != nil) {
            [layoutAttributes addObject:attributes];
        }
    }];
    
    for (UICollectionViewLayoutAttributes *attributes in layoutAttributes) {
        if ([attributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
            NSInteger section = attributes.indexPath.section;
            if (section >= self.collectionView.numberOfSections) {
                return layoutAttributes;
            }
            NSInteger numberOfItemsInSection = [self.collectionView numberOfItemsInSection:section];
            
            NSIndexPath *indexPathFirstItem = [NSIndexPath indexPathForItem:0 inSection:section];
            NSIndexPath *indexPathLastItem = [NSIndexPath indexPathForItem:MAX(0, (numberOfItemsInSection - 1)) inSection:section];
            
            UICollectionViewLayoutAttributes *attributesFirstItem = [self layoutAttributesForItemAtIndexPath:indexPathFirstItem];
            UICollectionViewLayoutAttributes *attributesLastItem = [self layoutAttributesForItemAtIndexPath:indexPathLastItem];
            
            CGRect frame = attributes.frame;
            CGFloat offset = self.collectionView.contentOffset.y + self.collectionView.contentInset.top;
            
            CGFloat minY = CGRectGetMinY(attributesFirstItem.frame) - frame.size.height;
            CGFloat maxY = CGRectGetMaxY(attributesLastItem.frame) - frame.size.height;
            CGFloat posY = MIN(MAX(offset, minY), maxY);
            frame.origin.y = posY;
            attributes.frame = frame;
            attributes.zIndex = 1024;
        }
    }
    return layoutAttributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBound {
    return YES;
}

- (CGSize)collectionViewContentSize {
    // Lets the collection view hide the searchbar on load, if there are only few items in the view
    CGSize size = [super collectionViewContentSize];
    size.height = MAX(size.height, self.collectionView.frame.size.height + searchBarHeight);
    return size;
}

- (void)setSearchBarHeight:(CGFloat)height {
    searchBarHeight = height;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
    // If searchbar is partially shown, snap to a position either showing (>=50% revealed) or hiding it (<50% revealed).
    CGFloat offsetAdjustment = 0;
    CGFloat threshold = searchBarHeight / 2;
    CGFloat contentOffsetInset = proposedContentOffset.y + self.collectionView.contentInset.top;
    if (contentOffsetInset <= threshold) {
        offsetAdjustment = -contentOffsetInset;
    }
    else if (contentOffsetInset > threshold && contentOffsetInset < searchBarHeight) {
        offsetAdjustment = searchBarHeight - contentOffsetInset;
    }
    return CGPointMake(proposedContentOffset.x, proposedContentOffset.y + offsetAdjustment);
}

@end
