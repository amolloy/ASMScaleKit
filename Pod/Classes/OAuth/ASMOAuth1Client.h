//
//  ASMOAuthManager.h
//  Pods
//
//  Created by Andrew Molloy on 7/13/14.
//
//

#import <Foundation/Foundation.h>

@class ASMOAuth1Token;

typedef NS_ENUM(NSInteger, ASMOAuth1ClientRequestParameterLocation)
{
	ASMOAuth1ClientRequestParameterAuthorizationHeaderLocation,
	ASMOAuth1ClientRequestParameterPostBodyLocation,
	ASMOAuth1ClientRequestParameterURLQueryLocation
};

typedef NS_ENUM(NSInteger, ASMOAuth1ClientAccessMethod)
{
	ASMOAUTH1ClientAccessGETMethod,
	ASMOAUTH1ClientAccessPOSTMethod,
	ASMOAUTH1ClientAccessHEADMethod,
	ASMOAUTH1ClientAccessDELETEMethod,
};

typedef NS_ENUM(NSInteger, ASMOAuth1ClientSignatureMethod)
{
	ASMOAuth1ClientPlainTextSignatureMethod,
	ASMOAuth1ClientHMACSHA1SignatureMethod,
};

@interface ASMOAuth1Client : NSObject

@property (nonatomic, assign) ASMOAuth1ClientSignatureMethod signatureMethod;
@property (nonatomic, copy) NSString* realm;
@property (nonatomic, strong, readonly) ASMOAuth1Token* accessToken;
@property (nonatomic, assign) NSUInteger stringEncoding;

- (instancetype)initWithBaseURL:(NSURL*)baseURL key:(NSString*)key secret:(NSString*)secret;

typedef void(^ASMOauth1ClientAuthorizeCompletion)(ASMOAuth1Token* token, NSError* error);

- (void)authorizeWithRequestTokenPath:(NSString*)tokenPath
			   userAuthenticationPath:(NSString*)authorizationPath
					  accessTokenPath:(NSString*)accessTokenPath
								scope:(NSString*)scope
						 accessMethod:(ASMOAuth1ClientAccessMethod)accessMethod
			 requestParameterLocation:(ASMOAuth1ClientRequestParameterLocation)requestParameterLocation
#if __IPHONE_OS_VERSION_MIN_REQUIRED
				   fromViewController:(UIViewController*)viewController
#endif
						   completion:(ASMOauth1ClientAuthorizeCompletion)completion;


// TODO This does not need to be public.
- (NSString*)HMACSHA1SignatureForURLRequest:(NSURLRequest*)request
							queryParameters:(NSArray*)queryParameters
						 postBodyParameters:(NSArray*)postBodyParameters
									  token:(ASMOAuth1Token*)token;

@end
