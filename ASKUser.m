//
//  ASKUser.m
//  Pods
//
//  Created by Andrew Molloy on 7/11/14.
//
//

#import "ASKUser.h"

@implementation ASKUser

- (NSString*)displayName
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (void)getEntriesFromDate:(NSDate*)startDate
					toDate:(NSDate*)endDate
				lastUpdate:(NSDate*)lastUpdate
					 limit:(NSNumber*)limit
					offset:(NSNumber*)offset
				completion:(void(^)(NSArray* entries, NSError* error))completion
{
	[self doesNotRecognizeSelector:_cmd];
}

- (BOOL)authenticated
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

- (BOOL)storeSensitiveInformationInKeychain:(NSError*__autoreleasing*)outError
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

- (BOOL)retrieveSensitiveInformationFromKeychain:(NSError*__autoreleasing*)outError
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

+ (BOOL)supportsSecureCoding
{
	return YES;
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
	return [self init];
}

- (void)encodeWithCoder:(NSCoder*)aCoder
{
}

@end
