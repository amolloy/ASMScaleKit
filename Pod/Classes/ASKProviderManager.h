//
//  ASMScaleManager.h
//  Pods
//
//  Created by Andrew Molloy on 7/16/14.
//
//

@protocol ASKServiceProvider;
@protocol ASKUser;

@interface ASKProviderManager : NSObject

+ (ASKProviderManager*)sharedManager;

- (void)registerServiceProvider:(id<ASKServiceProvider>)serviceProvider;
- (NSArray*)serviceProviders;
- (id<ASKServiceProvider>)serviceProviderForUser:(id<ASKUser>)user;

@end
