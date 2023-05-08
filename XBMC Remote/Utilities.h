//
//  Utilities.h
//  XBMC Remote
//
//  Created by Giovanni Messina on 4/3/13.
//  Copyright (c) 2013 joethefox inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SafariServices/SafariServices.h>
#import "DSJSONRPC.h"

typedef enum {
    jewelTypeCD,
    jewelTypeDVD,
    jewelTypeTV,
    jewelTypeUnknown,
} eJewelType;

typedef enum {
    bgAuto,
    bgDark,
    bgLight,
    bgTrans
} LogoBackgroundType;

#define PANEL_SHADOW_SIZE 16

@interface Utilities : NSObject

+ (UIColor*)averageColor:(UIImage*)image inverse:(BOOL)inverse autoColorCheck:(BOOL)autoColorCheck;
+ (UIColor*)limitSaturation:(UIColor*)c satmax:(CGFloat)satmax;
+ (UIColor*)slightLighterColorForColor:(UIColor*)c;
+ (UIColor*)lighterColorForColor:(UIColor*)c;
+ (UIColor*)darkerColorForColor:(UIColor*)c;
+ (UIColor*)updateColor:(UIColor*)newColor lightColor:(UIColor*)lighter darkColor:(UIColor*)darker;
+ (UIColor*)updateColor:(UIColor*)newColor lightColor:(UIColor*)lighter darkColor:(UIColor*)darker trigger:(CGFloat)trigger;
+ (UIImage*)colorizeImage:(UIImage*)image withColor:(UIColor*)color;
+ (void)setLogoBackgroundColor:(UIImageView*)imageview mode:(LogoBackgroundType)mode;
+ (BOOL)getPreferTvPosterMode;
+ (LogoBackgroundType)getLogoBackgroundMode;
+ (NSDictionary*)buildPlayerSeekPercentageParams:(int)playerID percentage:(float)percentage;
+ (NSDictionary*)buildPlayerSeekStepParams:(NSString*)stepmode;
+ (CGFloat)getTransformX;
+ (UIColor*)getSystemRed:(CGFloat)alpha;
+ (UIColor*)getSystemGreen:(CGFloat)alpha;
+ (UIColor*)getSystemBlue;
+ (UIColor*)getSystemTeal;
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
+ (CGRect)createXBMCInfoframe:(UIImage*)logo height:(CGFloat)height width:(CGFloat)width;
+ (CGRect)createCoverInsideJewel:(UIImageView*)jewelView jewelType:(eJewelType)type;
+ (UIAlertController*)createAlertOK:(NSString*)title message:(NSString*)msg;
+ (UIAlertController*)createAlertCopyClipboard:(NSString*)title message:(NSString*)msg;
+ (void)SFloadURL:(NSString*)url fromctrl:(UIViewController<SFSafariViewControllerDelegate>*)fromctrl;
+ (DSJSONRPC*)getJsonRPC;
+ (NSDictionary*)indexKeyedDictionaryFromArray:(NSArray*)array;
+ (NSMutableDictionary*)indexKeyedMutableDictionaryFromArray:(NSArray*)array;
+ (NSString*)convertTimeFromSeconds:(NSNumber*)seconds;
+ (NSString*)getItemIconFromDictionary:(NSDictionary*)dict mainFields:(NSDictionary*)mainFields;
+ (NSString*)getStringFromItem:(id)item;
+ (NSString*)getTimeFromItem:(id)item sec2min:(int)secondsToMinute;
+ (NSString*)getYearFromItem:(id)item;
+ (NSString*)getRatingFromItem:(id)item;
+ (NSString*)getClearArtFromDictionary:(NSDictionary*)dict type:(NSString*)type;
+ (NSString*)getThumbnailFromDictionary:(NSDictionary*)dict useBanner:(BOOL)useBanner useIcon:(BOOL)useIcon;
+ (NSString*)getDateFromItem:(id)item dateStyle:(NSDateFormatterStyle)dateStyle;
+ (int)getSec2Min:(BOOL)convert;
+ (NSString*)getImageServerURL;
+ (NSString*)formatStringURL:(NSString*)path serverURL:(NSString*)serverURL;
+ (CGFloat)getHeightOfLabel:(UILabel*)label;
+ (UIImage*)roundedCornerImage:(UIImage*)image drawBorder:(BOOL)drawBorder;
+ (UIImageView*)roundedCornerView:(UIImageView*)view drawBorder:(BOOL)drawBorder;
+ (UIImage*)applyRoundedEdgesImage:(UIImage*)image drawBorder:(BOOL)drawBorder;
+ (UIImageView*)applyRoundedEdgesView:(UIImageView*)imageView drawBorder:(BOOL)drawBorder;
+ (void)turnTorchOn:(id)sender on:(BOOL)torchOn;
+ (BOOL)isTorchOn;
+ (BOOL)hasRemoteToolBar;
+ (CGFloat)getBottomPadding;
+ (CGFloat)getTopPadding;
+ (void)sendXbmcHttp:(NSString*)command;
+ (NSString*)getAppVersionString;
+ (void)checkForReviewRequest;
+ (NSString*)getConnectionStatusIconName;
+ (NSString*)getConnectionStatusServerName;
+ (void)addShadowsToView:(UIView*)view viewFrame:(CGRect)frame;
+ (void)setStyleOfMenuItems:(UITableView*)tableView active:(BOOL)active;
+ (void)enableDefaultController:(id<UITableViewDelegate>)viewController tableView:(UITableView*)tableView menuItems:(NSArray*)menuItems;
+ (id)unarchivePath:(NSString*)path file:(NSString*)filename;
+ (void)archivePath:(NSString*)path file:(NSString*)filename data:(id)data;
+ (void)AnimView:(UIView*)view AnimDuration:(NSTimeInterval)seconds Alpha:(CGFloat)alphavalue XPos:(int)X;
+ (void)AnimView:(UIView*)view AnimDuration:(NSTimeInterval)seconds Alpha:(CGFloat)alphavalue XPos:(int)X YPos:(int)Y;
+ (void)alphaView:(UIView*)view AnimDuration:(NSTimeInterval)seconds Alpha:(CGFloat)alphavalue;
+ (void)imageView:(UIImageView*)view AnimDuration:(NSTimeInterval)seconds Image:(UIImage*)image;
+ (void)colorLabel:(UILabel*)view AnimDuration:(NSTimeInterval)seconds Color:(UIColor*)color;
+ (float)getPercentElapsed:(NSDate*)startDate EndDate:(NSDate*)endDate;
+ (void)createTransparentToolbar:(UIToolbar*)toolbar;
+ (NSString*)formatTVShowStringForSeason:(id)season episode:(id)episode title:(NSString*)title;
+ (NSString*)formatTVShowStringForSeason:(id)season episode:(id)episode;

@end
