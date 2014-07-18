//
//  ASMOAuthManager.h
//  Pods
//
//  Created by Andrew Molloy on 7/13/14.
//
//

#import <Foundation/Foundation.h>
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
#endif

@class ASKOAuth1Token;

typedef NS_ENUM(NSInteger, ASKOAuth1ProtocolParameterLocation)
{
	ASKOAuth1ProtocolParameterAuthorizationHeaderLocation,
	ASKOAuth1ProtocolParameterPostBodyLocation,
	ASKOAuth1ProtocolParameterURLQueryLocation
};

typedef NS_ENUM(NSInteger, ASKOAuth1ClientAccessMethod)
{
	ASKOAuth1ClientAccessGETMethod,
	ASKOAuth1ClientAccessPOSTMethod,
	ASKOAuth1ClientAccessHEADMethod,
	ASKOAuth1ClientAccessDELETEMethod,
};

typedef NS_ENUM(NSInteger, ASKOAuth1ClientSignatureMethod)
{
	ASKOAuth1ClientPlainTextSignatureMethod,
	ASKOAuth1ClientHMACSHA1SignatureMethod,
};

typedef NS_OPTIONS(NSInteger, ASKOAuth1ClientProviderHint)
{
	ASKOAuth1ClientProviderNoHint = 0,
	ASKOAuth1ClientProviderIncludeUserInfoInAccessRequestHint = 1 << 0,
	ASKOAuth1ClientProviderSuppressVerifierHint = 1 << 1,
	ASKOAuth1ClientIncludeFullOAuthParametersInAuthenticationHint = 1 << 2
};

extern NSInteger ASKOAuth1ClientWithingsProviderHints;

@interface ASKOAuth1Client : NSObject

@property (nonatomic, assign) ASKOAuth1ClientProviderHint providerHints;
@property (nonatomic, assign) ASKOAuth1ProtocolParameterLocation protocolParameterLocation;
@property (nonatomic, assign) ASKOAuth1ClientSignatureMethod signatureMethod;
@property (nonatomic, copy) NSString* realm;
@property (nonatomic, strong, readonly) ASKOAuth1Token* accessToken;
@property (nonatomic, assign) NSUInteger stringEncoding;

- (instancetype)initWithOAuthURLBase:(NSURL*)oauthURLBase key:(NSString*)key secret:(NSString*)secret;

typedef void(^ASKOAuth1ClientAuthorizeCompletion)(ASKOAuth1Token* token, NSError* error);

- (void)authorizeWithRequestTokenPath:(NSString*)tokenPath
			   userAuthenticationPath:(NSString*)authorizationPath
					  accessTokenPath:(NSString*)accessTokenPath
								scope:(NSString*)scope
						 accessMethod:(ASKOAuth1ClientAccessMethod)accessMethod
#if __IPHONE_OS_VERSION_MIN_REQUIRED
				   fromViewController:(UIViewController*)viewController
#endif
						   completion:(ASKOAuth1ClientAuthorizeCompletion)completion;

- (NSURLRequest*)requestWithOAuthParametersFromURLRequest:(NSURLRequest*)request
											  accessToken:(ASKOAuth1Token*)accessToken;
@end
