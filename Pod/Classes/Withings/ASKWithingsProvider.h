//
//  ASKWithingsProvider.h
//  Pods
//
//  Created by Andrew Molloy on 7/12/14.
//
//

#import <Foundation/Foundation.h>
#import <ASKServiceProvider.h>

@class ASKOAuth1Client;

@interface ASKWithingsProvider : ASKServiceProvider

extern const NSInteger ASMWithingsServiceProviderNoUserID;
extern NSString* const ASMWithingsBaseURLString;

@property (nonatomic, strong, readonly) ASKOAuth1Client* client;

- (instancetype)initWithOAuthKey:(NSString*)key secret:(NSString*)secret;

@end
