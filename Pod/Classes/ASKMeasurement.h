//
//  ASKMeasurement.h
//  Pods
//
//  Created by Andrew Molloy on 7/17/14.
//
//

#import <Foundation/Foundation.h>

#if defined(__IPHONE_8_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
#define ASKHealthKitAvailable 1
#import <HealthKit/HealthKit.h>
#endif

@interface ASKMeasurement : NSObject

@property (nonatomic, strong, readonly) NSDate* date;
@property (nonatomic, strong, readonly) NSDecimalNumber* weightInKg;
@property (nonatomic, strong, readonly) NSString* uniqueId;

#if ASKHealthKitAvailable
@property (nonatomic, strong, readonly) HKQuantity* weight;
#endif

- (instancetype)initWithDate:(NSDate*)date
				  weightInKg:(NSDecimalNumber*)weightInKg
					uniqueId:(NSString*)uniqueId;

@end
