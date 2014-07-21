//
//  NSDictionary+ASKKeychain.m
//  Pods
//
//  Created by Andrew Molloy on 7/20/14.
//
//

#import "NSDictionary+ASKKeychain.h"
#import <Security/Security.h>

@implementation NSDictionary (ASKKeychain)

- (NSData*)ask_serializedDataForKeychainError:(NSError*__autoreleasing*)error
{
	return [NSPropertyListSerialization dataWithPropertyList:self
													  format:NSPropertyListXMLFormat_v1_0
													 options:0
													   error:error];
}

- (BOOL)ask_storeToKeychainWithKey:(NSString*)aKey error:(NSError*__autoreleasing*)error
{
	BOOL stored = NO;
	NSData* serializedDictionary = [self ask_serializedDataForKeychainError:error];
    if(serializedDictionary)
	{
        (void)[self ask_deleteFromKeychainWithKey:aKey error:error];

        NSDictionary* storageQuery = @{(__bridge id)kSecAttrAccount:    aKey,
									   (__bridge id)kSecValueData:      serializedDictionary,
									   (__bridge id)kSecClass:          (__bridge id)kSecClassGenericPassword,
									   (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleWhenUnlocked};
        OSStatus osStatus = SecItemAdd((__bridge CFDictionaryRef)storageQuery, nil);
        if(osStatus == noErr)
		{
			stored = YES;
		}
		else
		{
			if (error)
			{
				*error = [NSError errorWithDomain:NSOSStatusErrorDomain
											 code:osStatus
										 userInfo:nil];
			}
        }
    }

	return stored;
}

+ (NSDictionary*)ask_dictionaryFromSerializedData:(NSData*)serializedDictionary error:(NSError*__autoreleasing*)error
{
	return [NSPropertyListSerialization propertyListWithData:serializedDictionary
													 options:0
													  format:NULL
													   error:error];
}

+ (NSDictionary*)ask_dictionaryFromKeychainWithKey:(NSString*)aKey error:(NSError*__autoreleasing*)error
{
    NSDictionary* readQuery = @{(__bridge id)kSecAttrAccount: aKey,
								(__bridge id)kSecReturnData: (__bridge id)kCFBooleanTrue,
								(__bridge id)kSecClass:      (__bridge id)kSecClassGenericPassword};

    NSData* serializedDictionary = nil;
    OSStatus osStatus = SecItemCopyMatching((__bridge CFDictionaryRef)readQuery,
											(void*)&serializedDictionary);

	NSDictionary* storedDictionary = nil;
    if(osStatus == noErr)
	{
		storedDictionary = [self ask_dictionaryFromSerializedData:serializedDictionary
															error:error];
    }
    else
	{
		if (error)
		{
			*error = [NSError errorWithDomain:NSOSStatusErrorDomain
										 code:osStatus
									 userInfo:nil];
		}
    }

	return storedDictionary;
}


- (BOOL)ask_deleteFromKeychainWithKey:(NSString*)aKey error:(NSError*__autoreleasing*)error
{
	BOOL anyFailed = NO;
	BOOL anySucceeded = NO;

    NSDictionary* deletableItemsQuery = @{(__bridge id)kSecAttrAccount:        aKey,
										  (__bridge id)kSecClass:              (__bridge id)kSecClassGenericPassword,
										  (__bridge id)kSecMatchLimit:         (__bridge id)kSecMatchLimitAll,
										  (__bridge id)kSecReturnAttributes:   (__bridge id)kCFBooleanTrue};

    NSArray* items = nil;
    OSStatus osStatus = SecItemCopyMatching((__bridge CFDictionaryRef)deletableItemsQuery, (void*)&items);

    for (NSDictionary* item in items)
	{
        NSMutableDictionary* deleteQuery = [item mutableCopy];
		deleteQuery[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;

        osStatus = SecItemDelete((__bridge CFDictionaryRef)deleteQuery);

		if(osStatus == noErr)
		{
			anySucceeded = YES;
        }
		else
		{
			anyFailed = YES;
			if (error)
			{
				// This will only capture the last error if there are more than one. Ah, well.
				*error = [NSError errorWithDomain:NSOSStatusErrorDomain
											 code:osStatus
										 userInfo:nil];
			}
		}
    }

	return !anyFailed && anySucceeded;
}

@end
