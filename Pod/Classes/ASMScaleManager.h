//
//  ASMScaleManager.h
//  Pods
//
//  Created by Andrew Molloy on 7/16/14.
//
//

@protocol ASMScaleServiceProvider;

@interface ASMScaleManager : NSObject

+ (ASMScaleManager*)sharedManager;

- (void)registerServiceProvider:(id<ASMScaleServiceProvider>)serviceProvider;
- (NSArray*)serviceProviders;

@end
