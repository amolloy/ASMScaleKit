//
//  ASMWithingUser.h
//  Pods
//
//  Created by Andrew Molloy on 7/12/14.
//
//

#import <Foundation/Foundation.h>
#import <ASMScaleKit/ASKUser.h>

@class ASKOAuth1Token;

@interface ASKWithingsUser : NSObject <ASKUser>
@property (nonatomic, copy, readonly) NSString* userId;
@property (nonatomic, strong, readonly) ASKOAuth1Token* accessToken;
@property (nonatomic, copy, readonly) NSString* name;

- (instancetype)initWithUserId:(NSString*)userId
		  permenantAccessToken:(ASKOAuth1Token*)token
						  name:(NSString*)name;

@end
