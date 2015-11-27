//
//  LoginViewController.m
//  Light Switch
//
//  Created by Greg Paton on 11/25/15.
//  Copyright © 2015 Greg Paton. All rights reserved.
//

#import "LoginViewController.h"
#import "Reachability.h"
#import "SSKeychain.h"
#import "Constants.h"

@import LocalAuthentication;

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _sessionFailureCount = 0;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSURL *defaultURL = [userDefaults URLForKey:LSKeyURL];
    if (defaultURL) {
        [[self tfURL] setText:[defaultURL absoluteString]];
    }
    
    NSString *defaultUsername = [userDefaults stringForKey:LSKeyUsername];
    if (defaultUsername) {
        [[self tfUsername] setText:defaultUsername];
    }
    
    if ([userDefaults stringForKey:LSKeyServiceTID] &&
        [userDefaults stringForKey:LSKeyUsernameTID] &&
        [userDefaults stringForKey:LSKeyURLTID] &&
        [userDefaults boolForKey:@"appLaunch"] &&
        [userDefaults boolForKey:@"storeCredentialsTouchID"]) {
        [self userLoginTouchID];
    }
    else if (false == [userDefaults boolForKey:@"storeCredentialsTouchID"]) {
        [[self buttonTouchID] setEnabled:NO];
    }
    
    [userDefaults setBool:NO forKey:@"appLaunch"];
    [userDefaults synchronize];
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

- (void)authenticateUser:(NSString*)user forService:(NSString*)service withURL:(NSURL*)url {
    _sessionFailureCount = 0;
    
    // Set current service and username
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:service forKey:LSKeyServiceCurrent];
    [userDefaults setObject:user forKey:LSKeyUsernameCurrent];
    [userDefaults synchronize];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    
    NSURLSessionDataTask *task = [session dataTaskWithURL:url];
    [task resume];
}

- (BOOL)hasTouchID {
    LAContext *context = [[LAContext alloc] init];
    return [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
}

- (void)promptToUseTouchIDWithCompletion:(void (^)(void))completion {
    // Get the user defaults
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSURL *defaultURL = [userDefaults URLForKey:LSKeyURL];
    NSString *username = [userDefaults stringForKey:LSKeyUsername];
    NSString *service = [userDefaults stringForKey:LSKeyServiceCurrent];
    
    BOOL promptUser = NO;
    NSString *title;
    NSString *message;
    if (false == [service isEqualToString:LSServiceLoginTID]) {
        NSString *password = [SSKeychain passwordForService:service account:username];
        NSString *passwordTouchID = [SSKeychain passwordForService:LSKeyServiceTID account:username];
        
        BOOL useTouchID = [userDefaults boolForKey:LSKeyTouchIDCredentials];
        
        if (false == useTouchID) {
            title = @"Store these credentials with Touch ID?";
            message = @"Any user with Touch ID will be able to login";
            promptUser = YES;
        }
        else if (false == [defaultURL isEqual:[userDefaults URLForKey:LSKeyURLTID]]) {
            title = @"Update credentials for Touch ID?";
            message = @"Credentials have changed";
            promptUser = YES;
        }
        else if (false == [username isEqualToString:[userDefaults stringForKey:LSKeyUsernameTID]]) {
            title = @"Update credentials for Touch ID?";
            message = @"Credentials have changed";
            promptUser = YES;
        }
        else if (false == [password isEqualToString:passwordTouchID]) {
            title = @"Update credentials for Touch ID?";
            message = @"Credentials have changed";
            promptUser = YES;
        }
    }
    
    if (promptUser) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionYes = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            // Save URL for touch ID
            NSURL *defaultURL = [userDefaults URLForKey:LSKeyURL];
            [userDefaults setURL:defaultURL forKey:LSKeyURLTID];
            
            // Save username for touch ID
            NSString *username = [userDefaults stringForKey:LSKeyUsername];
            [userDefaults setObject:username forKey:LSKeyUsernameTID];
        
            // Save password for touch ID
            NSString *password = [SSKeychain passwordForService:LSKeyService account:username];
            [SSKeychain setPassword:password forService:LSKeyServiceTID account:username];
            
            // Update defaults to flag that touch ID credentials are in use
            [userDefaults setBool:YES forKey:LSKeyTouchIDCredentials];
            [userDefaults synchronize];
            
            completion();
        }];
        UIAlertAction *actionNo = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            completion();
        }];
        
        [alert addAction:actionYes];
        [alert addAction:actionNo];
        [self presentViewController:alert animated:YES completion:^{}];
    }
    else {
        completion();
    }
}

- (BOOL)hasWifiForURL:(NSURL*)url {
    NSString *urlString = [url absoluteString];
    
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
            [[self buttonTouchID] setEnabled:YES];
            [[self activityIndicatorLogin] stopAnimating];
            
            return NO;
        }
    }
    
    return YES;
}

- (void)userLoginTouchID {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSURL *url = [userDefaults URLForKey:LSKeyURLTID];
    if (nil == url) {
        // TODO: handle error
        return;
    }
    NSString *username = [userDefaults stringForKey:LSKeyUsernameTID];
    
    // Check that wifi is on if needed
    if (false == [self hasWifiForURL:url]) {
        return;
    }
    
    // Disable login button and show activity indicator
    [[self buttonLogin] setEnabled:NO];
    [[self buttonTouchID] setEnabled:NO];
    [[self activityIndicatorLogin] startAnimating];
    
    if ([self hasTouchID]) {
        LAContext *context = [[LAContext alloc] init];
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:@"Authenticate to login" reply:^(BOOL success, NSError *authenticationError) {
            if (success) {
                [self authenticateUser:username forService:LSKeyServiceTID withURL:url];
            }
            else {
                // TODO: handle failure case
                NSLog(@"touch id fail");
                //message = [NSString stringWithFormat:@"evaluatePolicy: %@", authenticationError.localizedDescription];
            }
        }];
    }
}

- (void)userLogin {
    // Disable login button and show activity indicator
    [[self buttonLogin] setEnabled:NO];
    [[self buttonTouchID] setEnabled:NO];
    [[self activityIndicatorLogin] startAnimating];
    
    
    // Get URL, username, and password
    NSString *urlString = [[self tfURL] text]; //[NSURL URLWithString:[[self tfURL] text]];
    if (false == [[[urlString substringToIndex:4] lowercaseString] isEqualToString:@"http"]) {
        urlString = [NSString stringWithFormat:@"http://%@", urlString];
    }
    
    NSURL *const url = [NSURL URLWithString:urlString];
    NSString *const username = [[self tfUsername] text];
    NSString *const password = [[self tfPassword] text];
    
    // Check that wifi is on if needed
    if (false == [self hasWifiForURL:url]) {
        return;
    }
    
    // Get the user defaults
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    // Update URL is in user defaults
    [userDefaults setURL:url forKey:LSKeyURL];
    [userDefaults synchronize];
    
    // Update username in in user defaults
    [userDefaults setObject:username forKey:LSKeyUsername];
    [userDefaults synchronize];
    
    // Store the password in the keychain
    [SSKeychain setPassword:password forService:LSKeyService account:username];
    
    // Authenticate the user
    [self authenticateUser:username forService:LSKeyService withURL:url];
}

- (IBAction)login:(id)sender {
    [self userLogin];
}

- (IBAction)loginTouchID:(id)sender {
    [self userLoginTouchID];
}

- (IBAction)textFieldPasswordReturn:(id)sender {
    [sender resignFirstResponder];
    [self userLogin];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    if (0 == _sessionFailureCount) {
        // Get username and service
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *service = [userDefaults stringForKey:LSKeyServiceCurrent];
        NSString *username = [userDefaults stringForKey:LSKeyUsernameCurrent];
        
        // Get password from keychain
        NSString *password = [SSKeychain passwordForService:service account:username];
        
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
        [[self buttonTouchID] setEnabled:YES];
        [[self activityIndicatorLogin] stopAnimating];
    }];
    
    if (nil == error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            // Update user defaults for service and user
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            NSString *service = [userDefaults stringForKey:LSKeyServiceCurrent];
            NSString *username = [userDefaults stringForKey:LSKeyUsernameCurrent];
            [userDefaults setObject:service forKey:LSKeyService];
            [userDefaults setObject:username forKey:LSKeyUsername];
            [userDefaults synchronize];
            
            [self promptToUseTouchIDWithCompletion:^{
                [self performSegueWithIdentifier:@"loginSuccess" sender:self];
            }];
        }];
    }
    else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Unable to connect to server" message:@"Please check URL and network connection" preferredStyle:UIAlertControllerStyleAlert];
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
