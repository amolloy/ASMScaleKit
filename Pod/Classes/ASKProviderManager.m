//
//  ASKProviderManager.m
//  Pods
//
//  Created by Andrew Molloy on 7/16/14.
//
//

#import "ASKProviderManager.h"
#import "ASKServiceProvider.h"
#import "ASKUser.h"

@interface ASKProviderManager ()
@property (nonatomic, strong) NSMutableArray* providers;
@end

@implementation ASKProviderManager

- (void)registerServiceProvider:(id<ASKServiceProvider>)serviceProvider
{
	[self.providers addObject:serviceProvider];
}

- (NSArray*)serviceProviders
{
	return self.providers.copy;
}

- (id<ASKServiceProvider>)serviceProviderForUser:(id<ASKUser>)user
{
	__block id<ASKServiceProvider> provider = nil;
	[self.providers enumerateObjectsUsingBlock:^(id<ASKServiceProvider> obj, NSUInteger idx, BOOL *stop) {
		if ([user isKindOfClass:[obj userClass]])
		{
			provider = obj;
			*stop = YES;
		}
	}];
	return provider;
}

#pragma mark - Singleton

static ASKProviderManager *SINGLETON = nil;

static bool isFirstAccess = YES;

#pragma mark - Public Method

+ (id)sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isFirstAccess = NO;
        SINGLETON = [[super allocWithZone:NULL] init];    
    });
    
    return SINGLETON;
}

#pragma mark - Life Cycle

+ (id) allocWithZone:(NSZone *)zone
{
    return [self sharedManager];
}

+ (id)copyWithZone:(struct _NSZone *)zone
{
    return [self sharedManager];
}

+ (id)mutableCopyWithZone:(struct _NSZone *)zone
{
    return [self sharedManager];
}

- (id)copy
{
    return [[ASKProviderManager alloc] init];
}

- (id)mutableCopy
{
    return [[ASKProviderManager alloc] init];
}

- (id) init
{
    if(SINGLETON){
        return SINGLETON;
    }
    if (isFirstAccess) {
        [self doesNotRecognizeSelector:_cmd];
    }
    self = [super init];
	if (self)
	{
		self.providers = [NSMutableArray array];
	}
    return self;
}


@end
