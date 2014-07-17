//
//  ASMWithingsServiceProvider.h
//  Pods
//
//  Created by Andrew Molloy on 7/12/14.
//
//

#import <Foundation/Foundation.h>
#import <ASMScaleServiceProvider.h>

@class ASMOAuth1Client;

@interface ASMWithingsServiceProvider : NSObject <ASMScaleServiceProvider>

extern const NSInteger ASMWithingsServiceProviderNoUserID;
extern NSString* const ASMWithingsBaseURLString;

@property (nonatomic, strong, readonly) ASMOAuth1Client* client;

- (instancetype)initWithOAuthKey:(NSString*)key secret:(NSString*)secret;

@end
