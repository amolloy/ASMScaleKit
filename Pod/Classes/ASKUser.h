//
//  ASMScaleUser.h
//  Pods
//
//  Created by Andrew Molloy on 7/11/14.
//
//

#import <Foundation/Foundation.h>

/**
 *	Represents an individual (user) of a particular service.
 */
@protocol ASKUser <NSObject, NSSecureCoding>

/**
 *	A string representing this user appropriate for displaying in a user interface.
 *	Depending on the provider, this could be a username, first name / last name combo,
 *	etc.
 *
 *	@return a string for this user appropriate for displaying in a user interface.
 */
- (NSString*)displayName;

/**
 *	Retrieves all of the entries for a user from the service provider after a specified date.
 *
 *	@param startDate  The start date to filter entries on. If specified, only entries after the given date
 *	will be returned. Pass nil to retrieve all entries for the user regardless of date (or however many the
 *	service provider will vend).
 *	@param endDate    The end date to filter entries on. If specified, only entries before the given date
 *  will be returned. Pass nil to retreive all entries for the user regardless of the end date (or however
 *	many the service provider will vend).
 *	@param lastUpdate This can be use to filter entries by when they were created or modified instead of
 *	their associated date. If this is supplied and the service provider supports it, only entries that
 *  have been added or modified since this date will be returned.
 *  @param limit If provided and supported by the service provider, limits the number of entries to 
 *	recieve.
 *	@param offset If provided and supported by the service provider, starts listing entries at this
 *	offset.
 *	@param completion Called upon completion of the update request. If the update succeeded, the
 *	entries array will contain all entries for the given user after the specified date. If an error
 *	occurred, error will contain information about that error.
 *
 *	Note: If an underlying service limits the number of entries that may be retrieved in a single
 *	request, it is up to the implementor of ASMScaleServiceProvider to batch the update requests.
 *	The completion handler should not be called until all entries have been retrieved.
 */
- (void)getEntriesFromDate:(NSDate*)startDate
					toDate:(NSDate*)endDate
				lastUpdate:(NSDate*)lastUpdate
					 limit:(NSNumber*)limit
					offset:(NSNumber*)offset
				completion:(void(^)(NSArray* entries, NSError* error))completion;

- (BOOL)authenticated;

- (BOOL)storeSensitiveInformationInKeychain:(NSError*__autoreleasing*)outError;
- (BOOL)retrieveSensitiveInformationFromKeychain:(NSError*__autoreleasing*)outError;

@end
