//
//  ASMWithingUser.m
//  Pods
//
//  Created by Andrew Molloy on 7/12/14.
//
//

#import "ASMWithingsUser.h"
#import "ASMOAuth1Token.h"

static NSString* const kWithingsUserKeychainPrefix = @"com.asmscalekit.withings.";

@interface ASMWithingsUser ()
@property (nonatomic, copy, readwrite) NSString* userid;
@property (nonatomic, strong, readwrite) ASMOAuth1Token* accessToken;
@property (nonatomic, copy, readwrite) NSString* name;
@end

@implementation ASMWithingsUser

- (NSString*)displayName
{
	return self.name;
}

- (instancetype)initWithUserId:(NSString*)userid
		  permenantAccessToken:(ASMOAuth1Token*)token
						  name:(NSString*)name
{
	self = [super init];
	if (self)
	{
		self.userid = userid;
		self.accessToken = token;
		self.name = name;
	}
	return self;
}

- (BOOL)authenticated
{
	return self.accessToken && ![self.accessToken isExpired];
}

#pragma mark - Keychain
- (NSString*)keychainName
{
	return [kWithingsUserKeychainPrefix stringByAppendingString:self.userid];
}

- (BOOL)storeSensitiveInformationInKeychain:(NSError*__autoreleasing*)outError
{
	return [self.accessToken storeInKeychainWithName:[self keychainName]
											   error:outError];
}

- (BOOL)retrieveSensitiveInformationFromKeychain:(NSError*__autoreleasing*)outError
{
	self.accessToken = [ASMOAuth1Token oauth1TokenFromKeychainItemName:[self keychainName]
																 error:outError];
	return (self.accessToken != nil);
}

#pragma mark - NSSecureCoding

- (id)initWithCoder:(NSCoder*)aDecoder
{
	self = [super init];
	if (self)
	{
		self.userid = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"userid"];
		self.name = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"name"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder*)aCoder
{
	[aCoder encodeObject:self.userid forKey:@"userid"];
	[aCoder encodeObject:self.name forKey:@"name"];
}

+ (BOOL)supportsSecureCoding
{
	return YES;
}

@end
