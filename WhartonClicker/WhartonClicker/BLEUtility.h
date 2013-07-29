//
//  BLEUtility.h
//  
//
//  Created by Ole Andreas Torvmark on 9/22/12.
//  Copyright (c) 2012 Texas Instruments All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define TI_BASE_LONG_UUID @"F0000000-0451-4000-B000-000000000000"

@interface BLEUtility : NSObject

+(void)readCharacteristic:(CBPeripheral *)peripheral sUUID:(NSString *)sUUID cUUID:(NSString *)cUUID;
+(void)setNotificationForCharacteristic:(CBPeripheral *)peripheral sUUID:(NSString *)sUUID cUUID:(NSString *)cUUID enable:(BOOL)enable;
+(void)writeCharacteristic:(CBPeripheral *)peripheral sUUID:(NSString *)sUUID cUUID:(NSString *)cUUID data:(NSData *)data;

+(CBUUID *) expandToTIUUID:(CBUUID *)sourceUUID;

@end