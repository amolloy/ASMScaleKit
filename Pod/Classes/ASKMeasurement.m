//
//  ASKMeasurement.m
//  Pods
//
//  Created by Andrew Molloy on 7/17/14.
//
//

#import "ASKMeasurement.h"

@interface ASKMeasurement ()
@property (nonatomic, strong, readwrite) NSDate* date;
@property (nonatomic, strong, readwrite) NSDecimalNumber* weightInKg;
@property (nonatomic, strong, readwrite) NSString* uniqueId;
#if ASKHealthKitAvailable
@property (nonatomic, strong, readwrite) HKQuantity* weight;
#endif
@end

@implementation ASKMeasurement

- (instancetype)initWithDate:(NSDate*)date
				  weightInKg:(NSDecimalNumber*)weightInKg
					uniqueId:(NSString*)uniqueId
{
	self = [super init];
	if (self)
	{
		self.date = date;
		self.weightInKg = weightInKg;
		self.uniqueId = uniqueId;

#if ASKHealthKitAvailable
		if (NSClassFromString(@"HKQuantity"))
		{
			self.weight = [HKQuantity quantityWithUnit:[HKUnit gramUnitWithMetricPrefix:HKMetricPrefixKilo]
										   doubleValue:[self.weightInKg doubleValue]];
		}
#endif
	}
	return self;
}
@end
