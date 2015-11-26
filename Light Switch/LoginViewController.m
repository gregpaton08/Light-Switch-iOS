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
    NSString *urlString = [[self tfURL] text]; //[NSURL URLWithString:[[self tfURL] text]];
    if (false == [[[urlString substringToIndex:4] lowercaseString] isEqualToString:@"http"]) {
        urlString = [NSString stringWithFormat:@"http://%@", urlString];
    }
    NSURL *const url = [NSURL URLWithString:urlString];
    NSString *const username = [[self tfUsername] text];
    NSString *const password = [[self tfPassword] text];
    
    // Get the user defaults
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    // Update URL is in user defaults
    [userDefaults setURL:url forKey:@"url"];
    [userDefaults synchronize];
    
    // Update username in in user defaults
    [userDefaults setObject:username forKey:@"username"];
    [userDefaults synchronize];
    
    KeychainWrapper *keychainWrapper = [[KeychainWrapper alloc] init];
    [keychainWrapper mySetObject:password forKey:(__bridge id)kSecValueData];
    [keychainWrapper writeToKeychain];
    
    [self performSegueWithIdentifier:@"loginSuccess" sender:self];
}
@end
