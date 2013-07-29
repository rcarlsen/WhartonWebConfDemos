//
//  RCAppDelegate.m
//  WhartonLogger
//
//  Created by Robert Carlsen on 7/29/13.
//  Copyright (c) 2013 Robert Carlsen. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "RCAppDelegate.h"

#import "RCMasterViewController.h"

#import "BLEUtility.h"
#import "Sensors.h"

@interface RCAppDelegate ()
<CBCentralManagerDelegate, CBPeripheralDelegate>
{
    CBCentralManager    *_manager;
    CBPeripheral        *_peripheral;
}
@end


@implementation RCAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    RCMasterViewController *controller = (RCMasterViewController *)navigationController.topViewController;
    controller.managedObjectContext = self.managedObjectContext;
    
    // Create the central manager.
    _manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    
    // [self deconfigureSensorTag];
    
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"WhartonLogger" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"WhartonLogger.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:@{NSMigratePersistentStoresAutomaticallyOption:@YES,
                                                                   NSInferMappingModelAutomaticallyOption:@YES}
                                                           error:&error]) {
        
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


#pragma mark - Sensor Tag
-(void) configureSensorTag {
    // Configure sensortag, turning on Sensors and setting update period for sensors etc ...
    
    //Configure IR Termometer
    
    NSLog(@"Configured TI SensorTag IR Thermometer Service profile");
    NSString *sUUID = @"F000AA00-0451-4000-B000-000000000000";
    NSString *cUUID = @"F000AA02-0451-4000-B000-000000000000";
    uint8_t data = 0x01;
    [BLEUtility writeCharacteristic:_peripheral
                              sUUID:sUUID
                              cUUID:cUUID
                               data:[NSData dataWithBytes:&data length:1]];

    [BLEUtility setNotificationForCharacteristic:_peripheral
                                           sUUID:sUUID
                                           cUUID:@"F000AA01-0451-4000-B000-000000000000"
                                          enable:YES];
    
    
}
-(void) deconfigureSensorTag {
    //Deconfigure IR Termometer
    NSLog(@"Deconfigured TI SensorTag IR Thermometer Service profile");
    NSString *sUUID = @"F000AA00-0451-4000-B000-000000000000";
    NSString *cUUID = @"F000AA02-0451-4000-B000-000000000000";
    uint8_t data = 0x00;
    [BLEUtility writeCharacteristic:_peripheral
                              sUUID:sUUID
                              cUUID:cUUID
                               data:[NSData dataWithBytes:&data length:1]];
    
    cUUID = @"F000AA01-0451-4000-B000-000000000000";
    [BLEUtility setNotificationForCharacteristic:_peripheral
                                           sUUID:sUUID
                                           cUUID:cUUID
                                          enable:NO];
    
}


#pragma mark - Core Data
static NSString *timestampKey = @"RCEventTimestampKey";
static NSString *temperatureKey = @"RCEventTemperatureKey";

- (void)insertNewObject:(NSDictionary*)info;
{
    NSManagedObjectContext *context = self.managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event"
                                              inManagedObjectContext:self.managedObjectContext];
    
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    // If appropriate, configure the new managed object.
    // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
    [newManagedObject setValue:info[timestampKey]
                        forKey:@"timeStamp"];
    
    [newManagedObject setValue:info[temperatureKey]
                        forKey:@"temperature"];
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

#pragma mark - Methods
-(void)startScan;
{
    if([self isLECapableHardware]) {
        // start scanning
        [_manager scanForPeripheralsWithServices:nil //@[[CBUUID UUIDWithString:@"F000AA00-0451-4000-B000-000000000000"]]
                                         options:nil];
    }
}

-(void)stopLogging;
{
    if (_peripheral) {
        [_manager cancelPeripheralConnection:_peripheral];
    }
}

- (BOOL) isLECapableHardware
{
    NSString * state = nil;
    
    switch ([_manager state])
    {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            return TRUE;
            break;
        case CBCentralManagerStateUnknown:
        default:
            state = @"Bluetooth state unknown";
    }
    
    NSLog(@"Central manager state: %@", state);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Bluetooth Error"
                                                    message:state
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    
    return FALSE;
}

#pragma mark - Core Bluetooth
- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    [self startScan];
}


- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)aPeripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"discovered peripheral: %@", [aPeripheral description]);
    
    _peripheral = aPeripheral;
    _peripheral.delegate = self;
    [_manager connectPeripheral:_peripheral options:nil];
    
    [_manager stopScan];

}

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)aPeripheral
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [aPeripheral setDelegate:self];
    [aPeripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if( _peripheral && [_peripheral isEqual:aPeripheral] )
    {
        [_peripheral setDelegate:nil];
        _peripheral = nil;
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error
{
    NSLog(@"Fail to connect to peripheral: %@ with error = %@", aPeripheral, [error localizedDescription]);
    
    if( _peripheral && [_peripheral isEqual:aPeripheral] )
    {
        [_peripheral setDelegate:nil];
        _peripheral = nil;
    }
}


#pragma mark - CBPeripheralDelegate
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@".");
    for (CBService *s in peripheral.services) [peripheral discoverCharacteristics:nil forService:s];
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"..");
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"F000AA00-0451-4000-B000-000000000000"]]) {
        NSLog(@"This is a SensorTag!");

        [self configureSensorTag];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    //Read IR Termometer
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"F000AA01-0451-4000-B000-000000000000"]]) {
        float tAmb = [sensorTMP006 calcTAmb:characteristic.value];
        
        [self insertNewObject:@{timestampKey:[NSDate date],
                                temperatureKey:@(tAmb)}];
    }
    
}


@end
