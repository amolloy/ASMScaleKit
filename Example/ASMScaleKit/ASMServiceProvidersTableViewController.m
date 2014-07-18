//
//  ASMServiceProvidersTableViewController.m
//  ASMScaleKit
//
//  Created by Andrew Molloy on 7/16/14.
//  Copyright (c) 2014 Andrew Molloy. All rights reserved.
//

#import "ASMServiceProvidersTableViewController.h"
#import "ASMUsersTableViewController.h"
#import <ASMScaleKit/ASKProviderManager.h>
#import <ASMScaleKit/ASKServiceProvider.h>

@interface ASMServiceProvidersTableViewController ()

@end

@implementation ASMServiceProvidersTableViewController

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[ASKProviderManager sharedManager] serviceProviders].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ScaleServiceProviderCell"
															forIndexPath:indexPath];
    
	ASKServiceProvider* serviceProvider = [[ASKProviderManager sharedManager] serviceProviders][indexPath.row];
	cell.textLabel.text = [serviceProvider displayName];

    return cell;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"SelectServiceProvider"])
	{
		ASMUsersTableViewController* dest = (ASMUsersTableViewController*)segue.destinationViewController;
		NSIndexPath* indexPath = [self.tableView indexPathForSelectedRow];
		dest.provider = [[ASKProviderManager sharedManager] serviceProviders][indexPath.row];
	}
}

@end
