//
//  ASKProviderManager.h
//  Pods
//
//  Created by Andrew Molloy on 7/16/14.
//
//

@class ASKServiceProvider;
@class ASKUser;

@interface ASKProviderManager : NSObject

+ (ASKProviderManager*)sharedManager;

- (void)registerServiceProvider:(ASKServiceProvider*)serviceProvider;
- (NSArray*)serviceProviders;
- (ASKServiceProvider*)serviceProviderForUser:(ASKUser*)user;

@end
