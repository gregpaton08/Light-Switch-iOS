//
//  LSSwitchTableViewCell.m
//  Light Switch
//
//  Created by Greg Paton on 11/30/15.
//  Copyright © 2015 Greg Paton. All rights reserved.
//

#import "LSSwitchTableViewCell.h"

@import UIKit;

@implementation LSSwitchTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        [self setCellSwitch:[[UISwitch alloc] initWithFrame:CGRectZero]];
        [self setAccessoryView:[self cellSwitch]];
        
        [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    
    return self;
}

- (BOOL)getSwithState {
    if ([self cellSwitch]) {
        return [[self cellSwitch ] isOn];
    }
    
    return false;
}

- (void)addAction:(SEL)action {
    [[self cellSwitch] addTarget:nil action:action forControlEvents:UIControlEventValueChanged];
}

- (void)setTarget:(id)target action:(SEL)action {
    [[self cellSwitch] addTarget:target action:action forControlEvents:UIControlEventValueChanged];
}

+ (NSString*)getIdentifier {
    return @"LSSwitchTableViewCellIdentifier";
}

#pragma mark -NSCoding methods

-(void)encodeWithCoder:(NSCoder *)encoder{
    [encoder encodeInteger:[self tag] forKey:@"tag"];
    [encoder encodeObject:[self textLabel] forKey:@"textLabel"];
//    [encoder encodeObject:self.difficulty forKey:@"difficulty"];
//    [encoder encodeObject:self.language forKey:@"language"];
//    [encoder encodeObject:self.category forKey:@"category"];
//    [encoder encodeObject:self.playerType forKey:@"playerType"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithStyle:0 reuseIdentifier:[LSSwitchTableViewCell getIdentifier]];
    if (self) {
        [self setTag:[decoder decodeIntegerForKey:@"tag"]];
        [[self textLabel] setText:[decoder decodeObjectForKey:@"textLabel"]];
    }
    
    return self;
}

@end
