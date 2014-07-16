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
@protocol ASMScaleUser <NSObject, NSSecureCoding>

/**
 *	A string representing this user appropriate for displaying in a user interface.
 *	Depending on the provider, this could be a username, first name / last name combo,
 *	etc.
 *
 *	@return a string for this user appropriate for displaying in a user interface.
 */
- (NSString*)displayName;
@end
