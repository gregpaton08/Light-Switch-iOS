//
//  ViewController.m
//  Light Switch
//
//  Created by Greg Paton on 11/23/15.
//  Copyright © 2015 Greg Paton. All rights reserved.
//

#import "ViewController.h"
#import "Constants.h"
#import "SSKeychain.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _sessionFailureCount = 0;
    
    // Hide cancle button until needed
    [[self buttonCancel] setHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)lightSwitch:(BOOL)on {
    // Get the user defaults
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSURL *defaultURL = [userDefaults URLForKey:LSKeyURL];
    NSURL *url;
    if (on) {
        url = [defaultURL URLByAppendingPathComponent:@"/light_on"];
    }
    else {
        url = [defaultURL URLByAppendingPathComponent:@"/light_off"];
    }
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    
    [self setUrlSessionTask:[session dataTaskWithURL:url]];
    [[self urlSessionTask] resume];
}

- (void)setActivityIndicator:(BOOL)active {
    [[self buttonOn] setEnabled:!active];
    [[self buttonOff] setEnabled:!active];
    [[self buttonCancel] setHidden:!active];
    
    if (active) {
        [[self activityIndicatorLightSwitch] startAnimating];
    }
    else {
        [[self activityIndicatorLightSwitch] stopAnimating];
    }
}

- (IBAction)buttonPressLightOn:(id)sender {
    [self setActivityIndicator:YES];
    [self lightSwitch:NO];
    //[self lightSwitch:YES];
}

- (IBAction)buttonPressLightOff:(id)sender {
    [self setActivityIndicator:YES];
    [self lightSwitch:NO];
}

- (IBAction)buttonPressLogout:(id)sender {
    [self performSegueWithIdentifier:@"logout" sender:self];
}

- (IBAction)buttonPressCancel:(id)sender {
    [[self urlSessionTask] cancel];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    // Stop activity indicator
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self setActivityIndicator:NO];
    }];
    
    if (0 == _sessionFailureCount) {
        // Get username from user defaults
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *service = [userDefaults stringForKey:LSKeyServiceCurrent];
        NSString *username = [userDefaults stringForKey:LSKeyUsername];
        
        // Get password from keychain
        NSString *password = [SSKeychain passwordForService:service account:username];
        
        // Authenticate user
        NSURLCredential *credentials = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistenceNone];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credentials);
    }
    else {
//        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//            [self displaySimpleAlertWithTitle:@"Incorrect username or password" withMessage:@"Try again"];
//        }];
        
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        
        _sessionFailureCount = 0;
        return;
    }
    
    // TODO: handle authenctication failure case
    
    ++_sessionFailureCount;
}

#pragma mark - NSURLSessionTaskDelegate methods

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    // Stop progress animation
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self setActivityIndicator:NO];
    }];
    
    if (nil != error && [[error domain] isEqualToString:NSURLErrorDomain]) {
        switch ([error code]) {
            case NSURLErrorCancelled:
                NSLog(@"cancelled");
                break;
            case NSURLErrorTimedOut:
                NSLog(@"timed out");
                break;
            case NSURLErrorNetworkConnectionLost:
                NSLog(@"lost network connection");
                break;
            case NSURLErrorNotConnectedToInternet:
                NSLog(@"not connected to internet");
                break;
        }
    }
}

@end
