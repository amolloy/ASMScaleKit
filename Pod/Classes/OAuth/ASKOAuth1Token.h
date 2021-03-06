//
//  ASKOAuth1Token.h
//  Pods
//
//  Created by Andrew Molloy on 7/14/14.
//
//

#import <Foundation/Foundation.h>

@interface ASKOAuth1Token : NSObject
@property (nonatomic, copy, readonly) NSString* key;
@property (nonatomic, copy, readonly) NSString* secret;
@property (nonatomic, copy, readonly) NSString* session;
@property (nonatomic, strong, readonly) NSDate* expiration;
@property (nonatomic, assign, readonly) BOOL renewable;
@property (nonatomic, strong) NSDictionary* userInfo;
@property (nonatomic, copy) NSString* verifier;

- (id)initWithResponseString:(NSString*)responseString;

- (id)initWithKey:(NSString*)key
           secret:(NSString*)secret
          session:(NSString*)session
       expiration:(NSDate*)expiration
        renewable:(BOOL)canBeRenewed;

- (BOOL)isExpired;

- (BOOL)storeInKeychainWithName:(NSString*)name error:(NSError*__autoreleasing*)outError;
+ (ASKOAuth1Token*)oauth1TokenFromKeychainItemName:(NSString*)name error:(NSError*__autoreleasing*)outError;

- (NSDictionary*)dictionaryRepresentation;
- (id)initWithDictionaryRepresentation:(NSDictionary*)dict;

@end
