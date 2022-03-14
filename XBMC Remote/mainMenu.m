//
//  mainMenu.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "mainMenu.h"

@implementation mainMenu

@synthesize rootLabel, mainLabel, icon, family, mainButtons, mainMethod, mainFields, mainParameters, rowHeight, thumbWidth, defaultThumb, subItem, enableSection, sheetActions, showInfo, originYearDuration, widthLabel, showRuntime, originLabel, noConvertTime, chooseTab, disableNowPlaying, filterModes, currentFilterMode;

- (id)copyWithZone:(NSZone*)zone {
    mainMenu *menuCopy = [[mainMenu allocWithZone: zone] init];
    menuCopy.rootLabel = [self.rootLabel copy];
    menuCopy.mainLabel = [self.mainLabel copy];
    menuCopy.family = self.family;
    menuCopy.enableSection = self.enableSection;
    menuCopy.icon = [self.icon copy];
    menuCopy.mainMethod = [self.mainMethod copy];
    menuCopy.defaultThumb = [self.defaultThumb copy];
    menuCopy.mainButtons = [self.mainButtons copy];
    menuCopy.mainFields = [self.mainFields copy];
    menuCopy.mainParameters = [self.mainParameters mutableCopy];
    menuCopy.subItem = [self.subItem copy];
    menuCopy.sheetActions = [self.sheetActions copy];
    menuCopy.rowHeight = self.rowHeight;
    menuCopy.thumbWidth = self.thumbWidth;
    menuCopy.showInfo = self.showInfo;
    menuCopy.originYearDuration = self.originYearDuration;
    menuCopy.originLabel = self.originLabel;
    menuCopy.widthLabel = self.widthLabel;
    menuCopy.chooseTab = self.chooseTab;
    menuCopy.disableNowPlaying = self.disableNowPlaying;
    menuCopy.showRuntime = [self.showRuntime copy];
    menuCopy.noConvertTime = self.noConvertTime;
    menuCopy.filterModes = [self.filterModes copy];
    menuCopy.currentFilterMode = self.currentFilterMode;
    return menuCopy;
}

@end
