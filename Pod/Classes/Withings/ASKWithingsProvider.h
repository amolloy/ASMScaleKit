//
//  ASKWithingsProvider.h
//  Pods
//
//  Created by Andrew Molloy on 7/12/14.
//
//

#import <Foundation/Foundation.h>
#import <ASKServiceProvider.h>

/**
 *	An ASKServiceProvider for Withings' smart scales.
 *  http://www.withings.com
 *  You must sign up for a developer account with Withings, which you can do here:
 *  http://oauth.withings.com/api
 */
@interface ASKWithingsProvider : ASKServiceProvider

/**
 *	Initialize the ASKWithingsProvider. Like all ASKServiceProviders, ASKWithingsProvider
 *  is an informal singleton and should only be created once early in execution,
 *  such as during the application delegate's -application:didFinishLaunchingWithOptions:
 *  method.
 *
 *	@param key    The OAuth key provided by Withings after registering your application.
 *	@param secret The OAuth secret provided by Withings after registering your application.
 */
- (instancetype)initWithOAuthKey:(NSString*)key secret:(NSString*)secret;

@end
