//
//  ASKServiceProvider.h
//  Pods
//
//  Created by Andrew Molloy on 7/11/14.
//
//

#import "ASKServiceProvider.h"

@implementation ASKServiceProvider

+ (NSMutableArray*)registeredProviders
{
	static NSMutableArray* sRegisteredProviders = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sRegisteredProviders = [[NSMutableArray alloc] init];
	});
	return sRegisteredProviders;
}

+ (void)registerServiceProvider:(ASKServiceProvider*)serviceProvider
{
	[[self registeredProviders] addObject:serviceProvider];
}

+ (NSArray*)serviceProviders
{
	NSMutableArray* rp = [self registeredProviders];
	return [rp copy];
}

+ (instancetype)serviceProviderForUser:(ASKUser*)user
{
	__block ASKServiceProvider* provider = nil;
	[[self registeredProviders] enumerateObjectsUsingBlock:^(ASKServiceProvider* obj, NSUInteger idx, BOOL *stop) {
		if ([user isKindOfClass:[obj userClass]])
		{
			provider = obj;
			*stop = YES;
		}
	}];
	return provider;
}

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
