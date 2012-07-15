//
//  mainMenu.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "mainMenu.h"

@implementation mainMenu

@synthesize mainLabel, upperLabel, icon, family, mainButtons, mainMethod, mainFields, mainParameters, rowHeight, thumbWidth, defaultThumb, subItem, enableSection, sheetActions, showInfo, originYearDuration, widthLabel, showRuntime, originLabel, noConvertTime, chooseTab, disableNowPlaying,watchModes,currentWatchMode;

-(id) copyWithZone: (NSZone *) zone{
    mainMenu *menuCopy = [[mainMenu allocWithZone: zone] init];
    [menuCopy setMainLabel:[self.mainLabel copy]];
    [menuCopy setUpperLabel:[self.upperLabel copy]];
    [menuCopy setFamily:self.family];
    [menuCopy setEnableSection:self.enableSection];
    [menuCopy setIcon:[self.icon copy]];
    [menuCopy setMainMethod:[self.mainMethod copy]];
    [menuCopy setDefaultThumb:[self.defaultThumb copy]];
    [menuCopy setMainButtons:[self.mainButtons copy]];
    [menuCopy setMainFields:[self.mainFields copy]];
    [menuCopy setMainParameters:[self.mainParameters mutableCopy]];
    [menuCopy setSubItem:[self.subItem copy]];
    [menuCopy setSheetActions:[self.sheetActions copy]];
    [menuCopy setRowHeight:self.rowHeight];
    [menuCopy setThumbWidth:self.thumbWidth];
    [menuCopy setShowInfo:self.showInfo];
    [menuCopy setOriginYearDuration:self.originYearDuration];
    [menuCopy setOriginLabel:self.originLabel];
    [menuCopy setWidthLabel:self.widthLabel];
    [menuCopy setChooseTab:self.chooseTab];
    [menuCopy setDisableNowPlaying:self.disableNowPlaying];
    [menuCopy setShowRuntime:[self.showRuntime copy]];
    [menuCopy setNoConvertTime:self.noConvertTime];
    [menuCopy setWatchModes:[self.watchModes copy]];
    [menuCopy setCurrentWatchMode: self.currentWatchMode];
    return menuCopy;
}

@end
