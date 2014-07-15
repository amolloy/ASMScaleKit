//
//  ASMOAuth1Token.m
//  Pods
//
//  Created by Andrew Molloy on 7/14/14.
//
//

#import "ASMOAuth1Token.h"

@interface ASMOAuth1Token ()
@property (nonatomic, copy, readwrite) NSString* key;
@property (nonatomic, copy, readwrite) NSString* secret;
@property (nonatomic, copy, readwrite) NSString* session;
@property (nonatomic, strong, readwrite) NSDate* expiration;
@property (nonatomic, assign, readwrite) BOOL renewable;
@end

@implementation ASMOAuth1Token

- (id)initWithResponseString:(NSString*)responseString
{
	NSDictionary* attributes = [[self class] parametersFromResponseString:responseString];

	if ([responseString length] == 0 || [attributes count] == 0)
	{
		self = nil;
	}
	else
	{
		NSString* key = attributes[@"oauth_token"];
		NSString* secret = attributes[@"oauth_token_secret"];
		NSString* session = attributes[@"oauth_session_handle"];

		NSDate* expiration = nil;
		if (attributes[@"oauth_token_duration"])
		{
			expiration = [NSDate dateWithTimeIntervalSinceNow:[attributes[@"oauth_token_duration"] doubleValue]];
		}

		BOOL canBeRenewed = NO;
		if (attributes[@"oauth_token_renewable"])
		{
			NSString* renewable = [attributes[@"oauth_token_renewable"] lowercaseString];
			canBeRenewed = renewable && [renewable hasPrefix:@"t"];
		}

		self = [self initWithKey:key
						  secret:secret
						 session:session
					  expiration:expiration
					   renewable:canBeRenewed];
		if (self)
		{
			NSMutableDictionary* mutableUserInfo = [attributes mutableCopy];
			[mutableUserInfo removeObjectsForKeys:@[@"oauth_token", @"oauth_token_secret", @"oauth_session_handle", @"oauth_token_duration", @"oauth_token_renewable"]];

			if ([mutableUserInfo count] > 0)
			{
				self.userInfo = [NSDictionary dictionaryWithDictionary:mutableUserInfo];
			}
		}
	}

    return self;
}

- (id)initWithKey:(NSString*)key
           secret:(NSString*)secret
          session:(NSString*)session
       expiration:(NSDate*)expiration
        renewable:(BOOL)canBeRenewed
{
    NSParameterAssert(key);
    NSParameterAssert(secret);

    self = [super init];
	if (self)
	{
		self.key = key;
		self.secret = secret;
		self.session = session;
		self.expiration = expiration;
		self.renewable = canBeRenewed;
	}

    return self;
}

- (BOOL)isExpired
{
    return [self.expiration compare:[NSDate date]] == NSOrderedAscending;
}

+ (NSDictionary*)parametersFromResponseString:(NSString*)responseString
{
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    if (responseString)
	{
        NSScanner* parameterScanner = [[NSScanner alloc] initWithString:responseString];
        NSString* key = nil;
        NSString* value = nil;

        while (![parameterScanner isAtEnd])
		{
            key = nil;
            [parameterScanner scanUpToString:@"=" intoString:&key];
            [parameterScanner scanString:@"=" intoString:nil];

            value = nil;
            [parameterScanner scanUpToString:@"&" intoString:&value];
            [parameterScanner scanString:@"&" intoString:nil];

            if (key && value)
			{
				key = [key stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

				parameters[key] = value;
            }
        }
    }

    return parameters;
}
@end
