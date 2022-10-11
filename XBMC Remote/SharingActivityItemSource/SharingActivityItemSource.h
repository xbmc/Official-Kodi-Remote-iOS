//
//  SharingActivityItemSource.h
//  Kodi Remote
//
//  Created by Buschmann on 09.03.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

@interface SharingActivityItemSource : NSObject <UIActivityItemSource>

- (instancetype)initWithUrlString:(NSString*)urlString label:(NSString*)label image:(UIImage*)image;

@end
