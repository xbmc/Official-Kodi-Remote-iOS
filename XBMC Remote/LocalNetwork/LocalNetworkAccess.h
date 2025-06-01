//
//  LocalNetworkAccess.h
//  Kodi Remote
//
//  Created by Buschmann on 30.05.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

@import Foundation;

@interface LocalNetworkAccess : NSObject

- (void)checkAccessState:(void (^)(BOOL))completion;
    
@end
