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
#import "ASMWithingsUser.h"
#import <libextobjc/EXTScope.h>

@interface ASMWithingsServiceProvider ()
@property (nonatomic, copy) NSString* oauthKey;
@property (nonatomic, copy) NSString* oauthSecret;
@property (nonatomic, copy) ASMScaleServiceProviderAuthenticationHandler authenticationCompletionHandler;
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

- (NSString*)displayName
{
	// TODO Trademarks / localization / etc
	return @"Withings";
}

- (Class)userClass
{
	return [ASMWithingsUser class];
}

- (ASMWithingsUser*)userWithUserID:(NSString*)userid
					   accessToken:(ASMOAuth1Token*)accessToken
				fromJSONDictionary:(NSDictionary*)json
							 error:(NSError*__autoreleasing*)outError
{
	// I wonder if this might be better as an initializer in ASMWithingsUser. Initializers don't typically
	// have out errors, though...
	NSError* error = nil;
	ASMWithingsUser* user = nil;
	if (!json[@"status"])
	{
		error = [NSError errorWithDomain:@"com.amolloy.asmwithingsserviceprovider"
									code:-1
								userInfo:@{NSLocalizedDescriptionKey:@"Unexpected response"}];
	}
	else if ([json[@"status"] compare:@(0)] != NSOrderedSame)
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
			NSString* name = @"";
			if (body[@"firstname"])
			{
				name = body[@"firstname"];
			}
			if (body[@"lastname"])
			{
				if (name.length != 0)
				{
					name = [name stringByAppendingString:@" "];
				}
				name = [name stringByAppendingString:body[@"lastname"]];
			}
			if (name.length == 0)
			{
				name = userid;
			}

			user = [[ASMWithingsUser alloc] initWithUserId:userid
									  permenantAccessToken:accessToken
													  name:name];
		}
	}

	if (outError)
	{
		*outError = error;
	}
	return user;
}

- (void)lookupUserInformationWithAccessToken:(ASMOAuth1Token*)accessToken
{
	NSDictionary* userInfo = accessToken.userInfo;
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
						NSError* outError = nil;
						ASMWithingsUser* user = nil;
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
			 [self lookupUserInformationWithAccessToken:accessToken];
		 }
	 }];
}

- (void)getEntriesForUser:(ASMScaleUser*)user sinceDate:(NSDate*)date completion:(ASMScaleServiceProviderUpdateEntriesHandler)completion
{

}
@end
