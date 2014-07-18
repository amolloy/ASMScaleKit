//
//  ASKServiceProvider.h
//  Pods
//
//  Created by Andrew Molloy on 7/11/14.
//
//

#import "ASKServiceProvider.h"

@implementation ASKServiceProvider

- (NSString*)displayName
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (Class)userClass
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (void)authenticateFromViewController:(UIViewController*)viewController
						withCompletion:(ASMScaleServiceProviderAuthenticationHandler)completion
{
	[self doesNotRecognizeSelector:_cmd];
}

@end
