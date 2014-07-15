//
//  ASMOAuth1Token.h
//  Pods
//
//  Created by Andrew Molloy on 7/14/14.
//
//

#import <Foundation/Foundation.h>

@interface ASMOAuth1Token : NSObject
@property (nonatomic, copy, readonly) NSString* key;
@property (nonatomic, copy, readonly) NSString* secret;
@property (nonatomic, copy, readonly) NSString* session;
@property (nonatomic, strong, readonly) NSDate* expiration;
@property (nonatomic, assign, readonly) BOOL renewable;
@property (nonatomic, strong, readonly) NSDictionary* userInfo;
@property (nonatomic, copy) NSString* verifier;

- (id)initWithResponseString:(NSString*)responseString;

- (id)initWithKey:(NSString*)key
           secret:(NSString*)secret
          session:(NSString*)session
       expiration:(NSDate*)expiration
        renewable:(BOOL)canBeRenewed;

- (BOOL)isExpired;
@end
