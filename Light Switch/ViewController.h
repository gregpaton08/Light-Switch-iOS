//
//  ViewController.h
//  Light Switch
//
//  Created by Greg Paton on 11/23/15.
//  Copyright © 2015 Greg Paton. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

@property (strong, nonatomic) IBOutlet UIButton *buttonPressLightOn;
@property (strong, nonatomic) IBOutlet UIButton *buttonPressLightOff;

@end

