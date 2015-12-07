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
#import "LSSwitchInfo.h"

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
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [defaults objectForKey:LSKeySwitchTableInfo];
    if (data) {
        NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        [self setSwitchTableData:[dict mutableCopy]];
    }
    else {
        [self setSwitchTableData:[[NSMutableDictionary alloc] init]];
    }
    
    [self setSwitchTableDataLock:[[NSLock alloc] init]];
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
    NSNumber *tag = [NSNumber numberWithUnsignedInteger:[[self switchTableData] count]];
    LSSwitchInfo *switchInfo = [[LSSwitchInfo alloc] init];
    [switchInfo setTitle:@"test"];
    [switchInfo setTag:[tag integerValue]];
    [switchInfo setStatus:false];
    
    [[self switchTableDataLock] lock];
    [[self switchTableData] setObject:switchInfo forKey:tag];
    [[self switchTableDataLock] unlock];
    
    [[self tableViewSwitches] reloadData];
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
    return [[self switchTableData] count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LSSwitchTableViewCell *cell = (LSSwitchTableViewCell*)[tableView dequeueReusableCellWithIdentifier:[LSSwitchTableViewCell getIdentifier] forIndexPath:indexPath];
    if (cell) {
        LSSwitchInfo *switchInfo = (LSSwitchInfo*)[[self switchTableData] objectForKey:[NSNumber numberWithInteger:indexPath.row]];
        [[cell textLabel] setText:[switchInfo title]];
        [cell setTag:[switchInfo tag]];
        UISwitch *cellSwitch = (UISwitch*)[cell accessoryView];
        if (cellSwitch) {
            [cellSwitch setOn:[switchInfo status]];
        }
        [cell setTarget:self action:@selector(switchChanged:)];
    }
    
    return cell;
}

- (void) switchChanged:(id)sender {
    UISwitch* switchControl = sender;
    NSLog( @"The switch %zd is %@", [switchControl tag], switchControl.on ? @"ON" : @"OFF" );
    
    [self lightSwitch:[switchControl isOn]];
    
    [[self switchTableDataLock] lock];
    LSSwitchInfo *switchInfo = [[self switchTableData] objectForKey:[NSNumber numberWithInteger:[switchControl tag]]];
    [switchInfo setStatus:[switchControl isOn]];
    [[self switchTableDataLock] unlock];
}

@end
