//
//  RCAppDelegate.m
//  WhartonClicker
//
//  Created by Robert Carlsen on 7/29/13.
//  Copyright (c) 2013 Robert Carlsen. All rights reserved.
//

#import "RCAppDelegate.h"

#import "Sensors.h"
#import "BLEUtility.h"
#import "TISensorTag.h"

@implementation RCAppDelegate

-(void) configureSensorTag {
    // Configure sensortag, turning on Sensors and setting update period for sensors etc ...
    // NOP
    
}

-(void) deconfigureSensorTag {
    // NOP
}

#pragma mark - Application Delegate methods
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application


    
    self.clickers = [NSMutableArray array];
    
    manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    if( autoConnect )
    {
        [self startScan];
    }
}


- (void) dealloc
{
    [self stopScan];
    [peripheral setDelegate:nil];
}

/*
 Disconnect peripheral when application terminate
 */
- (void) applicationWillTerminate:(NSNotification *)notification
{
    if(peripheral)
    {
        [manager cancelPeripheralConnection:peripheral];
    }
}


#pragma mark - Scan sheet methods

/*
 Open scan sheet to discover heart rate peripherals if it is LE capable hardware
 */
- (IBAction)openScanSheet:(id)sender
{
    if( [self isLECapableHardware] )
    {
        autoConnect = FALSE;
        [_arrayController removeObjects:_clickers];
        [NSApp beginSheet:self.scanSheet modalForWindow:self.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
        [self startScan];
    }
}

/*
 Close scan sheet once device is selected
 */
- (IBAction)closeScanSheet:(id)sender
{
    [NSApp endSheet:self.scanSheet returnCode:NSAlertDefaultReturn];
    [self.scanSheet orderOut:self];
}

/*
 Close scan sheet without choosing any device
 */
- (IBAction)cancelScanSheet:(id)sender
{
    [NSApp endSheet:self.scanSheet returnCode:NSAlertAlternateReturn];
    [self.scanSheet orderOut:self];
}

/*
 This method is called when Scan sheet is closed. Initiate connection to selected heart rate peripheral
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [self stopScan];
    if( returnCode == NSAlertDefaultReturn )
    {
        NSIndexSet *indexes = [self.arrayController selectionIndexes];
        if ([indexes count] != 0)
        {
            NSUInteger anIndex = [indexes firstIndex];
            peripheral = [self.clickers objectAtIndex:anIndex];
            [indicatorButton setHidden:FALSE];
            [progressIndicator setHidden:FALSE];
            [progressIndicator startAnimation:self];
            [connectButton setTitle:@"Cancel"];
            [manager connectPeripheral:peripheral options:nil];
        }
    }
}

#pragma mark - Connect Button

/*
 This method is called when connect button pressed and it takes appropriate actions depending on device connection state
 */
- (IBAction)connectButtonPressed:(id)sender
{
    if(peripheral && ([peripheral isConnected]))
    {
        /* Disconnect if it's already connected */
        [manager cancelPeripheralConnection:peripheral];
    }
    else if (peripheral)
    {
        /* Device is not connected, cancel pendig connection */
        [indicatorButton setHidden:TRUE];
        [progressIndicator setHidden:TRUE];
        [progressIndicator stopAnimation:self];
        [connectButton setTitle:@"Connect"];
        [manager cancelPeripheralConnection:peripheral];
        [self openScanSheet:nil];
    }
    else
    {   /* No outstanding connection, open scan sheet */
        [self openScanSheet:nil];
    }
}


#pragma mark - Methods
- (BOOL) isLECapableHardware
{
    NSString * state = nil;
    
    switch ([manager state])
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
        case CBCentralManagerStateUnknown:
        default:
            return FALSE;
            
    }
    
    NSLog(@"Central manager state: %@", state);
    
    [self cancelScanSheet:nil];
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:state];
    [alert addButtonWithTitle:@"OK"];
    [alert setIcon:[[NSImage alloc] initWithContentsOfFile:@"AppIcon"]];
    [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
    
    return FALSE;
}

- (void) startScan
{
//    [manager scanForPeripheralsWithServices:[NSArray arrayWithObject:[CBUUID UUIDWithString:@"180D"]] options:nil];
    [manager scanForPeripheralsWithServices:nil options:nil]; // all objects
}

/*
 Request CBCentralManager to stop scanning for heart rate peripherals
 */
- (void) stopScan
{
    [manager stopScan];
}

#pragma mark - CBCentralManager delegate methods
/*
 Invoked whenever the central manager's state is updated.
 */
- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    [self isLECapableHardware];
}

/*
 Invoked when the central discovers heart rate peripheral while scanning.
 */
- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)aPeripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSMutableArray *peripherals = [self mutableArrayValueForKey:@"clickers"];
    if( ![self.clickers containsObject:aPeripheral] )
        [peripherals addObject:aPeripheral];
    
    /* Retreive already known devices */
    if(autoConnect)
    {
        [manager retrievePeripherals:[NSArray arrayWithObject:(id)aPeripheral.UUID]];
    }
}

/*
 Invoked when the central manager retrieves the list of known peripherals.
 Automatically connect to first known peripheral
 */
- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    NSLog(@"Retrieved peripheral: %lu - %@", [peripherals count], peripherals);
    
    [self stopScan];
    
    /* If there are any known devices, automatically connect to it.*/
    if([peripherals count] >=1)
    {
        [indicatorButton setHidden:FALSE];
        [progressIndicator setHidden:FALSE];
        [progressIndicator startAnimation:self];
        peripheral = [peripherals objectAtIndex:0];
        [connectButton setTitle:@"Cancel"];
        [manager connectPeripheral:peripheral options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
    }
}

/*
 Invoked whenever a connection is succesfully created with the peripheral.
 Discover available services on the peripheral
 */
- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)aPeripheral
{
    [aPeripheral setDelegate:self];
    [aPeripheral discoverServices:nil];
	
    [connectButton setTitle:@"Disconnect"];
    [indicatorButton setHidden:TRUE];
    [progressIndicator setHidden:TRUE];
    [progressIndicator stopAnimation:self];
}

/*
 Invoked whenever an existing connection with the peripheral is torn down.
 Reset local variables
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error
{
    [connectButton setTitle:@"Connect"];

    if( peripheral )
    {
        [peripheral setDelegate:nil];
        peripheral = nil;
    }
}

/*
 Invoked whenever the central manager fails to create a connection with the peripheral.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error
{
    NSLog(@"Fail to connect to peripheral: %@ with error = %@", aPeripheral, [error localizedDescription]);
    [connectButton setTitle:@"Connect"];
    if( peripheral )
    {
        [peripheral setDelegate:nil];
        peripheral = nil;
    }
}

#pragma mark - CBPeripheral delegate methods
/*
 Invoked upon completion of a -[discoverServices:] request.
 Discover available characteristics on interested services
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error
{
    for (CBService *aService in aPeripheral.services)
    {
        NSLog(@"Service found with UUID: %@", aService.UUID);

        /* Device Information Service */
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:@"180A"]])
        {
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
        
        /* GAP (Generic Access Profile) for Device Name */
        if ( [aService.UUID isEqual:[CBUUID UUIDWithString:CBUUIDGenericAccessProfileString]] )
        {
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
        
        // SimpleKeys service
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:@"FFE0"]]) {
            NSLog(@"Found a Simple Keys service");
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
    }
}

/*
 Invoked upon completion of a -[discoverCharacteristics:forService:] request.
 Perform appropriate operations on interested characteristics
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{

    // simple keys
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"FFE0"]]) {
        // 0xFFE1
        for (CBCharacteristic *aChar in service.characteristics) {
            /* Set notification on key press */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"FFE1"]])
            {
                [peripheral setNotifyValue:YES forCharacteristic:aChar];
                NSLog(@"Found a Key Press Characteristic");
            }
        }
    }
    
    if ( [service.UUID isEqual:[CBUUID UUIDWithString:CBUUIDGenericAccessProfileString]] )
    {
        for (CBCharacteristic *aChar in service.characteristics)
        {
            /* Read device name */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:CBUUIDDeviceNameString]])
            {
                [aPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Found a Device Name Characteristic");
            }
        }
    }
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"180A"]])
    {
        for (CBCharacteristic *aChar in service.characteristics)
        {
            /* Read manufacturer name */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"2A29"]])
            {
                [aPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Found a Device Manufacturer Name Characteristic");
            }
        }
    }
}

/*
 Invoked upon completion of a -[readValueForCharacteristic:] request or on the reception of a notification/indication.
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    /* Updated value for heart rate measurement received */
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FFE1"]])
    {
        if( (characteristic.value)  || !error )
        {
            NSLog(@"got a key press: %@", [characteristic.value description]);
            uint8_t keyPress = 0;
            [characteristic.value getBytes:&keyPress length:1];
            
            // key down is 0x01 | 0x02
            // key up is 0x00
            if (keyPress & 1) {
                NSLog(@"key 1 down");
                _buttonPressLabel.stringValue = @"Key 1";
                
                CGEventRef eventDown;
                eventDown = CGEventCreateKeyboardEvent (NULL, (CGKeyCode)124, true);
                CGEventPost(kCGHIDEventTap, eventDown);
            }
            else {
                NSLog(@"key 1 up");
                
                CGEventRef eventUp;
                eventUp = CGEventCreateKeyboardEvent (NULL, (CGKeyCode)124, false);
                CGEventPost(kCGHIDEventTap, eventUp);
            }
        
            if (keyPress & 2) {
                NSLog(@"key 2 down");
                _buttonPressLabel.stringValue = @"Key 2";
                
                CGEventRef eventDown;
                eventDown = CGEventCreateKeyboardEvent (NULL, (CGKeyCode)123, true);
                CGEventPost(kCGHIDEventTap, eventDown);
            }
            else {
                NSLog(@"key 2 up");
                
                CGEventRef eventUp;
                eventUp = CGEventCreateKeyboardEvent (NULL, (CGKeyCode)123, false);
                CGEventPost(kCGHIDEventTap, eventUp);
            }
        }
    }
    
    
    /* Value for device Name received */
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CBUUIDDeviceNameString]])
    {
        NSString * deviceName = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"Device Name = %@", deviceName);
    }
    /* Value for manufacturer name received */
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A29"]])
    {
        //self.manufacturer = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        //NSLog(@"Manufacturer Name = %@", self.manufacturer);
    }
}



@end
