//
//  ASMServiceProvidersTableViewController.m
//  ASMScaleKit
//
//  Created by Andrew Molloy on 7/12/14.
//  Copyright (c) 2014 Andrew Molloy. All rights reserved.
//

#import "ASMServiceProvidersTableViewController.h"
#import "ASMScaleDataTableViewController.h"
#import <ASMScaleKit/ASMWithingsServiceProvider.h>

@implementation ASMServiceProvidersTableViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	id<ASMScaleServiceProvider> provider = nil;

	if ([segue.identifier isEqualToString:@"Withings"])
	{
		NSDictionary* keysDict = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"WithingsKeys" withExtension:@"plist"]];

		provider = [[ASMWithingsServiceProvider alloc] initWithOAuthKey:keysDict[@"key"]
																 secret:keysDict[@"secret"]];
	}

	ASMScaleDataTableViewController* destination = (ASMScaleDataTableViewController*)segue.destinationViewController;
	destination.provider = provider;
}

@end
