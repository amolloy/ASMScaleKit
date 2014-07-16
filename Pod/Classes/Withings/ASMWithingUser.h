//
//  ASMWithingUser.h
//  Pods
//
//  Created by Andrew Molloy on 7/12/14.
//
//

#import <Foundation/Foundation.h>
#import <ASMScaleKit/ASMScaleUser.h>

@class ASMOAuth1Token;

@interface ASMWithingUser : NSObject <ASMScaleUser>
@property (nonatomic, assign, readonly) NSInteger userid;
@property (nonatomic, strong, readonly) ASMOAuth1Token* accessToken;
@property (nonatomic, copy, readonly) NSString* name;


@end
