//
//  LoginViewController.h
//  Light Switch
//
//  Created by Greg Paton on 11/25/15.
//  Copyright © 2015 Greg Paton. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController <NSURLSessionDataDelegate, NSURLSessionTaskDelegate> {
    int _sessionFailureCount;
}

@property (strong, nonatomic) IBOutlet UITextField *tfURL;
@property (strong, nonatomic) IBOutlet UITextField *tfUsername;
@property (strong, nonatomic) IBOutlet UITextField *tfPassword;

- (IBAction)login:(id)sender;
- (IBAction)textFieldPasswordReturn:(id)sender;
- (IBAction)backgroundTouch:(id)sender;

@end
