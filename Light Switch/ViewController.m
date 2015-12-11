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
    
    [self loadSwitchTableData];
    
    [self setSwitchTableDataLock:[[NSLock alloc] init]];
    
    [self setAvailableSwitches:[[NSMutableArray alloc] init]];
    [self setAvailableSwitchesLock:[[NSLock alloc] init]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[self switchTableData]];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:data forKey:LSKeySwitchTableInfo];
}

#pragma mark - Light switch methods

- (void)lightSwitch:(BOOL)on {
    NSURL *defaultURL = [self getDefaultURL];
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

- (void)getSwitches {
    NSURL *defaultURL = [self getDefaultURL];
    NSURL *url = [defaultURL URLByAppendingPathComponent:@"/switches/API/v1.0/switches"];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSError *err = nil;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&err];
        NSLog(@"%@", jsonDict);
        
        [[self availableSwitchesLock] lock];
        
        NSLog(@"%@", jsonDict);
        
        //NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        //[dict setObject:@"value" forKey:@"key"];
        
        [[self availableSwitchesLock] unlock];
    }];
    
    [dataTask resume];
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
    [self.navigationItem setLeftBarButtonItem:nil animated:NO];
    self.navigationController.navigationBar.backItem.hidesBackButton = YES;
    self.navigationItem.hidesBackButton = YES;
    
    [self setNavigationItemEdit:[[self navigationBarSwitches] popNavigationItemAnimated:YES]];
    
    //[self getSwitches];
}

- (IBAction)buttonPressLightOff:(id)sender {
    [self lightSwitch:NO];
    if ([self navigationItemEdit]) {
        [[self navigationBarSwitches] pushNavigationItem:[self navigationItemEdit] animated:YES];
    }
}

- (IBAction)buttonPressLogout:(id)sender {
    [self logout];
}

- (IBAction)buttonPressAddSwitch:(id)sender {
    NSNumber *tag = [NSNumber numberWithUnsignedInteger:[[self switchTableData] count]];
    LSSwitchInfo *switchInfo = [[LSSwitchInfo alloc] init];
    [switchInfo setTitle:@"test"];
    [switchInfo setTag:[tag integerValue]];
    [switchInfo setStatus:false];
    
    [[self switchTableDataLock] lock];
    //[[self switchTableData] setObject:switchInfo forKey:tag];
    [[self switchTableDataLock] unlock];
    
    [[self tableViewSwitches] reloadData];
}

- (IBAction)buttonPressEdit:(id)sender {
    if (0 == [[self switchTableData] count]) {
        return;
    }
    
    [[self tableViewSwitches] setEditing:![[self tableViewSwitches] isEditing] animated:YES];
    
    UIBarButtonItem *barButtonItem = (UIBarButtonItem*)sender;
    if ([[self tableViewSwitches] isEditing]) {
        [barButtonItem setTitle:@"Done"];
    }
    else {
        [barButtonItem setTitle:@"Edit"];
    }
}

- (void)addSwitchWithTitle:(NSString *)title withSwitchName:(NSString *)name {
    [self loadSwitchTableData];
    LSSwitchInfo *switchInfo = [[LSSwitchInfo alloc] init];
    [switchInfo setTitle:title];
    [switchInfo setUrl:name];
    [switchInfo setTag:[[self switchTableData] count]];    
    [[self switchTableData] addObject:switchInfo];
    [self saveSwitchTableData];
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
/*
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
}
*/
/*
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
}
*/
#pragma mark - Table View delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self switchTableData] count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LSSwitchTableViewCell *cell = (LSSwitchTableViewCell*)[tableView dequeueReusableCellWithIdentifier:[LSSwitchTableViewCell getIdentifier] forIndexPath:indexPath];
    if (cell) {
        LSSwitchInfo *switchInfo = (LSSwitchInfo*)[[self switchTableData] objectAtIndex:indexPath.row];
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

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (UITableViewCellEditingStyleDelete == editingStyle) {
        [[self switchTableData] removeObjectAtIndex:indexPath.row];
        [self saveSwitchTableData];
        [[self tableViewSwitches] reloadData];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void) switchChanged:(id)sender {
    UISwitch* switchControl = sender;
    NSLog( @"The switch %zd is %@", [switchControl tag], switchControl.on ? @"ON" : @"OFF" );
    
    //[self lightSwitch:[switchControl isOn]];
    
    [[self switchTableDataLock] lock];
    LSSwitchInfo *switchInfo = [[self switchTableData] objectAtIndex:[switchControl tag]];
    [switchInfo setStatus:[switchControl isOn]];
    [[self switchTableDataLock] unlock];
}

- (void)saveSwitchTableData {
    [[self switchTableDataLock] lock];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[self switchTableData]];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:data forKey:LSKeySwitchTableInfo];
    [defaults synchronize];
    [[self switchTableDataLock] unlock];
}

- (void)loadSwitchTableData {
    [[self switchTableDataLock] lock];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [defaults objectForKey:LSKeySwitchTableInfo];
    NSDictionary *dict = nil;
    if (data) {
        dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    
    if (dict) {
        [self setSwitchTableData:[dict mutableCopy]];
    }
    else {
        [self setSwitchTableData:[[NSMutableArray alloc] init]];
    }
    [[self switchTableDataLock] unlock];
}

#pragma mark - Helper methods

- (NSURL*)getDefaultURL {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults URLForKey:LSKeyURL];
}

@end
