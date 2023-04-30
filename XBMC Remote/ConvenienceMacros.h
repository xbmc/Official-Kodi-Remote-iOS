//
//  ConvenienceMacros.h
//  Kodi Remote
//
//  Created by Buschmann on 07.07.21.
//  Copyright © 2021 joethefox inc. All rights reserved.
//

#ifndef ConvenienceMacros_h
#define ConvenienceMacros_h

/*
 * Device and orientation checks
 */
#define IS_IPHONE (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
#define IS_IPAD (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
#define IS_PORTRAIT UIInterfaceOrientationIsPortrait(UIApplication.sharedApplication.statusBarOrientation)
#define IS_LANDSCAPE UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation)
 
/*
 * Color defines
 */
#define APP_TINT_COLOR [Utilities getGrayColor:0 alpha:0.3]
#define ICON_TINT_COLOR UIColor.lightGrayColor
#define ICON_TINT_COLOR_ACTIVE UIColor.systemBlueColor
#define BAR_TINT_COLOR [Utilities getGrayColor:26 alpha:1]
#define REMOTE_CONTROL_BAR_TINT_COLOR [Utilities getGrayColor:12 alpha:1]
#define SLIDER_DEFAULT_COLOR [Utilities getSystemTeal]
#define TOOLBAR_TINT_COLOR [Utilities getGrayColor:38 alpha:0.95]

/*
 * Dimension and layout macros
 */
#define GET_MAINSCREEN_HEIGHT CGRectGetHeight(UIScreen.mainScreen.fixedCoordinateSpace.bounds)
#define GET_MAINSCREEN_WIDTH CGRectGetWidth(UIScreen.mainScreen.fixedCoordinateSpace.bounds)
#define STACKSCROLL_WIDTH (GET_MAINSCREEN_WIDTH - PAD_MENU_TABLE_WIDTH)
#define ANCHOR_RIGHT_PEEK (GET_MAINSCREEN_WIDTH/10.0)

/*
 * Other
 */
#define LOCALIZED_STR(string) NSLocalizedString(string, nil)

#endif /* ConvenienceMacros_h */
