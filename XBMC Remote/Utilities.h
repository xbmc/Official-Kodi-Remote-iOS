//
//  Utilities.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 4/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import "MessagesView.h"
#import "mainMenu.h"
#import "DSJSONRPC.h"

@import Foundation;
@import SafariServices;

typedef NS_ENUM(NSInteger, JewelType) {
    JewelTypeCD,
    JewelTypeDVD,
    JewelTypeTV,
    JewelTypeUnknown,
};

typedef NS_ENUM(NSInteger, LogoBackgroundType) {
    LogoBackgroundAuto,
    LogoBackgroundDark,
    LogoBackgroundLight,
    LogoBackgroundTransparent,
};

#define PANEL_SHADOW_SIZE 16

@interface Utilities : NSObject

+ (CGImageRef)createLinearSRGBFromImage:(UIImage*)image size:(CGSize)size;
+ (UIColor*)getUIColorFromImage:(UIImage*)image;
+ (UIColor*)textTintColor:(UIColor*)color;
+ (UIColor*)sectionGradientTopColor:(UIColor*)color;
+ (UIColor*)sectionGradientBottomColor:(UIColor*)color;
+ (UIColor*)contrastColor:(UIColor*)color lightColor:(UIColor*)lighter darkColor:(UIColor*)darker;
+ (UIImage*)setLightDarkModeImageAsset:(UIImage*)image lightModeColor:(UIColor*)lightColor darkModeColor:(UIColor*)darkColor;
+ (void)setLogoBackgroundColor:(UIImageView*)imageview mode:(LogoBackgroundType)mode;
+ (BOOL)getPreferTvPosterMode;
+ (LogoBackgroundType)getLogoBackgroundMode;
+ (NSDictionary*)buildPlayerSeekPercentageParams:(int)playerID percentage:(float)percentage;
+ (NSDictionary*)buildPlayerSeekStepParams:(NSString*)stepmode;
+ (CGFloat)getTransformX;
+ (CGRect)createCoverInsideJewel:(UIImageView*)jewelView jewelType:(JewelType)type;
+ (UIAlertController*)createAlertOK:(NSString*)title message:(NSString*)msg;
+ (UIAlertController*)createAlertCopyClipboard:(NSString*)title message:(NSString*)msg;
+ (UIAlertController*)createPowerControl;
+ (void)SFloadURL:(NSString*)url fromctrl:(UIViewController<SFSafariViewControllerDelegate>*)fromctrl;
+ (void)showMessage:(NSString*)messageText color:(UIColor*)messageColor;
+ (void)showLocalNetworkAccessError:(UIViewController*)viewCtrl;
+ (DSJSONRPC*)getJsonRPC;
+ (void)setWebImageAuthorizationOnSuccessNotification:(NSNotification*)note;
+ (NSString*)convertTimeFromSeconds:(NSNumber*)seconds;
+ (NSString*)getItemIconFromDictionary:(NSDictionary*)dict;
+ (NSString*)getStringFromItem:(id)item;
+ (NSNumber*)getNumberFromItem:(id)item;
+ (NSString*)getTimeFromItem:(id)item sec2min:(int)secondsToMinute;
+ (NSString*)getYearFromItem:(id)item;
+ (float)getFloatValueFromItem:(id)item;
+ (NSString*)getRatingFromItem:(id)item;
+ (NSString*)getClearArtFromDictionary:(NSDictionary*)dict type:(NSString*)type;
+ (NSString*)getThumbnailFromDictionary:(NSDictionary*)dict useBanner:(BOOL)useBanner useIcon:(BOOL)useIcon;
+ (NSString*)getDateFromItem:(id)item dateStyle:(NSDateFormatterStyle)dateStyle;
+ (int)getSec2Min:(BOOL)convert;
+ (NSString*)getImageServerURL;
+ (NSString*)formatStringURL:(NSString*)path serverURL:(NSString*)serverURL;
+ (UIImage*)applyRoundedEdgesImage:(UIImage*)image;
+ (void)applyRoundedEdgesView:(UIView*)view;
+ (CGFloat)getBottomPadding;
+ (CGFloat)getTopPadding;
+ (CGFloat)getTopPaddingWithNavBar:(UINavigationController*)navCtrl;
+ (void)sendXbmcHttp:(NSString*)command;
+ (NSString*)getAppVersionString;
+ (void)checkForReviewRequest;
+ (void)checkLocalNetworkAccess;
+ (NSString*)getConnectionStatusIconName;
+ (NSString*)getConnectionStatusServerName;
+ (void)addShadowsToView:(UIView*)view viewFrame:(CGRect)frame;
+ (void)setStyleOfMenuItemCell:(UITableViewCell*)cell active:(BOOL)active menuType:(MenuItemType)type;
+ (void)setStyleOfMenuItems:(UITableView*)tableView active:(BOOL)active menu:(NSArray*)menuList;
+ (NSIndexPath*)getIndexPathForDefaultController:(NSArray*)menuItems;
+ (void)enableDefaultController:(id<UITableViewDelegate>)viewController tableView:(UITableView*)tableView menuItems:(NSArray*)menuItems;
+ (id)unarchivePath:(NSString*)path file:(NSString*)filename;
+ (void)archivePath:(NSString*)path file:(NSString*)filename data:(id)data;
+ (float)getPercentElapsed:(NSDate*)startDate EndDate:(NSDate*)endDate;
+ (void)createTransparentToolbar:(UIToolbar*)toolbar;
+ (NSString*)formatTVShowStringForSeasonTrailing:(id)season episode:(id)episode title:(NSString*)title;
+ (NSString*)formatTVShowStringForSeasonLeading:(id)season episode:(id)episode title:(NSString*)title;
+ (NSString*)formatTVShowStringForSeason:(id)season episode:(id)episode;
+ (NSString*)formatClipboardMessage:(NSString*)method parameters:(NSDictionary*)parameters error:(NSError*)error methodError:(DSJSONRPCError*)methodError;
+ (NSString*)stripBBandHTML:(NSString*)text;
+ (BOOL)isValidMacAddress:(NSString*)macAddress;
+ (void)wakeUp:(NSString*)macAddress;
+ (NSString*)getUrlStyleAddress:(NSString*)address;
+ (NSString*)getServerPort:(NSString*)serverPort;
+ (int)getTcpPort:(NSNumber*)tcpPort;
+ (int)getActivePlayerID:(NSArray*)activePlayerList;
+ (UIViewController*)topMostController;
+ (UIViewController*)topMostControllerIgnoringClass:(Class)ignoredClass;
+ (uint64_t)memoryFootprint;
+ (NSIndexPath*)readLastServerIndex;
+ (void)saveLastServerIndex:(NSIndexPath*)indexPath;
+ (void)readKodiServerParameters;
+ (void)resetKodiServerParameters;

@end

@interface UILabel (Extensions)

- (CGSize)getSize;

@end

@interface UIView (Extensions)

- (void)setX:(CGFloat)x;
- (void)setY:(CGFloat)y;
- (void)setOrigin:(CGPoint)origin;
- (void)setHeight:(CGFloat)height;
- (void)setWidth:(CGFloat)width;
- (void)offsetY:(CGFloat)offset;
- (void)setX:(CGFloat)x alpha:(CGFloat)alpha;
- (void)animateX:(CGFloat)x alpha:(CGFloat)alpha duration:(NSTimeInterval)seconds;
- (void)animateOrigin:(CGPoint)origin duration:(NSTimeInterval)seconds;
- (void)animateAlpha:(CGFloat)alpha duration:(NSTimeInterval)seconds;

@end

@interface UIImageView (Extensions)

- (void)animateImage:(UIImage*)image duration:(NSTimeInterval)seconds;

@end

@interface UIColor (Extensions)

+ (UIColor*)getSystemRed:(CGFloat)alpha;
+ (UIColor*)getSystemGreen:(CGFloat)alpha;
+ (UIColor*)getKodiBlue;
+ (UIColor*)getSystemBlue;
+ (UIColor*)getSystemGray1;
+ (UIColor*)getSystemGray2;
+ (UIColor*)getSystemGray3;
+ (UIColor*)getSystemGray4;
+ (UIColor*)getSystemGray5;
+ (UIColor*)getSystemGray6;
+ (UIColor*)get1stLabelColor;
+ (UIColor*)get2ndLabelColor;
+ (UIColor*)get3rdLabelColor;
+ (UIColor*)get4thLabelColor;
+ (UIColor*)getGrayColor:(int)tone alpha:(CGFloat)alpha;

@end

@interface UIImage (Extensions)

- (UIColor*)averageColor;
- (UIImage*)colorizeWithColor:(UIColor*)color;

@end
