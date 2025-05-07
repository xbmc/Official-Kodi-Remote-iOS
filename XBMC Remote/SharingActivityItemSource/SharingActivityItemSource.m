//
//  SharingActivityItemSource.m
//  Kodi Remote
//
//  Created by Buschmann on 09.03.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

#import "SharingActivityItemSource.h"

@import UIKit;
@import LinkPresentation;

@interface SharingActivityItemSource ()

@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSString *label;
@property (nonatomic, copy) UIImage *thumbnail;

@end

@implementation SharingActivityItemSource

- (instancetype)initWithUrlString:(NSString*)urlString label:(NSString*)label image:(UIImage*)image {
    if (self = [super init]) {
        self.url = [NSURL URLWithString:urlString];
        self.label = label;
        self.thumbnail = image ?: [UIImage imageNamed:@"app_logo"];
    }
    return self;
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController*)activityViewController {
    return self.url;
}

- (id)activityViewController:(UIActivityViewController*)activityViewController itemForActivityType:(NSString*)activityType {
    return self.url;
}

- (LPLinkMetadata*)activityViewControllerLinkMetadata:(UIActivityViewController*)activityViewController API_AVAILABLE(ios(13.0)) {
    __auto_type meta = [LPLinkMetadata new];
    meta.originalURL = self.url;
    meta.URL = meta.originalURL;
    meta.title = self.label;
    meta.imageProvider = [[NSItemProvider alloc] initWithObject:self.thumbnail];
    return meta;
}

@end
