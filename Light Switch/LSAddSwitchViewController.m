//
//  LSAddSwitchViewController.m
//  Light Switch
//
//  Created by Greg Paton on 12/5/15.
//  Copyright © 2015 Greg Paton. All rights reserved.
//

#import "LSAddSwitchViewController.h"
#import "LSSwitchInfo.h"
#import "Constants.h"
#import "ViewController.h"

@interface LSAddSwitchViewController ()

@end

@implementation LSAddSwitchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    UIBarButtonItem *barButtonItem = (UIBarButtonItem*)sender;
    NSLog(@"%@", [barButtonItem title]);
    
    if ([[[barButtonItem title] lowercaseString] isEqualToString:@"save"]) {
        
    }
    
    if ([[segue identifier] isEqualToString:@"addSwitchSave"]) {
        ViewController *controller = (ViewController*)[segue destinationViewController];
        if (controller) {
            [controller addSwitchWithTitle:[[self textFieldName] text] withSwitchName:[[self textFieldURL] text]];
        }
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
//    UIBarButtonItem *barButtonItem = (UIBarButtonItem*)sender;
//    if ([[[barButtonItem title] lowercaseString] isEqualToString:@"save"]) {
//        LSSwitchInfo *switchInfo = [[LSSwitchInfo alloc] init];
//        [switchInfo setTitle:[[self textFieldName] text]];
//        [switchInfo setUrl:[[self textFieldURL] text]];
//        
//        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//        NSData *data = [defaults objectForKey:LSKeySwitchTableInfo];
//        NSMutableDictionary *switchTableInfo;
//        if (data) {
//            NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
//            switchTableInfo = [dict mutableCopy];
//        }
//        else {
//            switchTableInfo = [[NSMutableDictionary alloc] init];
//        }
//        
//        NSNumber *tag = [NSNumber numberWithUnsignedInteger:[switchTableInfo count]];
//        [switchInfo setTag:[tag integerValue]];
//        
//        [switchTableInfo setObject:switchInfo forKey:tag];
//        
//        data = [NSKeyedArchiver archivedDataWithRootObject:switchTableInfo];
//        [defaults setObject:data forKey:LSKeySwitchTableInfo];
//    }
    
    
    if ([identifier isEqualToString:@"addSwitchSave"]) {
        //ViewController *controller = (ViewController*)segue.destinationViewController;
    }
    
    return YES;
}

@end
