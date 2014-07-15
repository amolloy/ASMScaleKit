//
//  ASMScaleDataTableViewController.m
//  ASMScaleKit
//
//  Created by Andrew Molloy on 7/12/14.
//  Copyright (c) 2014 Andrew Molloy. All rights reserved.
//

#import "ASMScaleDataTableViewController.h"

@interface ASMScaleDataTableViewController () <UITableViewDataSource, UITableViewDelegate>
@end

@implementation ASMScaleDataTableViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	if (![self.provider loggedIn])
	{
		[self login];
	}
}

- (void)login
{
	[self.provider authenticateFromViewController:self
								   withCompletion:^(NSArray* users, NSError* error) {
									   if (error)
									   {
										   NSLog(@"Error: %@", error);
									   }
									   else
									   {
										   NSLog(@"Got users: %@", users);
									   }
								   }];
}

- (IBAction)logout:(id)sender
{
	[self.provider logout];
	[self login];
}


@end
