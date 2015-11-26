//
//  LoginViewController.m
//  Light Switch
//
//  Created by Greg Paton on 11/25/15.
//  Copyright © 2015 Greg Paton. All rights reserved.
//

#import "LoginViewController.h"
#import "KeychainWrapper.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSURL *defaultURL = [userDefaults URLForKey:@"url"];
    if (defaultURL) {
        [[self tfURL] setText:[defaultURL absoluteString]];
    }
    
    NSString *defaultUsername = [userDefaults stringForKey:@"username"];
    if (defaultUsername) {
        [[self tfUsername] setText:defaultUsername];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)login:(id)sender {
    // Get URL, username, and password
    NSURL *const url = [NSURL URLWithString:[[self tfURL] text]];
    NSString *const username = [[self tfUsername] text];
    NSString *const password = [[self tfPassword] text];
    
    // Check if username in in NSUserDefaults
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *defaultUsername = [userDefaults stringForKey:@"username"];
    // Add username to defaults
    if (nil == defaultUsername) {
        [userDefaults setObject:username forKey:@"username"];
        [userDefaults synchronize];
    }
    
    NSURL *defaultURL = [userDefaults URLForKey:@"url"];
    if (nil == defaultURL) {
        [userDefaults setURL:url forKey:@"url"];
        [userDefaults synchronize];
    }
    
    //KeychainWrapper *keychainWrapper = [KeychainWrapper init];
    //[keychainWrapper mySetObject:password forKey:kSecValueData];
    //[keychainWrapper writeToKeychain];
    
    [self performSegueWithIdentifier:@"loginSuccess" sender:self];
}
@end
