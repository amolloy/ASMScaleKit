//
//  ASKOAuth1AuthenticationViewController.h
//  Pods
//
//  Created by Andrew Molloy on 7/15/14.
//
//

#import <UIKit/UIKit.h>

@interface ASKOAuth1AuthenticationViewController : UIViewController

typedef void(^ASMOAuth1AuthenticationCompletionHandler)(NSURL* authorizationURL, NSError* error);

- (instancetype)initWithAuthorizationURL:(NSURL*)url
							 sentinelURL:(NSURL*)sentinelURL
							  completion:(ASMOAuth1AuthenticationCompletionHandler)completion;

@end
