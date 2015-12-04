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

#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

@import LocalAuthentication;

@interface LoginViewController ()

@end

@implementation LoginViewController

#pragma mark - UIViewController methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _sessionFailureCount = 0;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    // If a URL has been saved then load it into the text field
    NSURL *defaultURL = [userDefaults URLForKey:LSKeyURL];
    if (defaultURL) {
        [[self tfURL] setText:[defaultURL absoluteString]];
    }
    
    // If a username has been saved then load it into the text field
    NSString *defaultUsername = [userDefaults stringForKey:LSKeyUsername];
    if (defaultUsername) {
        [[self tfUsername] setText:defaultUsername];
    }
    
    // If credentials for touch ID have been stored then prompt user to login via touch ID
    if ([userDefaults stringForKey:LSKeyUsernameTID] &&
        [userDefaults stringForKey:LSKeyURLTID] &&
        [userDefaults boolForKey:@"appLaunch"] &&
        [userDefaults boolForKey:@"storeCredentialsTouchID"]) {
        [self userLoginTouchID];
    }
    // Else if credentials have not yet been stored for touch ID then disable touch ID
    else if (false == [userDefaults boolForKey:@"storeCredentialsTouchID"]) {
        [[self buttonTouchID] setEnabled:NO];
    }
    
    // Set flag to signal that the app has now launched for the first time
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

#pragma mark - Authentication methods

- (void)authenticateUser:(NSString*)user forService:(NSString*)service withURL:(NSURL*)url {
    _sessionFailureCount = 0;
    
    // Set current service and username
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:service forKey:LSKeyServiceCurrent];
    [userDefaults setObject:user forKey:LSKeyUsernameCurrent];
    [userDefaults synchronize];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    
    [self setUrlSessionTask:[session dataTaskWithURL:url]];
    [[self urlSessionTask] resume];
}

- (void) cancelAuthentication {
    if ([self urlSessionTask]) {
        [[self urlSessionTask] cancel];
    }
}

#pragma mark - User interaction methods

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
        NSString *passwordTouchID = [SSKeychain passwordForService:LSServiceLoginTID account:username];
        
        BOOL useTouchID = [userDefaults boolForKey:LSKeyTouchIDCredentials];
        
        // If touch ID is not in use then prompt user to store credentials for touch ID
        if (false == useTouchID) {
            title = @"Store these credentials with Touch ID?";
            message = @"Any user with Touch ID will be able to login";
            promptUser = YES;
        }
        // Else if new credentials are entered prompt the user to update the touch ID credentials
        else if (false == [defaultURL isEqual:[userDefaults URLForKey:LSKeyURLTID]] ||
                 false == [username isEqualToString:[userDefaults stringForKey:LSKeyUsernameTID]] ||
                 false == [password isEqualToString:passwordTouchID]) {
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
            NSString *password = [SSKeychain passwordForService:LSServiceLogin account:username];
            [SSKeychain setPassword:password forService:LSServiceLoginTID account:username];
            
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

- (void)setActivityIndicator:(BOOL)active {
    [[self buttonTouchID] setEnabled:!active];
    
    if (active) {
        [[self buttonLogin] setTitle:@"Cancel" forState:UIControlStateNormal];
        [[self activityIndicatorLogin] startAnimating];
    }
    else {
        [[self buttonLogin] setTitle:@"Login" forState:UIControlStateNormal];
        [[self activityIndicatorLogin] stopAnimating];
    }
}

- (void)displaySimpleAlertWithTitle:(NSString*)title withMessage:(NSString*)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Login methods

- (void)getIpAddress {
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    struct ifaddrs *interfaces;
    if (!getifaddrs(&interfaces)) {
        struct ifaddrs *interface;
        for (interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if (addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if (addr->sin_family == AF_INET) {
                    if (inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                }
                else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if (inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if (type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
    }
    
    freeifaddrs(interfaces);
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
            
            [self setActivityIndicator:NO];
            
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
    
    [self setActivityIndicator:YES];
    
    LAContext *context = [[LAContext alloc] init];
    // Check if touch ID is available
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil]) {
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:@"Authenticate to login" reply:^(BOOL success, NSError *authenticationError) {
            if (success) {
                [self authenticateUser:username forService:LSServiceLoginTID withURL:url];
            }
            else {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self setActivityIndicator:NO];
                }];
            }
        }];
    }
}

- (void)userLogin {
    [self setActivityIndicator:YES];
    
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
    [SSKeychain setPassword:password forService:LSServiceLogin account:username];
    
    // Authenticate the user
    [self authenticateUser:username forService:LSServiceLogin withURL:url];
}

# pragma mark - IBAction methods

- (IBAction)login:(id)sender {
    
    [self performSegueWithIdentifier:@"loginSuccess" sender:self];
//    NSString *title = [[sender titleLabel] text];
//    if ([title isEqualToString:@"Login"]) {
//        [self userLogin];
//    }
//    else if ([title isEqualToString:@"Cancel"]) {
//        [self cancelAuthentication];
//    }
}

- (IBAction)loginTouchID:(id)sender {
        [self userLoginTouchID];
}

- (IBAction)textFieldPasswordReturn:(id)sender {
    [sender resignFirstResponder];
    [self userLogin];
}

- (IBAction)backgroundTouch:(id)sender {
    [self.view endEditing:YES];
}

#pragma mark - NSURLSessionDataDelegate methods

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
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self displaySimpleAlertWithTitle:@"Incorrect username or password" withMessage:@"Try again"];
        }];
        
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        _sessionFailureCount = 0;
        
        return;
    }
    
    ++_sessionFailureCount;
}

#pragma mark - NSURLSessionTaskDelegate methods

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    // Stop progress animation
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self setActivityIndicator:NO];
    }];
    
    // If no error logging in then segue to the next view
    if (nil == error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            // Update user defaults for username
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            NSString *username = [userDefaults stringForKey:LSKeyUsernameCurrent];
            [userDefaults setObject:username forKey:LSKeyUsername];
            [userDefaults synchronize];
            
            [self promptToUseTouchIDWithCompletion:^{
                [self performSegueWithIdentifier:@"loginSuccess" sender:self];
            }];
        }];
    }
    // If task was not cancelled by the user then report error
    else if ([error code] != NSURLErrorCancelled) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self displaySimpleAlertWithTitle:@"Unable to connect to server" withMessage:@"Please check URL and network connection"];
        }];
        NSLog(@"%zd", [error code]);
    }
}

@end
