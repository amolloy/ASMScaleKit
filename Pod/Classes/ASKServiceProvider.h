//
//  ASKServiceProvider.h
//  Pods
//
//  Created by Andrew Molloy on 7/11/14.
//
//

#import <Foundation/Foundation.h>

@protocol ASKUser;

@protocol ASKServiceProvider <NSObject>

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

@end
