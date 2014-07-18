//
//  ASMWithingUser.m
//  Pods
//
//  Created by Andrew Molloy on 7/12/14.
//
//

#import "ASKWithingsUser.h"
#import "ASKOAuth1Token.h"
#import "ASKOAuth1Client.h"
#import "ASKMeasurement.h"
#import "ASKWithingsProvider.h"
#import "ASKProviderManager.h"
#import <libextobjc/EXTScope.h>

static NSString* const kWithingsUserKeychainPrefix = @"com.asmscalekit.withings.";

@interface ASKWithingsUser ()
@property (nonatomic, copy, readwrite) NSString* userId;
@property (nonatomic, strong, readwrite) ASKOAuth1Token* accessToken;
@property (nonatomic, copy, readwrite) NSString* name;
@end

@implementation ASKWithingsUser

- (NSString*)displayName
{
	return self.name;
}

- (instancetype)initWithUserId:(NSString*)userId
		  permenantAccessToken:(ASKOAuth1Token*)token
						  name:(NSString*)name
{
	self = [super init];
	if (self)
	{
		self.userId = userId;
		self.accessToken = token;
		self.name = name;
	}
	return self;
}

- (BOOL)authenticated
{
	return self.accessToken && ![self.accessToken isExpired];
}

- (void)getEntriesFromDate:(NSDate*)startDate
					toDate:(NSDate*)endDate
				lastUpdate:(NSDate*)lastUpdate
					 limit:(NSNumber*)limit
					offset:(NSNumber*)offset
				completion:(void(^)(NSArray* entries, NSError* error))completion
{
	ASKWithingsProvider* serviceProvider = [[ASKProviderManager sharedManager] serviceProviderForUser:self];

	NSURL* baseURL = [NSURL URLWithString:ASMWithingsBaseURLString];
	NSURLComponents* components = [NSURLComponents componentsWithURL:[baseURL URLByAppendingPathComponent:@"measure"]
											 resolvingAgainstBaseURL:NO];

	NSMutableDictionary* parameters = @{@"action": @"getmeas",
										@"userid": self.userId,
										@"meastype": @"1",
										@"category": @"1"}.mutableCopy;

	if (startDate)
	{
		parameters[@"startdate"] = [@([startDate timeIntervalSince1970]) stringValue];
	}
	if (endDate)
	{
		parameters[@"enddate"] = [@([endDate timeIntervalSince1970]) stringValue];
	}
	if (lastUpdate)
	{
		parameters[@"lastupdate"] = [@([lastUpdate timeIntervalSince1970]) stringValue];
	}
	if (limit)
	{
		parameters[@"limit"] = [limit stringValue];
	}
	if (offset)
	{
		parameters[@"offset"] = [offset stringValue];
	}

	NSMutableCharacterSet* allowedCharacters = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
	[allowedCharacters addCharactersInString:@"-._~"];

	NSMutableArray* kvPairs = [NSMutableArray arrayWithCapacity:parameters.count];
	[parameters enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSString* value, BOOL *stop) {
		NSString* encodedValue = [value stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
		[kvPairs addObject:[NSString stringWithFormat:@"%@=%@", key, encodedValue]];
	}];

	components.query = [kvPairs componentsJoinedByString:@"&"];

	NSURLRequest* request = [NSURLRequest requestWithURL:components.URL];
	request = [serviceProvider.client requestWithOAuthParametersFromURLRequest:request
														accessToken:self.accessToken];

	@weakify(self);
	NSURLSession* session = [NSURLSession sharedSession];
	[[session dataTaskWithRequest:request
				completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
					@strongify(self);
					NSError* outError = nil;
					NSArray* measurements = nil;
					if (!error)
					{
						NSString* responseString = [[NSString alloc] initWithData:data
																		 encoding:NSUTF8StringEncoding];
						NSData* responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
						NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:responseData
																					 options:0
																					   error:&outError];

						measurements = [self measurementsFromJSONDictionary:responseDict
																	  error:&outError];
					}

					if (completion)
					{
						completion(measurements, outError);
					}
				}] resume];
}

- (NSArray*)measurementsFromJSONDictionary:(NSDictionary*)json
									 error:(NSError*__autoreleasing*)outError
{
	NSError* error = nil;
	NSInteger status = -1;
	if (json[@"status"] && [json[@"status"] isKindOfClass:[NSNumber class]])
	{
		NSNumber* statusNumber = json[@"status"];
		status = [statusNumber integerValue];
	}

	NSMutableArray* measurements = [NSMutableArray array];
	// All of Withings (current) status codes are >= 0
	if (-1 == status)
	{
		error = [NSError errorWithDomain:@"com.amolloy.asmwithingsserviceprovider"
									code:-1
								userInfo:@{NSLocalizedDescriptionKey:@"Unexpected response"}];
	}
	else if (0 != status)
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
			NSArray* measureGroups = body[@"measuregrps"];
			if (!measureGroups)
			{
				error = [NSError errorWithDomain:@"com.amolloy.asmwithingsserviceprovider"
											code:-1
										userInfo:@{NSLocalizedDescriptionKey:@"Unexpected response, no measurement groups"}];
			}
			else
			{
				[measureGroups enumerateObjectsUsingBlock:^(NSDictionary* group, NSUInteger grpIdx, BOOL* grpsStop) {
					NSArray* measures = group[@"measures"];
					__block NSDecimalNumber* measure = nil;
					[measures enumerateObjectsUsingBlock:^(NSDictionary* m, NSUInteger measureIdx, BOOL* measuresStop) {
						if ([m[@"type"] integerValue] == 1) // type 1 = Weight in Kg
						{
							NSUInteger value = [m[@"value"] unsignedIntegerValue];
							short unit = [m[@"unit"] shortValue];

							measure = [NSDecimalNumber decimalNumberWithMantissa:value
																		exponent:unit
																	  isNegative:NO];
							if (measure)
							{
								*measuresStop = YES;
							}
						}
					}];

					if (measure)
					{
						NSString* grpId = [group[@"grpid"] stringValue];
						NSDate* date = [NSDate dateWithTimeIntervalSince1970:[group[@"date"] doubleValue]];

						ASKMeasurement* skmeasure = [[ASKMeasurement alloc] initWithDate:date
																							  weightInKg:measure
																								uniqueId:grpId];

						[measurements addObject:skmeasure];
					}
				}];
			}
		}
	}

	if (outError)
	{
		*outError = error;
	}

	return measurements.copy;
}

#pragma mark - Keychain
- (NSString*)keychainName
{
	NSString* keychainName = nil;
	if (self.userId)
	{
		keychainName = [kWithingsUserKeychainPrefix stringByAppendingString:self.userId];
	}
	return keychainName;
}

- (BOOL)storeSensitiveInformationInKeychain:(NSError*__autoreleasing*)outError
{
	return [self.accessToken storeInKeychainWithName:[self keychainName]
											   error:outError];
}

- (BOOL)retrieveSensitiveInformationFromKeychain:(NSError*__autoreleasing*)outError
{
	self.accessToken = [ASKOAuth1Token oauth1TokenFromKeychainItemName:[self keychainName]
																 error:outError];
	return (self.accessToken != nil);
}

#pragma mark - NSSecureCoding

- (id)initWithCoder:(NSCoder*)aDecoder
{
	self = [super init];
	if (self)
	{
		self.userId = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"userid"];
		self.name = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"name"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder*)aCoder
{
	[aCoder encodeObject:self.userId forKey:@"userid"];
	[aCoder encodeObject:self.name forKey:@"name"];
}

+ (BOOL)supportsSecureCoding
{
	return YES;
}

@end
