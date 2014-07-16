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

@class ASMOAuth1Token;

typedef NS_ENUM(NSInteger, ASMOAuth1ProtocolParameterLocation)
{
	ASMOAuth1ProtocolParameterAuthorizationHeaderLocation,
	ASMOAuth1ProtocolParameterPostBodyLocation,
	ASMOAuth1ProtocolParameterURLQueryLocation
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

typedef NS_OPTIONS(NSInteger, ASMOAuth1ClientProviderHint)
{
	ASMOAuth1ClientProviderNoHint = 0,
	ASMOAuth1ClientProviderIncludeUserInfoInAccessRequestHint = 1 << 0,
	ASMOAuth1ClientProviderSuppressVerifierHint = 1 << 1,
	ASMOAuth1ClientIncludeFullOAuthParametersInAuthenticationHint = 1 << 2
};

extern NSInteger ASMOAuth1ClientWithingsProviderHints;

@interface ASMOAuth1Client : NSObject

@property (nonatomic, assign) ASMOAuth1ClientProviderHint providerHints;
@property (nonatomic, assign) ASMOAuth1ProtocolParameterLocation protocolParameterLocation;
@property (nonatomic, assign) ASMOAuth1ClientSignatureMethod signatureMethod;
@property (nonatomic, copy) NSString* realm;
@property (nonatomic, strong, readonly) ASMOAuth1Token* accessToken;
@property (nonatomic, assign) NSUInteger stringEncoding;

- (instancetype)initWithOAuthURLBase:(NSURL*)oauthURLBase key:(NSString*)key secret:(NSString*)secret;

typedef void(^ASMOauth1ClientAuthorizeCompletion)(ASMOAuth1Token* token, NSError* error);

- (void)authorizeWithRequestTokenPath:(NSString*)tokenPath
			   userAuthenticationPath:(NSString*)authorizationPath
					  accessTokenPath:(NSString*)accessTokenPath
								scope:(NSString*)scope
						 accessMethod:(ASMOAuth1ClientAccessMethod)accessMethod
#if __IPHONE_OS_VERSION_MIN_REQUIRED
				   fromViewController:(UIViewController*)viewController
#endif
						   completion:(ASMOauth1ClientAuthorizeCompletion)completion;

- (NSURLRequest*)requestWithOAuthParametersFromURLRequest:(NSURLRequest*)request;
@end
