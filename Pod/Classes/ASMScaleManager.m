//
//  ASMScaleManager.m
//  Pods
//
//  Created by Andrew Molloy on 7/16/14.
//
//

#import "ASMScaleManager.h"
#import "ASMScaleServiceProvider.h"
#import "ASMScaleUser.h"

@interface ASMScaleManager ()
@property (nonatomic, strong) NSMutableArray* providers;
@end

@implementation ASMScaleManager

- (void)registerServiceProvider:(id<ASMScaleServiceProvider>)serviceProvider
{
	[self.providers addObject:serviceProvider];
}

- (NSArray*)serviceProviders
{
	return self.providers.copy;
}

- (id<ASMScaleServiceProvider>)serviceProviderForUser:(id<ASMScaleUser>)user
{
	__block id<ASMScaleServiceProvider> provider = nil;
	[self.providers enumerateObjectsUsingBlock:^(id<ASMScaleServiceProvider> obj, NSUInteger idx, BOOL *stop) {
		if ([user isKindOfClass:[obj userClass]])
		{
			provider = obj;
			*stop = YES;
		}
	}];
	return provider;
}

#pragma mark - Singleton

static ASMScaleManager *SINGLETON = nil;

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
    return [[ASMScaleManager alloc] init];
}

- (id)mutableCopy
{
    return [[ASMScaleManager alloc] init];
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
