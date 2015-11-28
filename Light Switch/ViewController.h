//
//  ViewController.h
//  Light Switch
//
//  Created by Greg Paton on 11/23/15.
//  Copyright © 2015 Greg Paton. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <NSURLSessionDataDelegate, NSURLSessionTaskDelegate> {
    int _sessionFailureCount;
}

@property (strong, nonatomic) IBOutlet UIButton *buttonOn;
@property (strong, nonatomic) IBOutlet UIButton *buttonOff;
@property (strong, nonatomic) IBOutlet UIButton *buttonCancel;
@property (strong, nonatomic) IBOutlet UIButton *buttonLogout;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorLightSwitch;

@property NSURLSessionDataTask *urlSessionTask;

- (IBAction)buttonPressLightOn:(id)sender;
- (IBAction)buttonPressLightOff:(id)sender;
- (IBAction)buttonPressLogout:(id)sender;
- (IBAction)buttonPressCancel:(id)sender;

@end

