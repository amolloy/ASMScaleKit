//
//  ASKWithingsProvider.m
//  Pods
//
//  Created by Andrew Molloy on 7/12/14.
//
//

#import "ASKWithingsProvider.h"
#import "ASKOAuth1Client.h"
#import "ASKOAuth1Token.h"
#import "ASKWithingsUser.h"

@interface ASKWithingsUser ()
- (instancetype)initWithUserId:(NSString*)userId
		  permenantAccessToken:(ASKOAuth1Token*)token
						  name:(NSString*)name;
@end

@interface ASKWithingsProvider ()
@property (nonatomic, copy) NSString* oauthKey;
@property (nonatomic, copy) NSString* oauthSecret;
@property (nonatomic, copy) ASMScaleServiceProviderAuthenticationHandler authenticationCompletionHandler;
@property (nonatomic, strong, readwrite) ASKOAuth1Client* client;
@end

@implementation ASKWithingsProvider

const NSInteger ASMWithingsServiceProviderNoUserID = 1;
NSString* const ASMWithingsBaseURLString = @"http://wbsapi.withings.net";

static NSString* const kWithingsAuthBaseURLString = @"https://oauth.withings.com";

- (instancetype)initWithOAuthKey:(NSString*)key secret:(NSString*)secret
{
	self = [super init];
	if (self)
	{
		self.oauthKey = key;
		self.oauthSecret = secret;

		NSURL* oauthURLBase = [NSURL URLWithString:kWithingsAuthBaseURLString];

		self.client = [[ASKOAuth1Client alloc] initWithOAuthURLBase:oauthURLBase
																key:self.oauthKey
															 secret:self.oauthSecret];
		self.client.protocolParameterLocation = ASKOAuth1ProtocolParameterURLQueryLocation;
		self.client.providerHints = ASKOAuth1ClientWithingsProviderHints;
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

- (NSString*)displayName
{
	// TODO Trademarks / localization / etc
	return @"Withings";
}

- (Class)userClass
{
	return [ASKWithingsUser class];
}

- (ASKWithingsUser*)userWithUserID:(NSString*)userId
					   accessToken:(ASKOAuth1Token*)accessToken
				fromJSONDictionary:(NSDictionary*)json
							 error:(NSError*__autoreleasing*)outError
{
	// I wonder if this might be better as an initializer in ASMWithingsUser. Initializers don't typically
	// have out errors, though...
	NSError* error = nil;
	ASKWithingsUser* user = nil;

	NSInteger status = -1;
	if (json[@"status"] && [json[@"status"] isKindOfClass:[NSNumber class]])
	{
		NSNumber* statusNumber = json[@"status"];
		status = [statusNumber integerValue];
	}

	// All of Withings (current) status codes are >= 0
	if (-1 == status)
	{
		error = [NSError errorWithDomain:@"com.amolloy.asmwithingsserviceprovider"
									code:-1
								userInfo:@{NSLocalizedDescriptionKey:@"Unexpected response"}];
	}
	else if (0 != status)
	{
		// TODO They do list their status codes, probably should translate them here
		error = [NSError errorWithDomain:@"com.amolloy.asmwithingsserviceprovider"
									code:[json[@"status"] integerValue]
								userInfo:@{NSLocalizedDescriptionKey:@"Error from Withings"}];
	}
	else
	{
		NSDictionary* body = json[@"body"];
		if (!body)
		{
			error = [NSError errorWithDomain:@"com.amolloy.asmwithingsserviceprovider"
										code:-1
									userInfo:@{NSLocalizedDescriptionKey:@"Unexpected response, no body"}];
		}
		else
		{
			NSArray* users = body[@"users"];
			if (!users)
			{
				error = [NSError errorWithDomain:@"com.amolloy.asmwithingsserviceprovider"
											code:-1
										userInfo:@{NSLocalizedDescriptionKey:@"Unexpected response, no users"}];
			}
			else if (users.count == 0)
			{
				error = [NSError errorWithDomain:@"com.amolloy.asmwithingsserviceprovider"
											code:-1
										userInfo:@{NSLocalizedDescriptionKey:@"Unexpected response, users array empty"}];
			}
			else
			{
				NSDictionary* userDict = users[0];
				NSString* name = @"";
				if (userDict[@"firstname"])
				{
					name = userDict[@"firstname"];
				}
				if (userDict[@"lastname"])
				{
					if (name.length != 0)
					{
						name = [name stringByAppendingString:@" "];
					}
					name = [name stringByAppendingString:userDict[@"lastname"]];
				}
				if (name.length == 0)
				{
					name = userId;
				}

				user = [[ASKWithingsUser alloc] initWithUserId:userId
										  permenantAccessToken:accessToken
														  name:name];
			}
		}
	}

	if (outError)
	{
		*outError = error;
	}
	return user;
}

- (void)lookupUserInformationWithAccessToken:(ASKOAuth1Token*)accessToken
{
	NSDictionary* userInfo = accessToken.userInfo;
	NSString* userId = userInfo[@"userid"];
	if (userId)
	{
		NSURL* baseURL = [NSURL URLWithString:ASMWithingsBaseURLString];
		NSURLComponents* components = [NSURLComponents componentsWithURL:[baseURL URLByAppendingPathComponent:@"user"]
									   resolvingAgainstBaseURL:NO];
		components.query = [NSString stringWithFormat:@"action=getbyuserid&userId=%@", userId];

		NSURLRequest* request = [NSURLRequest requestWithURL:components.URL];
		request = [self.client requestWithOAuthParametersFromURLRequest:request
															accessToken:accessToken];

		NSURLSession* session = [NSURLSession sharedSession];
		[[session dataTaskWithRequest:request
					completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
						NSError* outError = nil;
						ASKWithingsUser* user = nil;
						if (!error)
						{
							NSString* responseString = [[NSString alloc] initWithData:data
																			 encoding:NSUTF8StringEncoding];
							NSData* responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
							NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:responseData
																						 options:0
																						   error:&outError];
							if (responseDict)
							{
								user = [self userWithUserID:userId
												accessToken:accessToken
										 fromJSONDictionary:responseDict
													  error:&outError];
							}
						}
						else
						{
							outError = error;
						}

						if (self.authenticationCompletionHandler)
						{
							NSArray* users = nil;
							if (user)
							{
								users = @[user];
							}
							self.authenticationCompletionHandler(users, outError);
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

	__weak typeof(self) wself = self;
	[self.client authorizeWithRequestTokenPath:@"account/request_token"
						userAuthenticationPath:@"account/authorize"
							   accessTokenPath:@"account/access_token"
										 scope:nil //@"read"?
								  accessMethod:ASKOAuth1ClientAccessGETMethod
							fromViewController:viewController
									completion:^(ASKOAuth1Token* accessToken, NSError *error)
	 {
		 __strong typeof(wself) sself = wself;
		 if (error)
		 {
			 if (sself.authenticationCompletionHandler)
			 {
				 sself.authenticationCompletionHandler(nil, error);
			 }
		 }
		 else
		 {
			 [sself lookupUserInformationWithAccessToken:accessToken];
		 }
	 }];
}

@end
