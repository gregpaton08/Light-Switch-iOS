//
//  LoginViewController.m
//  Light Switch
//
//  Created by Greg Paton on 11/25/15.
//  Copyright © 2015 Greg Paton. All rights reserved.
//

#import "LoginViewController.h"
#import "KeychainWrapper.h"
#import "Reachability.h"

@import LocalAuthentication;

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _sessionFailureCount = 0;
    
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

- (void)authenticateUser {
    _sessionFailureCount = 0;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSURL *defaultURL = [userDefaults URLForKey:@"url"];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    
    NSURLSessionDataTask *downloadTask = [session dataTaskWithURL:defaultURL];
    [downloadTask resume];
}

- (void)userLogin {
    // Disable login button and show activity indicator
    [[self buttonLogin] setEnabled:NO];
    [[self activityIndicatorLogin] startAnimating];
    
    // Get URL, username, and password
    NSString *urlString = [[self tfURL] text]; //[NSURL URLWithString:[[self tfURL] text]];
    if (false == [[[urlString substringToIndex:4] lowercaseString] isEqualToString:@"http"]) {
        urlString = [NSString stringWithFormat:@"http://%@", urlString];
    }
    // If ip address is local/private then check that wifi is on
    if ([urlString containsString:@"192.168"]) {
        if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] != ReachableViaWiFi) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Not connected to wifi" message:@"Connect to wifi and try again" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *actionOkay = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
            UIAlertAction *actionSettings = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                [[UIApplication sharedApplication] openURL:url];
            }];
            [alert addAction:actionOkay];
            [alert addAction:actionSettings];
            [self presentViewController:alert animated:YES completion:nil];
            
            [[self buttonLogin] setEnabled:YES];
            [[self activityIndicatorLogin] stopAnimating];
            
            return;
        }
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
    
    [self authenticateUser];
}

- (IBAction)login:(id)sender {
    [self userLogin];
}

- (IBAction)textFieldPasswordReturn:(id)sender {
    [sender resignFirstResponder];
    [self userLogin];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    if (0 == _sessionFailureCount) {
        // Get username from user defaults
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *username = [userDefaults stringForKey:@"username"];
        
        // Get password from keychain
        KeychainWrapper *keychainWrapper = [[KeychainWrapper alloc] init];
        NSString *password = [keychainWrapper myObjectForKey:(__bridge id)kSecValueData];
        
        // Authenticate user
        NSURLCredential *credentials = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credentials);
    }
    else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Incorrect username or password" message:@"Try again" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
        [alert addAction:action];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self presentViewController:alert animated:YES completion:nil];
        }];
        
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        _sessionFailureCount = 0;
        
        return;
    }
    
    ++_sessionFailureCount;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    // Stop progress animation
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[self buttonLogin] setEnabled:YES];
        [[self activityIndicatorLogin] stopAnimating];
    }];
    
    if (nil == error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self performSegueWithIdentifier:@"loginSuccess" sender:self];
        }];
    }
    else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Unable to connect to server" message:@"Please check network connection" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
        [alert addAction:action];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self presentViewController:alert animated:YES completion:nil];
        }];
    }
}

- (IBAction)backgroundTouch:(id)sender {
    [self.view endEditing:YES];
}

@end
