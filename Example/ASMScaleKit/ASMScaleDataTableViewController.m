//
//  ASMScaleDataTableViewController.m
//  ASMScaleKit
//
//  Created by Andrew Molloy on 7/12/14.
//  Copyright (c) 2014 Andrew Molloy. All rights reserved.
//

#import "ASMScaleDataTableViewController.h"
#import <ASMScaleKit/ASMScaleManager.h>
#import <ASMScaleKit/ASMScaleUser.h>
#import <ASMScaleKit/ASMScaleServiceProvider.h>

@interface ASMScaleDataTableViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSArray* measurements;
@end

@implementation ASMScaleDataTableViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	[self.refreshControl beginRefreshing];
	[self reloadData];
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
	self.refreshControl = refreshControl;
	[self.refreshControl addTarget:self
							action:@selector(reloadData)
				  forControlEvents:UIControlEventValueChanged];
}

- (void)reloadData
{
	id<ASMScaleServiceProvider> provider = [[ASMScaleManager sharedManager] serviceProviderForUser:self.user];

	[provider getEntriesForUser:self.user
					   fromDate:nil
						 toDate:nil
					 lastUpdate:nil
						  limit:nil
						 offset:nil
					 completion:^(NSArray *entries, NSError *error) {
						 self.measurements = entries;
						 [self.tableView reloadData];
						 [self.refreshControl endRefreshing];
					 }];
}

- (IBAction)logout:(id)sender
{
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.measurements.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MeasurementCell" forIndexPath:indexPath];

	/*
	HKQuantity* quant = self.measurements[indexPath.row];

	id<ASMScaleUser> user = self.users[indexPath.row];

	cell.textLabel.text = [user displayName];
	cell.detailTextLabel.text = [user authenticated] ? @"Authenticated" : @"Not Authenticated";
	 */

    return cell;
}



@end
