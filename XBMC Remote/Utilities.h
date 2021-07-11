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

@interface Utilities : NSObject

+ (UIColor*)averageColor:(UIImage*)image inverse:(BOOL)inverse;
+ (UIColor*)limitSaturation:(UIColor*)c satmax:(CGFloat)satmax;
+ (UIColor*)slightLighterColorForColor:(UIColor*)c;
+ (UIColor*)lighterColorForColor:(UIColor*)c;
+ (UIColor*)darkerColorForColor:(UIColor*)c;
+ (UIColor*)updateColor:(UIColor*)newColor lightColor:(UIColor*)lighter darkColor:(UIColor*)darker;
+ (UIColor*)updateColor:(UIColor*)newColor lightColor:(UIColor*)lighter darkColor:(UIColor*)darker trigger:(CGFloat)trigger;
+ (UIImage*)colorizeImage:(UIImage*)image withColor:(UIColor*)color;
+ (void)setLogoBackgroundColor:(UIImageView*)imageview mode:(LogoBackgroundType)mode;
+ (LogoBackgroundType)getLogoBackgroundMode;
+ (NSDictionary*)buildPlayerSeekPercentageParams:(int)playerID percentage:(float)percentage;
+ (NSArray*)buildPlayerSeekStepParams:(NSString*)stepmode;
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
+ (NSString*)getStringFromDictionary:(NSDictionary*)dict key:(NSString*)key emptyString:(NSString*)empty;
+ (NSString*)getTimeFromDictionary:(NSDictionary*)dict key:(NSString*)key sec2min:(int)secondsToMinute;
+ (NSString*)getYearFromDictionary:(NSDictionary*)dict key:(NSString*)key;
+ (NSString*)getRatingFromDictionary:(NSDictionary*)dict key:(NSString*)key;
+ (NSString*)getClearArtFromDictionary:(NSDictionary*)dict type:(NSString*)type;
+ (NSString*)getThumbnailFromDictionary:(NSDictionary*)dict useBanner:(BOOL)useBanner useIcon:(BOOL)useIcon;
+ (NSString*)formatStringURL:(NSString*)path serverURL:(NSString*)serverURL;
+ (UIImage*)imageWithShadow:(UIImage*)source radius:(CGFloat)radius;

@end
