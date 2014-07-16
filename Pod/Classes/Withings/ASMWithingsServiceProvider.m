//
//  ASMWithingsServiceProvider.m
//  Pods
//
//  Created by Andrew Molloy on 7/12/14.
//
//

#import "ASMWithingsServiceProvider.h"
#import "ASMOAuth1Client.h"
#import "ASMOAuth1Token.h"
#import <libextobjc/EXTScope.h>

@interface ASMWithingsServiceProvider ()
@property (nonatomic, copy) NSString* oauthKey;
@property (nonatomic, copy) NSString* oauthSecret;
@property (nonatomic, copy) ASMScaleServiceProviderAuthenticationHandler authenticationCompletionHandler;
@property (nonatomic, strong) ASMOAuth1Token* accessToken;
@property (nonatomic, strong) ASMOAuth1Client* client;
@end

@implementation ASMWithingsServiceProvider

const NSInteger ASMWithingsServiceProviderNoUserID = 1;
static NSString* const kWithingsAuthBaseURLString = @"https://oauth.withings.com";
static NSString* const kWithingsBaseURLString = @"http://wbsapi.withings.net";

- (instancetype)initWithOAuthKey:(NSString*)key secret:(NSString*)secret
{
	self = [super init];
	if (self)
	{
		self.oauthKey = key;
		self.oauthSecret = secret;
	}
	return self;
}


- (BOOL)loggedIn
{
	return self.client != nil;
}

- (void)logout
{

}

- (void)lookupUserInformation
{
	NSDictionary* userInfo = self.accessToken.userInfo;
	NSString* userId = userInfo[@"userid"];
	if (userId)
	{
		NSURLComponents* components = [NSURLComponents componentsWithString:[kWithingsBaseURLString stringByAppendingPathComponent:@"user"]];
		components.query = [NSString stringWithFormat:@"action=getbyuserid&userid=%@", userId];

		NSURLRequest* request = [NSURLRequest requestWithURL:components.URL];
		request = [self.client requestWithOAuthParametersFromURLRequest:request];

		NSURLSession* session = [NSURLSession sharedSession];
		[[session dataTaskWithRequest:request
					completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
						if (error)
						{
							NSLog(@"Error getting user info: %@", error);
						}
						else
						{
							NSString* responseString = [[NSString alloc] initWithData:data
																			 encoding:NSUTF8StringEncoding];

							NSLog(@"Response:");
							NSLog(@"%@", response);
							NSLog(@"Response string from data:");
							NSLog(@"%@", responseString);
						}
					}] resume];
	}
	else if (self.authenticationCompletionHandler)
	{
		NSError* error = [NSError errorWithDomain:@"ASMScaleKit.Withings"
											 code:ASMWithingsServiceProviderNoUserID
										 userInfo:@{NSLocalizedDescriptionKey: @"Did not receive user id"}];
		self.authenticationCompletionHandler(nil, error);
	}
}

- (void)authenticateFromViewController:(UIViewController*)viewController
						withCompletion:(ASMScaleServiceProviderAuthenticationHandler)completion
{
	self.authenticationCompletionHandler = completion;

	NSURL* oauthURLBase = [NSURL URLWithString:kWithingsAuthBaseURLString];

	self.client = [[ASMOAuth1Client alloc] initWithOAuthURLBase:oauthURLBase
													   key:self.oauthKey
													secret:self.oauthSecret];
	self.client.protocolParameterLocation = ASMOAuth1ProtocolParameterURLQueryLocation;
	self.client.providerHints = ASMOAuth1ClientWithingsProviderHints;

	@weakify(self);
	[self.client authorizeWithRequestTokenPath:@"account/request_token"
						userAuthenticationPath:@"account/authorize"
							   accessTokenPath:@"account/access_token"
										 scope:nil //@"read"?
								  accessMethod:ASMOAUTH1ClientAccessGETMethod
							fromViewController:viewController
									completion:^(ASMOAuth1Token* accessToken, NSError *error)
	 {
		 @strongify(self);
		 if (error)
		 {
			 if (self.authenticationCompletionHandler)
			 {
				 self.authenticationCompletionHandler(nil, error);
			 }
		 }
		 else
		 {
			 self.accessToken = accessToken;
			 [self lookupUserInformation];
		 }
	 }];
}

- (void)getEntriesForUser:(ASMScaleUser*)user sinceDate:(NSDate*)date completion:(ASMScaleServiceProviderUpdateEntriesHandler)completion
{

}
@end
