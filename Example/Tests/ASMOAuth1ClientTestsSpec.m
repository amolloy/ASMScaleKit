//
//  ASMOAuth1ClientTestsSpec.m
//  ASMScaleKit
//
//  Created by Andrew Molloy on 7/14/14.
//  Copyright 2014 Andrew Molloy. All rights reserved.
//

#import <Expecta/Expecta.h>
#import <ASMSCaleKit/ASMOAuth1Client.h>

// Yeah I know this is bad, but better than making a class category with a name like "fortesting"
// just for one method.
@interface ASMOAuth1Client ()
- (NSString*)HMACSHA1SignatureForURLRequest:(NSURLRequest*)request
							queryParameters:(NSArray*)queryParameters
						 postBodyParameters:(NSArray*)postBodyParameters
									  token:(ASMOAuth1Token*)token;
@end

SpecBegin(ASMOAuth1Client)

describe(@"ASMOAuth1Client", ^{
	it(@"should calculate HMAC-SHA1 correctly",
	   ^{
		   NSURL* url = [NSURL URLWithString:@"https://oauth.withings.com"];
		   ASMOAuth1Client* testClient = [[ASMOAuth1Client alloc] initWithOAuthURLBase:url
																				   key:@"abcdef0123456789abcdef"
																				secret:@"abcdef0123456789abcdef"];

		   NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[url URLByAppendingPathComponent:@"account/request_token"]];

		   NSString* signature =
		   [testClient HMACSHA1SignatureForURLRequest:request
									  queryParameters:@[@"oauth_callback=http%3A%2F%2Fexample.com%2Fget_access_token",
														@"oauth_consumer_key=abcdef0123456789abcdef",
														@"oauth_nonce=f71972b1fa93b8935ccaf34ee02d7657",
														@"oauth_signature_method=HMAC-SHA1",
														@"oauth_timestamp=1311778988",
														@"oauth_version=1.0"]
								   postBodyParameters:nil
												token:nil];
		   expect(signature).to.equal(@"cFj/h2sytYG/7N/szT4OjjdPgD0=");
	   }
	   );
});

SpecEnd
