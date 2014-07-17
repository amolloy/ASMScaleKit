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
#import <ASMScaleKit/ASMScaleKitMeasurement.h>

@interface ASMScaleDataTableViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSArray* measurements;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
@property (nonatomic, strong) NSNumberFormatter* weightFormatter;
@end

@implementation ASMScaleDataTableViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	self.dateFormatter = [[NSDateFormatter alloc] init];
	self.dateFormatter.timeStyle = NSDateFormatterNoStyle;
	self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;

	self.weightFormatter = [[NSNumberFormatter alloc] init];
	self.weightFormatter.maximumFractionDigits = 2;

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

	ASMScaleKitMeasurement* measurement = self.measurements[indexPath.row];

	cell.textLabel.text = [self.dateFormatter stringFromDate:measurement.date];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ kg", [self.weightFormatter stringFromNumber:measurement.weightInKg]];

    return cell;
}



@end
