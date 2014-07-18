//
//  ASMScaleDataTableViewController.h
//  ASMScaleKit
//
//  Created by Andrew Molloy on 7/12/14.
//  Copyright (c) 2014 Andrew Molloy. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ASKUser;

@interface ASMScaleDataTableViewController : UITableViewController
@property (nonatomic, strong) id<ASKUser> user;
@end
