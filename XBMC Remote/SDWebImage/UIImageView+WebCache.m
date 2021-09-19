/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImageView+WebCache.h"
#import "objc/runtime.h"
#import "Utilities.h"

static char operationKey;

@implementation UIImageView (WebCache)

- (CGSize)doubleSizeIfRetina:(CGSize)size {
    return CGSizeMake(size.width * UIScreen.mainScreen.scale, size.height * UIScreen.mainScreen.scale);
}

- (void)setImageWithURL:(NSURL*)url {
    [self setImageWithURL:url placeholderImage:nil options:0 andResize:CGSizeZero withBorder:YES progress:nil completed:nil];
}

- (void)setImageWithURL:(NSURL*)url placeholderImage:(UIImage*)placeholder {
    [self setImageWithURL:url placeholderImage:placeholder options:0 andResize:CGSizeZero withBorder:YES progress:nil completed:nil];
}

- (void)setImageWithURL:(NSURL*)url placeholderImage:(UIImage*)placeholder andResize:(CGSize)size {
    size = [self doubleSizeIfRetina:size];
    [self setImageWithURL:url placeholderImage:placeholder options:0 andResize:size withBorder:YES progress:nil completed:nil];
}

- (void)setImageWithURL:(NSURL*)url placeholderImage:(UIImage*)placeholder options:(SDWebImageOptions)options {
    [self setImageWithURL:url placeholderImage:placeholder options:options andResize:CGSizeZero withBorder:YES progress:nil completed:nil];
}

- (void)setImageWithURL:(NSURL*)url completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageWithURL:url placeholderImage:nil options:0 andResize:CGSizeZero withBorder:YES progress:nil completed:completedBlock];
}

- (void)setImageWithURL:(NSURL*)url placeholderImage:(UIImage*)placeholder andResize:(CGSize)size completed:(SDWebImageCompletedBlock)completedBlock {
    size = [self doubleSizeIfRetina:size];
    [self setImageWithURL:url placeholderImage:placeholder options:0 andResize:size withBorder:YES progress:nil completed:completedBlock];
}

- (void)setImageWithURL:(NSURL*)url placeholderImage:(UIImage*)placeholder completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageWithURL:url placeholderImage:placeholder options:0 andResize:CGSizeZero withBorder:YES progress:nil completed:completedBlock];
}

- (void)setImageWithURL:(NSURL*)url placeholderImage:(UIImage*)placeholder options:(SDWebImageOptions)options completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageWithURL:url placeholderImage:placeholder options:options andResize:CGSizeZero withBorder:YES progress:nil completed:completedBlock];
}

- (void)setImageWithURL:(NSURL*)url placeholderImage:(UIImage*)placeholder options:(SDWebImageOptions)options andResize:(CGSize)size withBorder:(BOOL)withBorder progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletedBlock)completedBlock {
    [self cancelCurrentImageLoad];

    self.image = placeholder;
    
    if (url && url.path) {
        NSDictionary *userInfo = nil;
        if (size.width && size.height) {
            userInfo = @{@"transformation": @"resize",
                         @"size": NSStringFromCGSize(size)};
        }
        __weak UIImageView *wself = self;
        id<SDWebImageOperation> operation = [SDWebImageManager.sharedManager downloadWithURL:url options:options userInfo:userInfo progress:progressBlock completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
            __strong UIImageView *sself = wself;
            if (!sself) {
                return;
            }
            if (image) {
                sself.image = [Utilities applyRoundedEdgesImage:image drawBorder:withBorder];
                [sself setNeedsLayout];
            }
            if (completedBlock) {
                completedBlock(image, error, cacheType);
            }
        }];
        objc_setAssociatedObject(self, &operationKey, operation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)cancelCurrentImageLoad {
    // Cancel in progress downloader from queue
    id<SDWebImageOperation> operation = objc_getAssociatedObject(self, &operationKey);
    if (operation) {
        [operation cancel];
        objc_setAssociatedObject(self, &operationKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

@end
