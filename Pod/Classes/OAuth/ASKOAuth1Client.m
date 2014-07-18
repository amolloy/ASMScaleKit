//
//  ASMOAuthManager.m
//  Pods
//
//  Created by Andrew Molloy on 7/13/14.
//
//

#import "ASKOAuth1Client.h"
#import "ASKOAuth1Token.h"
#import <CommonCrypto/CommonHMAC.h>
#import <libextobjc/EXTScope.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import "ASKOAuth1AuthenticationViewController.h"
#endif

NSInteger ASKOAuth1ClientWithingsProviderHints = ASKOAuth1ClientProviderIncludeUserInfoInAccessRequestHint | ASKOAuth1ClientProviderSuppressVerifierHint | ASKOAuth1ClientIncludeFullOAuthParametersInAuthenticationHint;

static NSString* const kASMOAuth1Version = @"1.0";
static NSString* const kASMOAuth1CallbackURLString = @"askoauth1client://success";

@interface NSString (ASKOAuth1ClientHelpers)
+ (NSString*)stringWithOAuth1ClientSignatureMethod:(ASKOAuth1ClientSignatureMethod)signatureMethod;
+ (NSString*)stringWithOAuth1ClientAccessMethod:(ASKOAuth1ClientAccessMethod)clientAccessMethod;
+ (NSString*)nonceString;
@end

static NSCharacterSet* oauthParameterValidCharacterSet()
{
	// http://oauth.net/core/1.0/#signing_process section 5.1
	static NSCharacterSet* sCharSet = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSMutableCharacterSet* set = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
		[set addCharactersInString:@"-._~"];
		sCharSet = set.copy;
	});
	return sCharSet;
}

@interface ASKOAuth1Client ()
@property (nonatomic, copy) NSString* consumerKey;
@property (nonatomic, copy) NSString* consumerSecret;
@property (nonatomic, strong, readwrite) ASKOAuth1Token* accessToken;
@property (nonatomic, copy) ASKOAuth1ClientAuthorizeCompletion authorizationCompletion;
@property (nonatomic, strong) NSURL* oauthURLBase;

#if __IPHONE_OS_VERSION_MIN_REQUIRED
@property (nonatomic, strong) UIViewController* presentingViewController;
#endif
@end

@implementation ASKOAuth1Client

- (instancetype)initWithOAuthURLBase:(NSURL*)oauthURLBase key:(NSString*)key secret:(NSString*)secret
{
	self = [super init];
	if (self)
	{
		self.oauthURLBase = oauthURLBase;
		self.consumerKey = key;
		self.consumerSecret = secret;
		self.signatureMethod = ASKOAuth1ClientHMACSHA1SignatureMethod;
		self.stringEncoding = NSUTF8StringEncoding;
	}
	return self;
}

- (void)authorizeWithRequestTokenPath:(NSString*)tokenPath
			   userAuthenticationPath:(NSString*)authorizationPath
					  accessTokenPath:(NSString*)accessTokenPath
								scope:(NSString*)scope
						 accessMethod:(ASKOAuth1ClientAccessMethod)accessMethod
#if __IPHONE_OS_VERSION_MIN_REQUIRED
				   fromViewController:(UIViewController*)viewController
#endif
						   completion:(ASKOAuth1ClientAuthorizeCompletion)completion
{
	self.authorizationCompletion = completion;

	@weakify(self);
	[self acquireOAuthRequestTokenWithPath:tokenPath
									 scope:scope
							  accessMethod:accessMethod
								completion:^(ASKOAuth1Token* requestToken, NSError* error)
	 {
		 @strongify(self);
		 if (!error)
		 {
#if __IPHONE_OS_VERSION_MIN_REQUIRED
			 self.presentingViewController = viewController;
			 [self authenticateUserWithPath:authorizationPath
							accessTokenPath:accessTokenPath
							   requestToken:requestToken
							   accessMethod:accessMethod];
#else
#error Unimplemented
#endif
		 }
		 else if (self.authorizationCompletion)
		 {
			 self.authorizationCompletion(nil, error);
		 }
	 }];
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED
- (void)authenticateUserWithPath:(NSString*)path
				 accessTokenPath:(NSString*)accessTokenPath
					requestToken:(ASKOAuth1Token*)requestToken
					accessMethod:(ASKOAuth1ClientAccessMethod)accessMethod
{
	NSURLComponents* urlComponents = [NSURLComponents componentsWithURL:[self.oauthURLBase URLByAppendingPathComponent:path]
												resolvingAgainstBaseURL:NO];
	urlComponents.percentEncodedQuery = [NSString stringWithFormat:@"oauth_token=%@", [requestToken.key stringByAddingPercentEncodingWithAllowedCharacters:oauthParameterValidCharacterSet()]];

	if (self.providerHints & ASKOAuth1ClientIncludeFullOAuthParametersInAuthenticationHint)
	{
		NSURLRequest* request = [NSURLRequest requestWithURL:urlComponents.URL];
		request = [self requestWithOAuthParametersFromURLRequest:request
													 accessToken:self.accessToken];

		urlComponents = [NSURLComponents componentsWithURL:request.URL
								   resolvingAgainstBaseURL:NO];
	}

	@weakify(self);
	dispatch_async(dispatch_get_main_queue(), ^{
		ASKOAuth1AuthenticationViewController* vc = [[ASKOAuth1AuthenticationViewController alloc]
													 initWithAuthorizationURL:urlComponents.URL
													 sentinelURL:[NSURL URLWithString:kASMOAuth1CallbackURLString]
													 completion:^(NSURL* authorizationURL, NSError* error)
													 {
														 @strongify(self);
														 [self.presentingViewController dismissViewControllerAnimated:YES
																										   completion:nil];
														 [self receivedAuthorizationURL:authorizationURL
																		accessTokenPath:accessTokenPath
																		   requestToken:requestToken
																		   accessMethod:accessMethod
																				  error:error];
													 }];
		UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:vc];

		[self.presentingViewController presentViewController:nav
													animated:YES
												  completion:nil];
	});
}
#endif

- (NSDictionary*)parametersFromQueryString:(NSString*)string
{
	NSMutableDictionary* parameters = [NSMutableDictionary dictionaryWithCapacity:0];
	NSArray* kvPairs = [string componentsSeparatedByString:@"&"];
	[kvPairs enumerateObjectsUsingBlock:^(NSString* kvPair, NSUInteger idx, BOOL *stop) {
		NSArray* components = [kvPair componentsSeparatedByString:@"="];
		if (components.count == 2)
		{
			NSString* key = components[0];
			key = [key stringByReplacingPercentEscapesUsingEncoding:self.stringEncoding];
			NSString* value = components[1];
			value = [value stringByReplacingPercentEscapesUsingEncoding:self.stringEncoding];

			if (key.length != 0 && value)
			{
				parameters[key] = value;
			}
		}
	}];

	return parameters.copy;
}

- (void)receivedAuthorizationURL:(NSURL*)url
				 accessTokenPath:(NSString*)accessTokenPath
					requestToken:(ASKOAuth1Token*)requestToken
					accessMethod:(ASKOAuth1ClientAccessMethod)accessMethod
						   error:(NSError*)error
{
	if (!error)
	{
		NSDictionary* parameters = [self parametersFromQueryString:url.query];
		requestToken.verifier = parameters[@"oauth_verifier"];

		if (self.providerHints & ASKOAuth1ClientProviderIncludeUserInfoInAccessRequestHint)
		{
			NSMutableDictionary* mutableParameters = parameters.mutableCopy;
			for (NSString* key in parameters.allKeys)
			{
				if ([key hasPrefix:@"oauth_"])
				{
					[mutableParameters removeObjectForKey:key];
				}
			}
			requestToken.userInfo = mutableParameters.copy;
		}

		@weakify(self);
		[self acquireOAuthAccessTokenWithPath:accessTokenPath
								 requestToken:requestToken
								 accessMethod:accessMethod
								   completion:^(ASKOAuth1Token* accessToken, id responseObject, NSError* aatError)
		 {
			 @strongify(self);
			 self.accessToken = accessToken;
			 if (self.authorizationCompletion)
			 {
				 self.authorizationCompletion(accessToken, aatError);
			 }
		 }];
	}
	else if (self.authorizationCompletion)
	{
		self.authorizationCompletion(nil, error);
	}
}

- (void)acquireOAuthAccessTokenWithPath:(NSString*)path
                           requestToken:(ASKOAuth1Token*)requestToken
                           accessMethod:(ASKOAuth1ClientAccessMethod)accessMethod
							 completion:(void (^)(ASKOAuth1Token* accessToken, id responseObject, NSError* error))completion
{
	NSAssert(accessMethod != ASKOAuth1ClientAccessPOSTMethod, @"POST not yet supported");

    if (requestToken.key && requestToken.verifier)
	{
        self.accessToken = requestToken;

		NSURLComponents* components = [NSURLComponents componentsWithURL:[self.oauthURLBase URLByAppendingPathComponent:path]
												 resolvingAgainstBaseURL:NO];

		if (!(self.providerHints & ASKOAuth1ClientProviderSuppressVerifierHint))
		{
			NSString* oauthVerifierParam = [NSString stringWithFormat:@"oauth_verifier=%@",
											[requestToken.verifier stringByAddingPercentEncodingWithAllowedCharacters:oauthParameterValidCharacterSet()]];

			components.percentEncodedQuery = oauthVerifierParam;
		}

		if (self.providerHints & ASKOAuth1ClientProviderIncludeUserInfoInAccessRequestHint)
		{
			if (requestToken.userInfo.count != 0)
			{
				NSMutableArray* userInfoKVPairs = [NSMutableArray arrayWithCapacity:requestToken.userInfo.count];
				[requestToken.userInfo enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSString* value, BOOL *stop) {
					NSString* kvPair = [NSString stringWithFormat:@"%@=%@",
										[key stringByAddingPercentEncodingWithAllowedCharacters:oauthParameterValidCharacterSet()],
										[value stringByAddingPercentEncodingWithAllowedCharacters:oauthParameterValidCharacterSet()]];
					[userInfoKVPairs addObject:kvPair];
				}];

				NSString* newQuery = components.percentEncodedQuery;
				if (!newQuery)
				{
					newQuery = @"";
				}
				if (newQuery.length != 0)
				{
					newQuery = [newQuery stringByAppendingString:@"&"];
				}

				newQuery = [newQuery stringByAppendingString:[userInfoKVPairs componentsJoinedByString:@"&"]];
				components.percentEncodedQuery = newQuery;
			}
		}

		NSMutableURLRequest* mutableRequest = [NSMutableURLRequest requestWithURL:components.URL];
		[mutableRequest setHTTPMethod:[NSString stringWithOAuth1ClientAccessMethod:accessMethod]];
		[mutableRequest setHTTPBody:nil];

		NSURLRequest* request = [self requestWithOAuthParametersFromURLRequest:mutableRequest
																   accessToken:self.accessToken];

		NSURLSession* session = [NSURLSession sharedSession];
		[[session dataTaskWithRequest:request completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
			ASKOAuth1Token* accessToken = nil;
			if (!error)
			{
				NSString* responseString = [[NSString alloc] initWithData:data encoding:self.stringEncoding];
				if (responseString)
				{
					accessToken = [[ASKOAuth1Token alloc] initWithResponseString:responseString];
				}
			}

			if (completion)
			{
				completion(accessToken, response, error);
			}
		}] resume];
    }
	else if (completion)
	{
		// TODO
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:NSLocalizedStringFromTable(@"Bad OAuth response received from the server.", @"ASKOAuth1Client", nil) forKey:NSLocalizedFailureReasonErrorKey];
        NSError* error = [[NSError alloc] initWithDomain:@"com.amolloy.oauth1client"
													code:NSURLErrorBadServerResponse
												userInfo:userInfo];
        completion(nil, nil, error);
    }
}

- (void)acquireOAuthRequestTokenWithPath:(NSString*)path
								   scope:(NSString*)scope
							accessMethod:(ASKOAuth1ClientAccessMethod)accessMethod
							  completion:(void(^)(ASKOAuth1Token* requestToken, NSError* error))completion
{
	NSAssert(ASKOAuth1ClientAccessPOSTMethod != accessMethod, @"POST not yet supported");

	NSURLComponents* urlComponents = [NSURLComponents componentsWithURL:[self.oauthURLBase URLByAppendingPathComponent:path]
												resolvingAgainstBaseURL:NO];

	NSMutableDictionary* parameters = @{}.mutableCopy;
	if (scope && !self.accessToken)
	{
		parameters[@"scope"] = scope;
	}

	NSMutableArray* kvPairs = [NSMutableArray arrayWithCapacity:parameters.count];
	[parameters enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSString* value, BOOL *stop) {
		[kvPairs addObject:[NSString stringWithFormat:@"%@=%@", key, [value stringByAddingPercentEncodingWithAllowedCharacters:oauthParameterValidCharacterSet()]]];
	}];
	[kvPairs sortUsingSelector:@selector(compare:)];

	NSString* query = urlComponents.percentEncodedQuery;
	if (query)
	{
		query = [query stringByAppendingString:@"&"];
	}
	else
	{
		query = @"";
	}
	query = [query stringByAppendingString:[kvPairs componentsJoinedByString:@"&"]];
	urlComponents.percentEncodedQuery = query;

	NSMutableURLRequest* mutableRequest = [NSMutableURLRequest requestWithURL:urlComponents.URL];
	[mutableRequest setHTTPMethod:[NSString stringWithOAuth1ClientAccessMethod:accessMethod]];
	[mutableRequest setHTTPBody:nil];
	NSURLRequest* request = [self requestWithOAuthParametersFromURLRequest:mutableRequest
															   accessToken:self.accessToken
															   callbackURL:[NSURL URLWithString:kASMOAuth1CallbackURLString]];

	NSURLSession* session = [NSURLSession sharedSession];
	[[session dataTaskWithRequest:request completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
		ASKOAuth1Token* accessToken = nil;

		if (!error)
		{
			NSString* responseString = [[NSString alloc] initWithData:data encoding:self.stringEncoding];
			if (responseString)
			{
				accessToken = [[ASKOAuth1Token alloc] initWithResponseString:responseString];
			}

			if (!accessToken)
			{
				// TODO
				error = [NSError errorWithDomain:@"com.amolloy.scalekit" code:1 userInfo:@{NSLocalizedDescriptionKey:@"TODO"}];
			}
		}

		if (completion)
		{
			completion(accessToken, error);
		}
	}] resume];
}

- (NSURLRequest*)requestWithOAuthParametersFromURLRequest:(NSURLRequest*)request
											  accessToken:(ASKOAuth1Token*)accessToken
{
	return [self requestWithOAuthParametersFromURLRequest:request
											  accessToken:accessToken
											  callbackURL:nil];
}

- (NSURLRequest*)requestWithOAuthParametersFromURLRequest:(NSURLRequest*)request
											  accessToken:(ASKOAuth1Token*)accessToken
											  callbackURL:(NSURL*)callbackURL
{
	NSAssert(ASKOAuth1ProtocolParameterURLQueryLocation == self.protocolParameterLocation, @"Not yet implemented");

	NSMutableURLRequest* newRequest = request.mutableCopy;

	if (ASKOAuth1ProtocolParameterURLQueryLocation == self.protocolParameterLocation)
	{
		NSMutableArray* parameters = [self oauthParametersQueryComponents].mutableCopy;
		if (callbackURL)
		{
			[parameters addObject:[NSString stringWithFormat:@"oauth_callback=%@",
										[[callbackURL absoluteString] stringByAddingPercentEncodingWithAllowedCharacters:oauthParameterValidCharacterSet()]]];
		}
		if (accessToken)
		{
			[parameters addObject:[NSString stringWithFormat:@"oauth_token=%@",
										[accessToken.key stringByAddingPercentEncodingWithAllowedCharacters:oauthParameterValidCharacterSet()]]];
		}
		NSURLComponents* urlComponents = [NSURLComponents componentsWithURL:request.URL
													resolvingAgainstBaseURL:NO];
		NSString* query = [urlComponents percentEncodedQuery];
		if (query.length != 0)
		{
			NSArray* queryParameters = [query componentsSeparatedByString:@"&"];
			[parameters addObjectsFromArray:queryParameters];
		}

		NSString* signature = [self oauthSignatureForURLRequest:newRequest
												queryParameters:parameters
											 postBodyParameters:nil
														  token:accessToken];

		[parameters addObject:[NSString stringWithFormat:@"oauth_signature=%@",
							   [signature stringByAddingPercentEncodingWithAllowedCharacters:oauthParameterValidCharacterSet()]]];
		
		[parameters sortUsingSelector:@selector(compare:)];

		urlComponents.percentEncodedQuery = [parameters componentsJoinedByString:@"&"];
		newRequest.URL = urlComponents.URL;
	}

    [newRequest setHTTPShouldHandleCookies:NO];

    return newRequest.copy;
}

- (NSArray*)oauthParametersQueryComponents
{
	NSDictionary* parameters = [self oauthParameters];
	NSArray* oauthParameterKeys = [[parameters allKeys] sortedArrayUsingSelector:@selector(compare:)];

	NSMutableArray* oauthParameters = [NSMutableArray arrayWithCapacity:oauthParameterKeys.count];
	[oauthParameterKeys enumerateObjectsUsingBlock:^(NSString* key, NSUInteger idx, BOOL *stop) {
		NSString* value = parameters[key];
		value = [value stringByAddingPercentEncodingWithAllowedCharacters:oauthParameterValidCharacterSet()];

		[oauthParameters addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
	}];

	return oauthParameters;
}

- (NSString *)authorizationHeaderForURLRequest:(NSURLRequest*)request
{
    static NSString * const kASMAuth1AuthorizationFormatString = @"OAuth %@";

    NSMutableDictionary* mutableAuthorizationParameters = [NSMutableDictionary dictionary];

    if (self.consumerKey && self.consumerSecret)
	{
        [mutableAuthorizationParameters addEntriesFromDictionary:[self oauthParameters]];
        if (self.accessToken)
		{
			// TODO    mutableAuthorizationParameters[@"oauth_token"] = self.accessToken.key;
        }
    }

// TODO    mutableAuthorizationParameters[@"oauth_signature"] = [self oauthSignatureForURLRequest:request
		//																			 token:self.accessToken];

	NSArray* sortedComponents = [self oauthParametersQueryComponents];

    NSMutableArray* mutableComponents = [NSMutableArray arrayWithCapacity:sortedComponents.count];
    for (NSString *component in sortedComponents)
	{
        NSArray* subcomponents = [component componentsSeparatedByString:@"="];
        if ([subcomponents count] == 2)
		{
            [mutableComponents addObject:[NSString stringWithFormat:@"%@=\"%@\"", subcomponents[0], subcomponents[1]]];
        }
    }

    return [NSString stringWithFormat:kASMAuth1AuthorizationFormatString, [mutableComponents componentsJoinedByString:@", "]];
}

- (NSString*)plainTextSignatureForURLRequest:(NSURLRequest*)request
									   token:(ASKOAuth1Token*)token
{
    NSString* secret = @""; // token ? token.secret : @"";
    NSString* signature = [NSString stringWithFormat:@"%@&%@", self.consumerSecret, secret];
    return signature;
}

- (NSString*)HMACSHA1SignatureForURLRequest:(NSURLRequest*)request
							queryParameters:(NSArray*)queryParameters
						 postBodyParameters:(NSArray*)postBodyParameters
									  token:(ASKOAuth1Token*)token
{
	// http://oauth.net/core/1.0/#signing_process

	// 9.1.1
	if (!queryParameters)
	{
		queryParameters = @[];
	}
	NSArray* allParameters = [queryParameters arrayByAddingObjectsFromArray:postBodyParameters];
	allParameters = [allParameters sortedArrayUsingSelector:@selector(compare:)];

	NSString* normalizedRequestParameters = [allParameters componentsJoinedByString:@"&"];
	normalizedRequestParameters = [normalizedRequestParameters stringByAddingPercentEncodingWithAllowedCharacters:oauthParameterValidCharacterSet()];

	// 9.1.2
	NSString* requestBaseURL = [request.URL absoluteString];
	NSUInteger queryStart = [requestBaseURL rangeOfString:@"?"].location;
	if (NSNotFound != queryStart)
	{
		requestBaseURL = [requestBaseURL substringToIndex:queryStart];
	}
	requestBaseURL = [requestBaseURL lowercaseString];
	requestBaseURL = [requestBaseURL stringByAddingPercentEncodingWithAllowedCharacters:oauthParameterValidCharacterSet()];

	// 9.1.3
	NSArray* signatureBaseStringParts = @[request.HTTPMethod, requestBaseURL, normalizedRequestParameters];
	NSString* signatureBaseString = [signatureBaseStringParts componentsJoinedByString:@"&"];
	NSData* signatureBaseStringData = [signatureBaseString dataUsingEncoding:self.stringEncoding];

	// 9.2
	NSString* secret = token.secret ? token.secret : @"";
	NSString* encodedSecret = [secret stringByAddingPercentEncodingWithAllowedCharacters:oauthParameterValidCharacterSet()];
	NSString* encodedConsumerSecret = [self.consumerSecret stringByAddingPercentEncodingWithAllowedCharacters:oauthParameterValidCharacterSet()];
	NSString* secretString = [NSString stringWithFormat:@"%@&%@", encodedConsumerSecret, encodedSecret];
	NSData* secretStringData = [secretString dataUsingEncoding:self.stringEncoding];

    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CCHmacContext cx;
    CCHmacInit(&cx, kCCHmacAlgSHA1, [secretStringData bytes], [secretStringData length]);
    CCHmacUpdate(&cx, [signatureBaseStringData bytes], [signatureBaseStringData length]);
    CCHmacFinal(&cx, digest);

    return [[NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH] base64EncodedStringWithOptions:0];
}

- (NSString*)oauthSignatureForURLRequest:(NSURLRequest*)request
						 queryParameters:(NSArray*)queryParameters
					  postBodyParameters:(NSArray*)postBodyParameters
								   token:(ASKOAuth1Token*)token
{
	NSString* signature = nil;

    switch (self.signatureMethod)
	{
        case ASKOAuth1ClientPlainTextSignatureMethod:
            signature = [self plainTextSignatureForURLRequest:request
														token:token];
			break;
        case ASKOAuth1ClientHMACSHA1SignatureMethod:
            signature = [self HMACSHA1SignatureForURLRequest:request
											 queryParameters:queryParameters
										  postBodyParameters:postBodyParameters
													   token:token];
			break;
    }

	return signature;
}

- (NSDictionary*)oauthParameters
{
	NSMutableDictionary* parameters =
	@{@"oauth_version": kASMOAuth1Version,
	  @"oauth_signature_method": [NSString stringWithOAuth1ClientSignatureMethod:self.signatureMethod],
	  @"oauth_consumer_key": self.consumerKey,
	  @"oauth_timestamp": [@(floor([[NSDate date] timeIntervalSince1970])) stringValue],
	  @"oauth_nonce": [NSString nonceString]
	  }.mutableCopy;

    if (self.realm)
	{
        parameters[@"realm"] = self.realm;
    }

    return parameters.copy;
}

@end

#pragma mark = NSString+ASKOAuth1ClientHelpers

@implementation NSString (ASKOAuth1ClientHelpers)
+ (NSString*)stringWithOAuth1ClientSignatureMethod:(ASKOAuth1ClientSignatureMethod)signatureMethod
{
	NSString* result = nil;
	switch (signatureMethod)
	{
		case ASKOAuth1ClientPlainTextSignatureMethod:
			result = @"PLAINTEXT";
			break;
		case ASKOAuth1ClientHMACSHA1SignatureMethod:
			result = @"HMAC-SHA1";
			break;
	}

	return result;
}

+ (NSString*)stringWithOAuth1ClientAccessMethod:(ASKOAuth1ClientAccessMethod)clientAccessMethod
{
	NSString* result = nil;
	switch (clientAccessMethod)
	{
		case ASKOAuth1ClientAccessGETMethod:
			result = @"GET";
			break;
		case ASKOAuth1ClientAccessPOSTMethod:
			result = @"POST";
			break;
		case ASKOAuth1ClientAccessHEADMethod:
			result = @"HEAD";
			break;
		case ASKOAuth1ClientAccessDELETEMethod:
			result = @"DELETE";
			break;
	}
	return result;
}

+ (NSString*)nonceString
{
	return [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
}
@end

