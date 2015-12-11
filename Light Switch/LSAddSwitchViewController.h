//
//  LSAddSwitchViewController.h
//  Light Switch
//
//  Created by Greg Paton on 12/5/15.
//  Copyright © 2015 Greg Paton. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LSAddSwitchViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>

@property (strong, nonatomic) IBOutlet UITextField *textFieldName;
@property (strong, nonatomic) IBOutlet UITextField *textFieldURL;
@property (strong, nonatomic) IBOutlet UIPickerView *pickerViewSwitch;

@property NSMutableArray *switchInfo;

- (void)updateSwitchInfo:(NSMutableArray*)info;

@end
