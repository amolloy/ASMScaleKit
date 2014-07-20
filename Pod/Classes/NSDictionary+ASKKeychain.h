//
//  NSDictionary+ASKKeychain.h
//  Pods
//
//  Created by Andrew Molloy on 7/20/14.
//
//

#import <Foundation/Foundation.h>

@interface NSDictionary (ASKKeychain)

-(BOOL)ask_storeToKeychainWithKey:(NSString*)aKey error:(NSError*__autoreleasing*)error;
+ (NSDictionary*)ask_dictionaryFromKeychainWithKey:(NSString*)aKey error:(NSError*__autoreleasing*)error;
- (BOOL)ask_deleteFromKeychainWithKey:(NSString*)aKey error:(NSError*__autoreleasing*)error;

@end
