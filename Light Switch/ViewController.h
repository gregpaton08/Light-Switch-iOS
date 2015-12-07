//
//  ViewController.h
//  Light Switch
//
//  Created by Greg Paton on 11/23/15.
//  Copyright © 2015 Greg Paton. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <NSURLSessionDataDelegate, NSURLSessionTaskDelegate, UITableViewDelegate, UITableViewDataSource> {
    int _sessionFailureCount;
    
    NSArray *tableData;
}

@property (strong, nonatomic) IBOutlet UIButton *buttonOn;
@property (strong, nonatomic) IBOutlet UIButton *buttonOff;
@property (strong, nonatomic) IBOutlet UIButton *buttonLogout;
@property (strong, nonatomic) IBOutlet UITableView *tableViewSwitches;

@property NSURLSessionDataTask *urlSessionTask;
@property NSMutableDictionary *switchTableData;
@property NSLock *switchTableDataLock;

- (IBAction)buttonPressLightOn:(id)sender;
- (IBAction)buttonPressLightOff:(id)sender;
- (IBAction)buttonPressLogout:(id)sender;
- (IBAction)buttonPressInsert:(id)sender;
- (IBAction)buttonPressAddSwitch:(id)sender;

@end

