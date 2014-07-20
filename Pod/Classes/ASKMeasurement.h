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

/**
 *	Represents a measurement retrieved from a smart scale service provider.
 */
@interface ASKMeasurement : NSObject

/**
 *	The date the measurement was taken, if available.
 */
@property (nonatomic, strong, readonly) NSDate* date;

/**
 *	The weight in kilograms.
 */
@property (nonatomic, strong, readonly) NSDecimalNumber* weightInKg;

/**
 *	If provided by the service provider, a unique identifier for the measurement.
 */
@property (nonatomic, strong, readonly) NSString* uniqueId;

#if ASKHealthKitAvailable
/**
 *	The weight in the form of a Health Kit HKQuantity.
 */
@property (nonatomic, strong, readonly) HKQuantity* weight;
#endif

/**
 *	Initialize a new ASKMeasurement.
 *
 *	@param date       The date the measurement was taken.
 *	@param weightInKg The weight for the measurement in kilograms.
 *	@param uniqueId   A unique id for the measurement, if available, nil otherwise.
 */
- (instancetype)initWithDate:(NSDate*)date
				  weightInKg:(NSDecimalNumber*)weightInKg
					uniqueId:(NSString*)uniqueId;

@end
