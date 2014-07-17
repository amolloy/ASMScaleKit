//
//  ASMUsersTableViewController.m
//  ASMScaleKit
//
//  Created by Andrew Molloy on 7/17/14.
//  Copyright (c) 2014 Andrew Molloy. All rights reserved.
//

#import "ASMUsersTableViewController.h"
#import "ASMScaleKit/ASMScaleUser.h"
#import "ASMScaleDataTableViewController.h"

@interface ASMUsersTableViewController ()
@property (nonatomic, strong) NSArray* users;
@end

@implementation ASMUsersTableViewController

- (NSString*)usersKey
{
	return [@"com.amolloy.scalekit." stringByAppendingString:[self.provider displayName]];
}

- (void)saveUsers
{
	__block NSMutableArray* plistUsers = [NSMutableArray arrayWithCapacity:self.users.count];
	[self.users enumerateObjectsUsingBlock:^(id<ASMScaleUser> user, NSUInteger idx, BOOL *stop) {
		NSData* userData = [NSKeyedArchiver archivedDataWithRootObject:user];

		if (userData)
		{
			[plistUsers addObject:userData];
			[user storeSensitiveInformationInKeychain:nil];
		}
	}];

	[[NSUserDefaults standardUserDefaults] setObject:plistUsers.copy
											  forKey:[self usersKey]];
}

- (void)loadUsers
{
	NSArray* plistUsers = [[NSUserDefaults standardUserDefaults] arrayForKey:[self usersKey]];
	__block NSMutableArray* users = [NSMutableArray arrayWithCapacity:plistUsers.count];

	[plistUsers enumerateObjectsUsingBlock:^(NSData* userData, NSUInteger idx, BOOL *stop) {
		id<ASMScaleUser> user = [NSKeyedUnarchiver unarchiveObjectWithData:userData];
		if (user)
		{
			[user retrieveSensitiveInformationFromKeychain:nil];
			[users addObject:user];
		}
	}];

	self.users = users.copy;
}

- (IBAction)addUser:(id)sender
{
	[self.provider authenticateFromViewController:self
								   withCompletion:^(NSArray* users, NSError* error) {
									   if (error)
									   {
										   NSLog(@"Error: %@", error);
									   }
									   else
									   {
										   self.users = [self.users arrayByAddingObjectsFromArray:users];
										   [self saveUsers];
										   [self.tableView reloadData];
									   }
								   }];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	[self loadUsers];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self loadUsers];
	[self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];

	id<ASMScaleUser> user = self.users[indexPath.row];

	cell.textLabel.text = [user displayName];
	cell.detailTextLabel.text = [user authenticated] ? @"Authenticated" : @"Not Authenticated";

    return cell;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"ListMeasurements"])
	{
		ASMScaleDataTableViewController* dest = (ASMScaleDataTableViewController*)segue.destinationViewController;
		NSIndexPath* indexPath = [self.tableView indexPathForSelectedRow];
		dest.user = self.users[indexPath.row];
	}
}

@end
