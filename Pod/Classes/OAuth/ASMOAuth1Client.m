//
//  ASMOAuthManager.m
//  Pods
//
//  Created by Andrew Molloy on 7/13/14.
//
//

#import "ASMOAuth1Client.h"
#import "ASMOAuth1Token.h"
#import <CommonCrypto/CommonHMAC.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import "ASMOAuth1AuthenticationViewController.h"
#endif

static NSString* const kASMOAuth1Version = @"1.0";
static NSString* const kASMOAuth1CallbackURLString = @"asmoauth1client://success";

@interface NSString (ASMOAuth1ClientHelpers)
+ (NSString*)stringWithOAuth1ClientSignatureMethod:(ASMOAuth1ClientSignatureMethod)signatureMethod;
+ (NSString*)stringWithOAuth1ClientAccessMethod:(ASMOAuth1ClientAccessMethod)clientAccessMethod;
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

@interface ASMOAuth1Client ()
@property (nonatomic, copy) NSString* consumerKey;
@property (nonatomic, copy) NSString* consumerSecret;
@property (nonatomic, strong, readwrite) ASMOAuth1Token* accessToken;
@property (nonatomic, copy) ASMOauth1ClientAuthorizeCompletion authorizationCompletion;

#if __IPHONE_OS_VERSION_MIN_REQUIRED
@property (nonatomic, strong) UIViewController* presentingViewController;
#endif
@end

@implementation ASMOAuth1Client

- (instancetype)initWithBaseURL:(NSURL*)baseURL key:(NSString*)key secret:(NSString*)secret
{
	self = [super init];
	if (self)
	{
		self.baseURL = baseURL;
		self.consumerKey = key;
		self.consumerSecret = secret;
		self.signatureMethod = ASMOAuth1ClientHMACSHA1SignatureMethod;
		self.stringEncoding = NSUTF8StringEncoding;
	}
	return self;
}

- (void)authorizeWithRequestTokenPath:(NSString*)tokenPath
			   userAuthenticationPath:(NSString*)authorizationPath
					  accessTokenPath:(NSString*)accessTokenPath
								scope:(NSString*)scope
						 accessMethod:(ASMOAuth1ClientAccessMethod)accessMethod
#if __IPHONE_OS_VERSION_MIN_REQUIRED
				   fromViewController:(UIViewController*)viewController
#endif
						   completion:(ASMOauth1ClientAuthorizeCompletion)completion
{
	self.authorizationCompletion = completion;

	__weak typeof(self) wself = self;
	[self acquireOAuthRequestTokenWithPath:tokenPath
									 scope:scope
							  accessMethod:accessMethod
								completion:^(ASMOAuth1Token* requestToken, NSError* error)
	 {
		 __strong typeof(self) self = wself;
		 if (!error)
		 {
#if __IPHONE_OS_VERSION_MIN_REQUIRED
			 self.presentingViewController = viewController;
			 [self authenticateUserWithPath:authorizationPath
							accessTokenPath:accessTokenPath
							   requestToken:requestToken
							   accessMethod:accessMethod
								 completion:^(ASMOAuth1Token *token, NSError *error)
			 {
				 NSLog(@"Authenticated user");
			 }];
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
					requestToken:(ASMOAuth1Token*)requestToken
					accessMethod:(ASMOAuth1ClientAccessMethod)accessMethod
					  completion:(ASMOauth1ClientAuthorizeCompletion)completion
{
	NSURLComponents* urlComponents = [NSURLComponents componentsWithURL:[self.baseURL URLByAppendingPathComponent:path]
												resolvingAgainstBaseURL:NO];
	urlComponents.percentEncodedQuery = [NSString stringWithFormat:@"oauth_token=%@", [requestToken.key stringByAddingPercentEncodingWithAllowedCharacters:oauthParameterValidCharacterSet()]];

	__weak typeof(self) wself = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		ASMOAuth1AuthenticationViewController* vc = [[ASMOAuth1AuthenticationViewController alloc]
													 initWithAuthorizationURL:urlComponents.URL
													 sentinelURL:[NSURL URLWithString:kASMOAuth1CallbackURLString]
													 completion:^(NSURL* authorizationURL, NSError* error)
													 {
														 __strong typeof(self) self = wself;
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
					requestToken:(ASMOAuth1Token*)requestToken
					accessMethod:(ASMOAuth1ClientAccessMethod)accessMethod
						   error:(NSError*)error
{
	if (!error)
	{
		NSDictionary* parameters = [self parametersFromQueryString:url.query];
		requestToken.verifier = parameters[@"oauth_verifier"];

		__weak typeof(self) wself = self;
		[self acquireOAuthAccessTokenWithPath:accessTokenPath
								 requestToken:requestToken
								 accessMethod:accessMethod
								   completion:^(ASMOAuth1Token* accessToken, id responseObject, NSError* error)
		 {
			 __strong typeof(self) self = wself;
			 if (self.authorizationCompletion)
			 {
				 self.authorizationCompletion(accessToken, error);
			 }
		 }];
	}
	else if (self.authorizationCompletion)
	{
		self.authorizationCompletion(nil, error);
	}
}

- (void)acquireOAuthAccessTokenWithPath:(NSString*)path
                           requestToken:(ASMOAuth1Token*)requestToken
                           accessMethod:(ASMOAuth1ClientAccessMethod)accessMethod
							 completion:(void (^)(ASMOAuth1Token* accessToken, id responseObject, NSError* error))completion
{
	NSAssert(accessMethod != ASMOAUTH1ClientAccessPOSTMethod, @"POST not yet supported");

    if (requestToken.key && requestToken.verifier)
	{
        self.accessToken = requestToken;

		NSURLComponents* components = [NSURLComponents componentsWithURL:[self.baseURL URLByAppendingPathComponent:path]
												 resolvingAgainstBaseURL:NO];

		NSString* oauthVerifierParam = [NSString stringWithFormat:@"oauth_verifier=%@",
										[requestToken.verifier stringByAddingPercentEncodingWithAllowedCharacters:oauthParameterValidCharacterSet()]];

		components.percentEncodedQuery = oauthVerifierParam;

		NSMutableURLRequest* mutableRequest = [NSMutableURLRequest requestWithURL:components.URL];
		[mutableRequest setHTTPMethod:[NSString stringWithOAuth1ClientAccessMethod:accessMethod]];
		[mutableRequest setHTTPBody:nil];

		NSURLRequest* request = [self requestWithOAuthParametersFromURLRequest:mutableRequest];

		NSURLSession* session = [NSURLSession sharedSession];
		[[session dataTaskWithRequest:request completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
			ASMOAuth1Token* accessToken = nil;
			if (!error)
			{
				NSString* responseString = [[NSString alloc] initWithData:data encoding:self.stringEncoding];
				if (responseString)
				{
					accessToken = [[ASMOAuth1Token alloc] initWithResponseString:responseString];
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
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:NSLocalizedStringFromTable(@"Bad OAuth response received from the server.", @"ASMOAuth1Client", nil) forKey:NSLocalizedFailureReasonErrorKey];
        NSError* error = [[NSError alloc] initWithDomain:@"com.amolloy.oauth1client"
													code:NSURLErrorBadServerResponse
												userInfo:userInfo];
        completion(nil, nil, error);
    }
}

- (void)acquireOAuthRequestTokenWithPath:(NSString*)path
								   scope:(NSString*)scope
							accessMethod:(ASMOAuth1ClientAccessMethod)accessMethod
							  completion:(void(^)(ASMOAuth1Token* requestToken, NSError* error))completion
{
	NSAssert(ASMOAUTH1ClientAccessPOSTMethod != accessMethod, @"POST not yet supported");

	NSURLComponents* urlComponents = [NSURLComponents componentsWithURL:[self.baseURL URLByAppendingPathComponent:path]
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
															   callbackURL:[NSURL URLWithString:kASMOAuth1CallbackURLString]];

	NSURLSession* session = [NSURLSession sharedSession];
	[[session dataTaskWithRequest:request completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
		ASMOAuth1Token* accessToken = nil;

		if (!error)
		{
			NSString* responseString = [[NSString alloc] initWithData:data encoding:self.stringEncoding];
			if (responseString)
			{
				accessToken = [[ASMOAuth1Token alloc] initWithResponseString:responseString];
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
{
	return [self requestWithOAuthParametersFromURLRequest:request
											  callbackURL:nil];
}

- (NSURLRequest*)requestWithOAuthParametersFromURLRequest:(NSURLRequest*)request
											  callbackURL:(NSURL*)callbackURL
{
	NSAssert(ASMOAuth1ProtocolParameterURLQueryLocation == self.protocolParameterLocation, @"Not yet implemented");

	NSMutableURLRequest* newRequest = request.mutableCopy;

	if (ASMOAuth1ProtocolParameterURLQueryLocation == self.protocolParameterLocation)
	{
		NSMutableArray* parameters = [self oauthParametersQueryComponents].mutableCopy;
		if (callbackURL)
		{
			[parameters addObject:[NSString stringWithFormat:@"oauth_callback=%@",
										[[callbackURL absoluteString] stringByAddingPercentEncodingWithAllowedCharacters:oauthParameterValidCharacterSet()]]];
		}
		if (self.accessToken)
		{
			[parameters addObject:[NSString stringWithFormat:@"oauth_token=%@",
										[self.accessToken.key stringByAddingPercentEncodingWithAllowedCharacters:oauthParameterValidCharacterSet()]]];
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
														  token:self.accessToken];

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
									   token:(ASMOAuth1Token*)token
{
    NSString* secret = @""; // token ? token.secret : @"";
    NSString* signature = [NSString stringWithFormat:@"%@&%@", self.consumerSecret, secret];
    return signature;
}

- (NSString*)HMACSHA1SignatureForURLRequest:(NSURLRequest*)request
							queryParameters:(NSArray*)queryParameters
						 postBodyParameters:(NSArray*)postBodyParameters
									  token:(ASMOAuth1Token*)token
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
								   token:(ASMOAuth1Token*)token
{
	NSString* signature = nil;

    switch (self.signatureMethod)
	{
        case ASMOAuth1ClientPlainTextSignatureMethod:
            signature = [self plainTextSignatureForURLRequest:request
														token:token];
			break;
        case ASMOAuth1ClientHMACSHA1SignatureMethod:
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

#pragma mark = NSString+ASMOAuth1ClientHelpers

@implementation NSString (ASMOAuth1ClientHelpers)
+ (NSString*)stringWithOAuth1ClientSignatureMethod:(ASMOAuth1ClientSignatureMethod)signatureMethod
{
	NSString* result = nil;
	switch (signatureMethod)
	{
		case ASMOAuth1ClientPlainTextSignatureMethod:
			result = @"PLAINTEXT";
			break;
		case ASMOAuth1ClientHMACSHA1SignatureMethod:
			result = @"HMAC-SHA1";
			break;
	}

	return result;
}

+ (NSString*)stringWithOAuth1ClientAccessMethod:(ASMOAuth1ClientAccessMethod)clientAccessMethod
{
	NSString* result = nil;
	switch (clientAccessMethod)
	{
		case ASMOAUTH1ClientAccessGETMethod:
			result = @"GET";
			break;
		case ASMOAUTH1ClientAccessPOSTMethod:
			result = @"POST";
			break;
		case ASMOAUTH1ClientAccessHEADMethod:
			result = @"HEAD";
			break;
		case ASMOAUTH1ClientAccessDELETEMethod:
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

