//
//  ASMScaleServiceProvider.h
//  Pods
//
//  Created by Andrew Molloy on 7/11/14.
//
//

#import <Foundation/Foundation.h>

@protocol ASMScaleUser;

@protocol ASMScaleServiceProvider <NSObject>

/**
 *	Returns the logged in status for the service provider.
 *
 *	@return YES if the service provider is logged in and does not need authentication.
 *	This method is temporary and will be removed when multi-user accounts support is added.
 */
- (BOOL)loggedIn;

/**
 *	Log the account out of the service provider (if appropriate).
 */
- (void)logout;

/**
 *	Returns a name for this provider appropriate for display in a user interface;
 *
 *	@return a name for this provider appropriate for display in a user interface;
 */
- (NSString*)displayName;

/**
 *	Returns the class this provider uses to represent users.
 *
 *	@return the class this provider uses to represent users.
 */
- (Class)userClass;

/**
 *	Completion handler for authenticating a scale service provider.
 *
 *	@param users If authentication succeeded, contains a list of available ASMScaleUsers for this service.
 *	@param error If authentication failed, a service-provider-specific error, nil otherwise.
 */
typedef void(^ASMScaleServiceProviderAuthenticationHandler)(NSArray* users, NSError* error);

/**
 *	Authenticates against the scale service provider. If appropriate, this also retrieves a list of users
 *	available for the logged in account.
 *
 *	@param viewController If the service provider needs to present a UI to perform authentication, it 
 *	will be presented through viewController.
 *	@param completion Called upon completion of the authentication request. If authentication failed,
 *	an error will be provided in error. If the service provider has a concept of users, then a list
 *	of the available users will be provided in users.
 */
- (void)authenticateFromViewController:(UIViewController*)viewController
						withCompletion:(ASMScaleServiceProviderAuthenticationHandler)completion;

/**
 *	Completion handler for retrieving the latest entries for a user from a service provider.
 *
 *	@param entries If the update succeded, contains a list of entries for the user. The entries
 *	will be stored as HKQuantity objects.
 *	@param error   If the update failed, a service-provider-specific error, nil otherwise.
 */
typedef void(^ASMScaleServiceProviderUpdateEntriesHandler)(NSArray* entries, NSError* error);

/**
 *	Retrieves all of the entries for a user from the service provider after a specified date.
 *
 *	@param user       The user whose data is to be retrieved.
 *	@param startDate  The start date to filter entries on. If specified, only entries after the given date
 *	will be returned. Pass nil to retrieve all entries for the user regardless of date (or however many the 
 *	service provider will vend).
 *	@param endDate    The end date to filter entries on. If specified, only entries before the given date
 *  will be returned. Pass nil to retreive all entries for the user regardless of the end date (or however
 *	many the service provider will vend).
 *	@param lastUpdate This can be use to filter entries by when they were created or modified instead of 
 *	their associated date. If this is supplied and the service provider supports it, only entries that
 *  have been added or modified since this date will be returned.
 *	@param completion Called upon completion of the update request. If the update succeeded, the
 *	entries array will contain all entries for the given user after the specified date. If an error 
 *	occurred, error will contain information about that error.
 *
 *	Note: If an underlying service limits the number of entries that may be retrieved in a single
 *	request, it is up to the implementor of ASMScaleServiceProvider to batch the update requests.
 *	The completion handler should not be called until all entries have been retrieved.
 */
- (void)getEntriesForUser:(id<ASMScaleUser>)user
				 fromDate:(NSDate*)startDate
				   toDate:(NSDate*)endDate
			   lastUpdate:(NSDate*)lastUpdate
					limit:(NSNumber*)limit
				   offset:(NSNumber*)offset
			   completion:(ASMScaleServiceProviderUpdateEntriesHandler)completion;

@end
