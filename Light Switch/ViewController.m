//
//  ViewController.m
//  Light Switch
//
//  Created by Greg Paton on 11/23/15.
//  Copyright © 2015 Greg Paton. All rights reserved.
//

#import "ViewController.h"
#import "KeychainWrapper.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)lightSwitch:(BOOL)on {
    // Get the user defaults
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSURL *defaultURL = [userDefaults URLForKey:@"url"];
    //NSURL *url;// = [defaultURL URLByAppendingPathComponent:@"/light_on"];
    NSString *urlString;
    if (on) {
        urlString = @"http://192.168.0.105:3333/light_on";
        //url = [NSURL URLWithString:@"192.168.0.105:3333/light_on"];
        //url = [defaultURL URLByAppendingPathComponent:@"/light_on"];
    }
    else {
        urlString = @"http://192.168.0.105:3333/light_off";
        //url = [NSURL URLWithString:@"192.168.0.105:3333/light_off"];
        //url = [defaultURL URLByAppendingPathComponent:@"/light_off"];
    }
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionDataTask *downloadTask = [session dataTaskWithURL:url];
    [downloadTask resume];
}

- (IBAction)buttonPressLightOn:(id)sender {
    [self lightSwitch:YES];
}

- (IBAction)buttonPressLightOff:(id)sender {
    [self lightSwitch:NO];
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    KeychainWrapper *keychainWrapper = [[KeychainWrapper alloc] init];
    NSString *password = [keychainWrapper myObjectForKey:(__bridge id)kSecValueData];
    //[keychainWrapper mySetObject:password forKey:(__bridge id)kSecValueData];
    
    NSURLCredential *credentials = [NSURLCredential credentialWithUser:@"gpaton" password:password persistence:NSURLCredentialPersistenceNone];
    completionHandler(NSURLSessionAuthChallengeUseCredential, credentials);
}

@end
