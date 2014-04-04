//
//  SettingsValuesViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 2/4/14.
//  Copyright (c) 2014 joethefox inc. All rights reserved.
//

#import "SettingsValuesViewController.h"
#import "DSJSONRPC.h"
#import "AppDelegate.h"

@interface SettingsValuesViewController ()

@end

@implementation SettingsValuesViewController

@synthesize detailItem = _detailItem;

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
    }
}

-(void)retrieveXBMCData:(NSString *)method parameters:(NSDictionary *)params itemKey:(NSString *)itemkey{
    NSString *userPassword=[[AppDelegate instance].obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", [AppDelegate instance].obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", [AppDelegate instance].obj.serverUser, userPassword, [AppDelegate instance].obj.serverIP, [AppDelegate instance].obj.serverPort];
    DSJSONRPC *jsonRPC = nil;
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    [jsonRPC callMethod: method
         withParameters: params
           onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
               if (error == nil && methodError == nil) {
                   NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"name"  ascending:YES];
                   NSArray *retrievedItems = [[methodResult objectForKey:itemkey] sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];
                   for (NSDictionary *item in retrievedItems) {
                       [settingOptions addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                  [item objectForKey:@"name"], @"label",
                                                  [item objectForKey:@"addonid"], @"value",
                                                  nil]
                        ];
                   }
                   [_tableView reloadData];
               }
               else {
                   NSLog(@"%@ %@", methodError, error);
               }
           }];
    return;
}

- (id)initWithFrame:(CGRect)frame withItem:(id)item {
    if (self = [super init]) {
		
        [self.view setFrame:frame];
        
        self.detailItem = item;
        
        cellHeight = 44.0f;
        
        settingOptions = [self.detailItem objectForKey:@"options"];
        if (![settingOptions isKindOfClass:[NSArray class]]) {
            settingOptions = nil;
        }
        itemControls = [self.detailItem objectForKey:@"control"];
        xbmcSetting = cDefault;
        
        if ([[itemControls objectForKey:@"format"] isEqualToString:@"boolean"]) {
            xbmcSetting = cSwitch;
            cellHeight = 180.0f;
        }
        else if ([[itemControls objectForKey:@"format"] isEqualToString:@"addon"]) {
            xbmcSetting = cList;
            cellHeight = 44.0f;
//            NSLog(@"AAA %@", self.detailItem);
            
            [self retrieveXBMCData: @"Addons.GetAddons"
                        parameters: [NSDictionary dictionaryWithObjectsAndKeys:
                                     [self.detailItem objectForKey:@"addontype"], @"type",
                                     [NSNumber numberWithBool:YES], @"enabled",
                                     [NSArray arrayWithObjects:@"name", nil], @"properties",
                                     nil]
                           itemKey: @"addons"];
            
            settingOptions = [[NSMutableArray alloc] init];
        }
        else if ([[itemControls objectForKey:@"type"] isEqualToString:@"spinner"] && settingOptions == nil) {
            xbmcSetting = cSlider;
            cellHeight = 184.0f;
        }
        else if ([[itemControls objectForKey:@"type"] isEqualToString:@"edit"]) {
            xbmcSetting = cInput;
            cellHeight = 172.0f;
        }
        else {
            if ([settingOptions isKindOfClass:[NSArray class]]){
                if ([settingOptions count] > 0){
                    xbmcSetting = cList;
                }
            }
            self.navigationItem.title = [self.detailItem objectForKey:@"label"];
        }

        UIImageView *imageBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shiny_black_back"]];
        [imageBackground setAutoresizingMask: UIViewAutoresizingFlexibleBottomMargin |UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [imageBackground setFrame:frame];
        [self.view addSubview:imageBackground];
		_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
        cellLabelOffset = 8;
		[_tableView setDelegate:self];
		[_tableView setDataSource:self];
        [_tableView setBackgroundColor:[UIColor clearColor]];
        UIView* footerView =  [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
		_tableView.tableFooterView = footerView;
        [self.view setBackgroundColor:[UIColor clearColor]];
        [self.view addSubview:_tableView];
	}
    return self;
}

#pragma mark -
#pragma mark Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return cellHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numRows = 1;
    if ([settingOptions isKindOfClass:[NSArray class]]) {
//        numRows = [settingOptions count] == 0 ? 1 : [settingOptions count];
        numRows = [settingOptions count];
    }
    return numRows;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	cell.backgroundColor = [UIColor whiteColor];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *tableCellIdentifier = @"UITableViewCell";
	UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableCellIdentifier];
        UILabel *cellLabel = [[UILabel alloc] initWithFrame:CGRectMake(cellLabelOffset, cellHeight/2 - 11, self.view.bounds.size.width - cellLabelOffset - 38, 22)];
        cellLabel.tag = 1;
        [cellLabel setFont:[UIFont systemFontOfSize:18]];
        [cellLabel setAdjustsFontSizeToFitWidth:YES];
        [cellLabel setMinimumFontSize:12];
        [cellLabel setTextColor:[UIColor blackColor]];
        [cellLabel setHighlightedTextColor:[UIColor blackColor]];
        [cell.contentView addSubview:cellLabel];
        
        UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(cellLabelOffset, 54, self.view.bounds.size.width - cellLabelOffset - 68, 120)];
        descriptionLabel.tag = 2;
        [descriptionLabel setFont:[UIFont systemFontOfSize:12]];
        [descriptionLabel setAdjustsFontSizeToFitWidth:YES];
        [descriptionLabel setNumberOfLines:8];
        [descriptionLabel setMinimumFontSize:12];
        [descriptionLabel setTextColor:[UIColor grayColor]];
        [descriptionLabel setHighlightedTextColor:[UIColor blackColor]];
        [cell.contentView addSubview:descriptionLabel];
        
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(14, cellHeight - 20 - 20, cell.frame.size.width - 14 * 2, 20)];
        [slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
        [slider setBackgroundColor:[UIColor clearColor]];
        slider.continuous = YES;
        slider.tag = 101;
        [cell.contentView addSubview:slider];
        
        int uiSliderLabelWidth = cell.frame.size.width - 14 * 2;
        UILabel *uiSliderLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width / 2 - uiSliderLabelWidth / 2, slider.frame.origin.y - 28, uiSliderLabelWidth, 20)];
        uiSliderLabel.tag = 102;
        [uiSliderLabel setTextAlignment:NSTextAlignmentCenter];
        [uiSliderLabel setFont:[UIFont systemFontOfSize:14]];
        [uiSliderLabel setAdjustsFontSizeToFitWidth:YES];
        [uiSliderLabel setMinimumFontSize:12];
        [uiSliderLabel setTextColor:[UIColor grayColor]];
        [uiSliderLabel setHighlightedTextColor:[UIColor blackColor]];
        [cell.contentView addSubview:uiSliderLabel];
        
        UISwitch *onoff = [[UISwitch alloc] initWithFrame: CGRectZero];
        onoff.tag = 201;
        [onoff addTarget: self action: @selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
        [onoff setFrame:CGRectMake(self.view.bounds.size.width - onoff.frame.size.width - 12, cellHeight/2 - onoff.frame.size.height/2, onoff.frame.size.width, onoff.frame.size.height)];
        [cell.contentView addSubview: onoff];
        
        UITextField *textInputField = [[UITextField alloc] initWithFrame:CGRectMake(14, cellHeight - 20 - 20, cell.frame.size.width - 14 * 2, 30)];
        textInputField.borderStyle = UITextBorderStyleRoundedRect;
        textInputField.textAlignment = NSTextAlignmentCenter;
        textInputField.font = [UIFont systemFontOfSize:15];
        textInputField.placeholder = NSLocalizedString(@"enter value", nil);;
        textInputField.autocorrectionType = UITextAutocorrectionTypeNo;
        textInputField.keyboardType = UIKeyboardTypeDefault;
        textInputField.returnKeyType = UIReturnKeyDone;
        textInputField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textInputField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        textInputField.delegate = self;
        textInputField.tag = 301;
        [cell.contentView addSubview:textInputField];
	}
    cell.accessoryType =  UITableViewCellAccessoryNone;

    UILabel *cellLabel =  (UILabel*) [cell viewWithTag:1];
    UILabel *descriptionLabel =  (UILabel*) [cell viewWithTag:2];
    UISlider *slider = (UISlider*) [cell viewWithTag:101];
    UILabel *sliderLabel =  (UILabel*) [cell viewWithTag:102];
    UISwitch *onoff = (UISwitch*) [cell viewWithTag:201];
    UITextField *textInputField = (UITextField*) [cell viewWithTag:301];
    
    descriptionLabel.hidden = YES;
    slider.hidden = YES;
    sliderLabel.hidden = YES;
    onoff.hidden = YES;
    textInputField.hidden = YES;
    
    NSString *cellText = @"";
    NSString *stringFormat = @"%i";
    NSString *descriptionString = [NSString stringWithFormat:@"%@", [self.detailItem objectForKey:@"genre"]];
    CGSize descriptionSize;

//    NSLog(@"AAAA %@", self.detailItem);
    
    switch (xbmcSetting) {
            
        case cSwitch:
    
            tableView.scrollEnabled = NO;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            descriptionLabel.hidden = NO;
            cellText = [NSString stringWithFormat:@"%@", [self.detailItem objectForKey:@"label"]];
            [cellLabel setFrame:CGRectMake(cellLabelOffset, 8, self.view.bounds.size.width - onoff.frame.size.width - 26, 44)];
            [cellLabel setNumberOfLines:2];
            [descriptionLabel setText:descriptionString];
            descriptionSize = [descriptionLabel.text sizeWithFont:descriptionLabel.font
                                                constrainedToSize:CGSizeMake(descriptionLabel.bounds.size.width, NSIntegerMax)
                                                    lineBreakMode:descriptionLabel.lineBreakMode];
            if (descriptionSize.height > descriptionLabel.bounds.size.height) {
                [descriptionLabel setFont:[UIFont systemFontOfSize:11]];
            }
            
            onoff.hidden = NO;
            onoff.on = [[self.detailItem objectForKey:@"value"] boolValue];
            
            break;
            
        case cList:
            
            cellText = [NSString stringWithFormat:@"%@", [[settingOptions objectAtIndex:indexPath.row] objectForKey:@"label"]];
            if ([[[settingOptions objectAtIndex:indexPath.row] objectForKey:@"value"] isEqual:[self.detailItem objectForKey:@"value"]]){
                cell.accessoryType =  UITableViewCellAccessoryCheckmark;
            }
            break;
            
        case cSlider:
            
            tableView.scrollEnabled = NO;
            slider.hidden = NO;
            sliderLabel.hidden = NO;
            descriptionLabel.hidden = NO;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cellLabel setFrame:CGRectMake(cellLabelOffset, 8, self.view.bounds.size.width - (cellLabelOffset * 2), 46)];
            [cellLabel setNumberOfLines:2];
            [cellLabel setTextAlignment:NSTextAlignmentCenter];
            cellText = [NSString stringWithFormat:@"%@", [self.detailItem objectForKey:@"label"]];
            
            [descriptionLabel setFrame:CGRectMake(descriptionLabel.frame.origin.x, descriptionLabel.frame.origin.y + 2, self.view.bounds.size.width - (cellLabelOffset * 2), 58)];
            [descriptionLabel setTextAlignment:NSTextAlignmentCenter];
            [descriptionLabel setNumberOfLines:4];
            [descriptionLabel setText: [NSString stringWithFormat:@"%@", [self.detailItem objectForKey:@"genre"]]];
            slider.minimumValue = [[self.detailItem objectForKey:@"minimum"] intValue];
            slider.maximumValue = [[self.detailItem objectForKey:@"maximum"] intValue];
            slider.value = [[self.detailItem objectForKey:@"value"] intValue];
            if ([itemControls objectForKey:@"formatlabel"] != nil){
                stringFormat = [NSString stringWithFormat:@"%@", [itemControls objectForKey:@"formatlabel"]];
            }
            [sliderLabel setText:[NSString stringWithFormat:stringFormat, [[self.detailItem objectForKey:@"value"] intValue]]];
            break;
            
        case cInput:
            
            tableView.scrollEnabled = NO;
            descriptionLabel.hidden = NO;
            textInputField.hidden = NO;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cellLabel setFrame:CGRectMake(cellLabelOffset, 8, self.view.bounds.size.width - (cellLabelOffset * 2), 46)];
            [cellLabel setNumberOfLines:2];
            [cellLabel setTextAlignment:NSTextAlignmentCenter];
            cellText = [NSString stringWithFormat:@"%@", [self.detailItem objectForKey:@"label"]];
            
            [descriptionLabel setFrame:CGRectMake(descriptionLabel.frame.origin.x, descriptionLabel.frame.origin.y + 2, self.view.bounds.size.width - (cellLabelOffset * 2), 74)];
            [descriptionLabel setTextAlignment:NSTextAlignmentCenter];
            [descriptionLabel setNumberOfLines:5];
            descriptionString  = [descriptionString stringByReplacingOccurrencesOfString:@"[B]" withString:@""];
            descriptionString  = [descriptionString stringByReplacingOccurrencesOfString:@"[/B]" withString:@""];
            [descriptionLabel setText: descriptionString];
            descriptionSize = [descriptionLabel.text sizeWithFont:descriptionLabel.font
                                                       constrainedToSize:CGSizeMake(descriptionLabel.bounds.size.width, NSIntegerMax) lineBreakMode:descriptionLabel.lineBreakMode];
            if (descriptionSize.height > descriptionLabel.bounds.size.height) {
                [descriptionLabel setFont:[UIFont systemFontOfSize:11]];
            }
            
            [textInputField setText:[NSString stringWithFormat:@"%@", [self.detailItem objectForKey:@"value"]]];
            break;
            
        case cDefault:
            if ([self.detailItem objectForKey:@"value"] != nil){
                cellText = [NSString stringWithFormat:@"%@", [self.detailItem objectForKey:@"value"]];
                cell.accessoryType =  UITableViewCellAccessoryDisclosureIndicator;
            }
            break;

        default:
            if ([self.detailItem objectForKey:@"value"] != nil){
                cellText = [NSString stringWithFormat:@"%@", [self.detailItem objectForKey:@"value"]];
                cell.accessoryType =  UITableViewCellAccessoryDisclosureIndicator;
            }
            break;
    }

    if ([cellText isEqualToString:@""] || cellText == nil){
        cellText = [NSString stringWithFormat:@"%@", [self.detailItem objectForKey:@"genre"]];
    }

    [cellLabel setText:cellText];

    return cell;
}
-(void)sliderAction:(id)sender {
    UISlider *slider = (UISlider*) sender;
    float newStep = roundf((slider.value) / [[self.detailItem objectForKey:@"step"] intValue]);
    slider.value = newStep * [[self.detailItem objectForKey:@"step"] intValue];
    if ([[[slider superview] viewWithTag:102] isKindOfClass:[UILabel class]]){
        UILabel *sliderLabel = (UILabel *)[[slider superview] viewWithTag:102];
        NSString *stringFormat = @"%i";
        if ([itemControls objectForKey:@"formatlabel"] != nil){
            stringFormat = [NSString stringWithFormat:@"%@", [itemControls objectForKey:@"formatlabel"]];
        }
        [sliderLabel setText:[NSString stringWithFormat:stringFormat, (int)slider.value]];
    }
}

- (void)toggleSwitch:(id)sender {
}

#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSInteger viewWidth = self.view.frame.size.width;
    UIView *sectionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, 1)];
    [sectionView setBackgroundColor:[UIColor colorWithRed:.4 green:.4 blue:.4 alpha:1]];
    CGRect toolbarShadowFrame = CGRectMake(0.0f, 1, viewWidth, 4);
    UIImageView *toolbarShadow = [[UIImageView alloc] initWithFrame:toolbarShadowFrame];
    [toolbarShadow setImage:[UIImage imageNamed:@"tableUp.png"]];
    toolbarShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    toolbarShadow.contentMode = UIViewContentModeScaleToFill;
    toolbarShadow.opaque = YES;
    toolbarShadow.alpha = .3f;
    [sectionView addSubview:toolbarShadow];
    return sectionView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 1;
}

#pragma mark - LifeCycle

- (void)dismissAddAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^ {
    }];
}

-(void)viewWillAppear:(BOOL)animated {
    if ([self presentingViewController] != nil) {
        UIBarButtonItem * doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissAddAction:)];
        self.navigationItem.rightBarButtonItem = doneButton;
    }
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")){
        [_tableView setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 0)];
        UIEdgeInsets tableViewInsets = UIEdgeInsetsZero;
        tableViewInsets.top = CGRectGetMaxY(self.navigationController.navigationBar.frame);
        _tableView.contentInset = tableViewInsets;
        _tableView.scrollIndicatorInsets = tableViewInsets;
        [_tableView setContentOffset:CGPointMake(0, - tableViewInsets.top) animated:NO];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
