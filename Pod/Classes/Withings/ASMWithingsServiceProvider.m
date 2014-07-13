//
//  ASMWithingsServiceProvider.m
//  Pods
//
//  Created by Andrew Molloy on 7/12/14.
//
//

#import "ASMWithingsServiceProvider.h"
#import <AFOAuth1Client~wouterds/AFOAuth1Client.h>
#import <AFNetworking/AFNetworking.h>

@interface ASMWithingsServiceProvider ()
@property (nonatomic, copy) NSString* oauthKey;
@property (nonatomic, copy) NSString* oauthSecret;
@property (nonatomic, copy) ASMScaleServiceProviderAuthenticationHandler authenticationCompletionHandler;
@property (nonatomic, strong) AFOAuth1Token* accessToken;
@property (nonatomic, strong) AFOAuth1Client* client;
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

- (void)logout
{

}

- (void)lookupUserInformation
{
	NSDictionary* userInfo = self.accessToken.userInfo;
	NSString* userId = userInfo[@"userid"];
	if (userId)
	{
		NSLog(@"User: %@", userId);

		NSMutableURLRequest* request = [self.client requestWithMethod:@"GET"
																 path:@"user"
														   parameters:@{@"action": @"getbyuserid",
																		@"userid": userId}];

		AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
		[manager HTTPRequestOperationWithRequest:request
										 success:^(AFHTTPRequestOperation *operation, id responseObject)
		 {
			 NSLog(@"Wee success: %@", responseObject);
		 }
										 failure:^(AFHTTPRequestOperation *operation, NSError *error)
		 {
			 NSLog(@"BOO failure: %@", error);
		 }];
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

	NSURL* baseURL = [NSURL URLWithString:kWithingsAuthBaseURLString];

	self.client = [[AFOAuth1Client alloc] initWithBaseURL:baseURL
													  key:self.oauthKey
												   secret:self.oauthSecret];

	__weak typeof(self) wself = self;
	[self.client authorizeUsingOAuthWithRequestTokenPath:@"account/request_token"
								   userAuthorizationPath:@"account/authorize"
											 callbackURL:[NSURL URLWithString:@"x-com-asmscalekit://success"]
										 accessTokenPath:@"account/access_token"
											accessMethod:@"GET"
												   scope:@"read"
												 success:^(AFOAuth1Token *accessToken, id responseObject)
	 {
		 __strong typeof(wself) self = wself;
		 self.accessToken = accessToken;

		 self.client = [[AFOAuth1Client alloc] initWithBaseURL:[NSURL URLWithString:kWithingsBaseURLString]
														   key:self.oauthKey
														secret:self.oauthSecret];
		 self.client.accessToken = self.accessToken;

		 [self lookupUserInformation];
	 }
												 failure:^(NSError *error)
	 {
		 __strong typeof(wself) self = wself;
		 if (self.authenticationCompletionHandler)
		 {
			 self.authenticationCompletionHandler(nil, error);
		 }
	 }];
}

- (void)getEntriesForUser:(ASMScaleUser*)user sinceDate:(NSDate*)date completion:(ASMScaleServiceProviderUpdateEntriesHandler)completion
{

}
@end
