//
//  ASMWithingsServiceProvider.h
//  Pods
//
//  Created by Andrew Molloy on 7/12/14.
//
//

#import <Foundation/Foundation.h>
#import <ASMScaleServiceProvider.h>

@interface ASMWithingsServiceProvider : NSObject <ASMScaleServiceProvider>

extern const NSInteger ASMWithingsServiceProviderNoUserID;

- (instancetype)initWithOAuthKey:(NSString*)key secret:(NSString*)secret;

@end
