//
//  ASMScaleDataTableViewController.m
//  ASMScaleKit
//
//  Created by Andrew Molloy on 7/12/14.
//  Copyright (c) 2014 Andrew Molloy. All rights reserved.
//

#import "ASMScaleDataTableViewController.h"
#import <ASMScaleKit/ASKUser.h>
#import <ASMScaleKit/ASKMeasurement.h>
#if ASKHealthKitAvailable
#import <HealthKit/HealthKit.h>
#endif

@interface ASMScaleDataTableViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSArray* measurements;
@property (nonatomic, strong) NSDateFormatter* dateFormatter;
@property (nonatomic, strong) NSNumberFormatter* weightFormatter;
#if ASKHealthKitAvailable
@property (nonatomic, strong) NSMassFormatter* weightMassFormatter;
#endif
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

#if ASKHealthKitAvailable
	if (NSClassFromString(@"NSMassFormatter"))
	{
		self.weightMassFormatter = [[NSMassFormatter alloc] init];
		self.weightMassFormatter.forPersonMassUse = YES;
	}
#endif

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
	[self.user getEntriesFromDate:nil
						   toDate:nil
					   lastUpdate:nil
							limit:nil
						   offset:nil
					   completion:^(NSArray *entries, NSError *error) {
						   if (!error)
						   {
							   self.measurements = entries;
							   dispatch_async(dispatch_get_main_queue(), ^{
								   [self.tableView reloadData];
								   [self.refreshControl endRefreshing];
							   });
						   }
						   else
						   {
							   NSLog(@"Error: %@", error);
						   }
					   }];
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

	ASKMeasurement* measurement = self.measurements[indexPath.row];

	cell.textLabel.text = [self.dateFormatter stringFromDate:measurement.date];
#if ASKHealthKitAvailable
	if (self.weightMassFormatter)
	{
		cell.detailTextLabel.text = [self.weightMassFormatter stringFromKilograms:[measurement.weight doubleValueForUnit:[HKUnit gramUnitWithMetricPrefix:HKMetricPrefixKilo]]];
	}
	else
#endif
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ kg", [self.weightFormatter stringFromNumber:measurement.weightInKg]];

    return cell;
}



@end
