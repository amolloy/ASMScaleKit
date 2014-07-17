//
//  ASMUsersTableViewController.h
//  ASMScaleKit
//
//  Created by Andrew Molloy on 7/17/14.
//  Copyright (c) 2014 Andrew Molloy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASMScaleServiceProvider.h"

@interface ASMUsersTableViewController : UITableViewController
@property (nonatomic, strong) id<ASMScaleServiceProvider> provider;
@end
