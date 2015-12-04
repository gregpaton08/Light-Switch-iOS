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
#import "LSSwitchTableViewCell.h"

@interface ViewController ()

@end

@implementation ViewController

#pragma mark - UIViewController methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _sessionFailureCount = 0;
    
    [[self tableViewSwitches] registerClass:[LSSwitchTableViewCell class] forCellReuseIdentifier:[LSSwitchTableViewCell getIdentifier]];
    
    tableData = [NSArray arrayWithObjects:@"test1", @"test2", nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Light switch methods

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

#pragma mark - User interaction methods

- (void)logout {
    [self performSegueWithIdentifier:@"logout" sender:self];
}

- (void)promptUserToLogout {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invalid username and password" message:@"Please try logging in again" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *actionOkay = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self logout];
        }];
    }];
    
    [alert addAction:actionOkay];
    [self presentViewController:alert animated:YES completion:^{}];
}

#pragma mark - IBAction methods

- (IBAction)buttonPressLightOn:(id)sender {
    [self lightSwitch:YES];
}

- (IBAction)buttonPressLightOff:(id)sender {
    [self lightSwitch:NO];
}

- (IBAction)buttonPressLogout:(id)sender {
    [self logout];
}

- (IBAction)buttonPressInsert:(id)sender {
    tableData = [tableData arrayByAddingObject:@"Test"];
    [[self tableViewSwitches] reloadData];
}

- (IBAction)buttonPressAddSwitch:(id)sender {
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
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
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self promptUserToLogout];
        }];
        
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        
        _sessionFailureCount = 0;
        return;
    }
    
    ++_sessionFailureCount;
}

#pragma mark - NSURLSessionTaskDelegate methods

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
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
    
    _sessionFailureCount = 0;
}

#pragma mark - Table View delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [tableData count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LSSwitchTableViewCell *cell = (LSSwitchTableViewCell*)[tableView dequeueReusableCellWithIdentifier:[LSSwitchTableViewCell getIdentifier] forIndexPath:indexPath];
    if (cell == nil) {
        
    }
    
    [[cell textLabel] setText:[tableData objectAtIndex:indexPath.row]];
    
    return cell;
}

@end
