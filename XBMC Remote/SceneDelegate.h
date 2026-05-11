//
//  SceneDelegate.h
//  Kodi Remote
//
//  Created by Buschmann on 24.05.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

@import UIKit;

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate> {
    UIApplicationShortcutItem *launchShortcutItem;
    NSSet<UIOpenURLContext*>* launchURLContexts;
}

@property (strong, nonatomic) UIWindow *window;

@end
