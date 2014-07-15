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

static NSString * const kASMOAuth1Version = @"1.0";

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
@property (nonatomic, strong) NSURL* baseURL;
@property (nonatomic, copy) NSString* consumerKey;
@property (nonatomic, copy) NSString* consumerSecret;
@property (nonatomic, strong, readwrite) ASMOAuth1Token* accessToken;
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
						  callbackURL:(NSURL*)callbackURL
								scope:(NSString*)scope
						 accessMethod:(ASMOAuth1ClientAccessMethod)accessMethod
			 requestParameterLocation:(ASMOAuth1ClientRequestParameterLocation)requestParameterLocation
						   completion:(ASMOauth1ClientAuthorizeCompletion)completion
{
	[self acquireOAuthRequestTokenWithPath:tokenPath
							   callbackURL:(NSURL*)callbackURL
									 scope:scope
							  accessMethod:accessMethod
				  requestParameterLocation:requestParameterLocation
								completion:^(ASMOAuth1Token *requestToken, NSError *error) {
									NSLog(@"Got the access token.");
								}];
}

- (void)acquireOAuthRequestTokenWithPath:(NSString*)path
							 callbackURL:(NSURL*)callbackURL
								   scope:(NSString*)scope
							accessMethod:(ASMOAuth1ClientAccessMethod)accessMethod
				requestParameterLocation:(ASMOAuth1ClientRequestParameterLocation)requestParameterLocation
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
												  requestParameterLocation:requestParameterLocation
															   callbackURL:callbackURL];

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
			else
			{
				// TODO
				error = [NSError errorWithDomain:@"TODO" code:1 userInfo:nil];
			}
		}

		if (completion)
		{
			completion(accessToken, error);
		}
	}] resume];
}

- (NSURLRequest*)requestWithOAuthParametersFromURLRequest:(NSURLRequest*)request
								 requestParameterLocation:(ASMOAuth1ClientRequestParameterLocation)requestParameterLocation
{
	return [self requestWithOAuthParametersFromURLRequest:request
								 requestParameterLocation:requestParameterLocation
											  callbackURL:nil];
}

- (NSURLRequest*)requestWithOAuthParametersFromURLRequest:(NSURLRequest*)request
								 requestParameterLocation:(ASMOAuth1ClientRequestParameterLocation)requestParameterLocation
											  callbackURL:(NSURL*)callbackURL
{
	NSMutableURLRequest* newRequest = request.mutableCopy;

	if (ASMOAuth1ClientRequestParameterURLQueryLocation == requestParameterLocation)
	{
		NSURLComponents* urlComponents = [NSURLComponents componentsWithURL:request.URL
													resolvingAgainstBaseURL:NO];
		NSString* query = [urlComponents query];

		if (query)
		{
			query = [query stringByAppendingString:@"&"];
		}
		else
		{
			query = @"";
		}

		NSMutableArray* oauthParameters = [self oauthParametersQueryComponents].mutableCopy;
		if (callbackURL)
		{
			[oauthParameters addObject:[NSString stringWithFormat:@"oauth_callback=%@",
										[[callbackURL absoluteString] stringByAddingPercentEncodingWithAllowedCharacters:oauthParameterValidCharacterSet()]]];
		}

		NSString* signature = [self oauthSignatureForURLRequest:newRequest
												queryParameters:oauthParameters
											 postBodyParameters:nil
														  token:self.accessToken];

		[oauthParameters addObject:[NSString stringWithFormat:@"oauth_signature=%@",
									[signature stringByAddingPercentEncodingWithAllowedCharacters:oauthParameterValidCharacterSet()]]];

		[oauthParameters sortUsingSelector:@selector(compare:)];

		urlComponents.percentEncodedQuery = [query stringByAppendingString:[oauthParameters componentsJoinedByString:@"&"]];
		newRequest.URL = urlComponents.URL;
	}
	else if (ASMOAuth1ClientRequestParameterAuthorizationHeaderLocation == requestParameterLocation)
	{
		[newRequest setValue:[self authorizationHeaderForURLRequest:request]
		  forHTTPHeaderField:@"Authorization"];
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

