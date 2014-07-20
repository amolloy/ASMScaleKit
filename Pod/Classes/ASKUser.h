//
//  ASKUser.h
//  Pods
//
//  Created by Andrew Molloy on 7/11/14.
//
//

#import <UIKit/UIKit.h>

/**
 *	Represents an individual (user) of a particular service.
 *
 *	ASKUser can be serialized and persisted using the NSSecureCoding protocol. However,
 *  most (probably all) service providers require some sort of sensitive information,
 *  such as access tokens or password hashes, to be associated with the user. It is up
 *  to clients of this library to store and retrieve that sensitive information in the
 *  user's keychain. This can be accomplished by passing an ASKUser instance
 *  the -storeSensitiveInformationInKeychain: message when storing it, and the
 *	-retrieveSensitiveInformationFromKeychain: message when loading it.
 *	Alternatively, for more control over how the information is stored in the keychain,
 *  the sensitive information can be serialized / deserialized to a form suitable for
 *  storage in the keychain via -serializeSensitiveInformation: and 
 *  -deserializeSensitiveInformation:.
 */
@interface ASKUser : NSObject <NSSecureCoding>

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

/**
 *	Check if this user is authenticated and ready to use. Note that the authenticated state may not
 *  be reliably determined until an actual attempt to query the service provider occurs. However, this 
 *  can be used as an early filter to bypass an attempt to query the service provider if the user is
 *  known not to be authenticated.
 *
 *	@return NO if the user is known to not be authenticated, YES otherwise.
 */
- (BOOL)authenticated;

/**
 *	Attempts to store any sensitive information (access tokens, etc) for this user into the keychain.
 *
 *	@param outError Contains any error which occurred while trying to store the sensitive information.
 *
 *	@return YES if storing the sensitive information in the keychain succeeded, NO otherwise.
 */
- (BOOL)storeSensitiveInformationInKeychain:(NSError*__autoreleasing*)outError;

/**
 *	Attempts to retrieve any sensitive information (access tokens, etc) for this user from the keychain.
 *
 *	@param outError Contains any error which occurred while trying to retrieve the sensitive information.
 *
 *	@return YES if retrieving the sensitive information was successful.
 */
- (BOOL)retrieveSensitiveInformationFromKeychain:(NSError*__autoreleasing*)outError;

/**
 *	Serializes the sensitive information for this user into an NSData, which can then be stored
 *  in the user's keychain. This is an alternative to using -storeSensitiveInformationInKeychain:.
 *  Note that the data is not encrypted and is therefore not suitable for storing in an unencrypted
 *  store.
 *
 *	@param outError Contains any error which occurred while trying to serialize the sensitive information.
 *
 *	@return Data containing a serialized form of the sensitive information, suitable for storage in
 *  the user's keychain.
 */
- (NSData*)serializedSensitiveInformationError:(NSError*__autoreleasing*)outError;

/**
 *	Deserializes the sensitive information for this user from the given NSData. This should be
 *  data that was previously generated with -serializedSensitiveInformationError:. This is an
 *  alternative to -retrieveSensitiveInformationForKeychain:.
 *
 *	@param outError Contains any error which occurred while tyring to deserialize the sensitive
 *  information.
 *
 *	@return YES if deserialization was successful.
 */
- (BOOL)deserializedSensitiveInformation:(NSData*)serializedData error:(NSError*__autoreleasing*)outError;

@end
