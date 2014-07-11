//
//  ASMScaleUser.h
//  Pods
//
//  Created by Andrew Molloy on 7/11/14.
//
//

#import <Foundation/Foundation.h>

/**
 *	Base class to represent a user from an ASMScaleServiceProvider.
 */
@interface ASMScaleUser : NSObject

/**
 *	A string representing this user appropriate for displaying in a user interface.
 *	Depending on the provider, this could be a username, first name / last name combo,
 *	etc.
 *
 *	@return a string for this user appropriate for displaying in a user interface.
 */
- (NSString*)displayName;
@end
