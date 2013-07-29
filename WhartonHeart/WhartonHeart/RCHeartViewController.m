//
//  RCHeartViewController.m
//  WhartonHeart
//
//  Created by Robert Carlsen on 7/28/13.
//  Copyright (c) 2013 Robert Carlsen. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <QuartzCore/QuartzCore.h>
#import <Parse/Parse.h>

#import "RCHeartViewController.h"
#import "RCHeartRateSample.h"

@interface RCHeartViewController ()
<CBCentralManagerDelegate, CBPeripheralDelegate>

@property (weak, nonatomic) IBOutlet UIView *hearrrt;
@property (weak, nonatomic) IBOutlet UILabel *bpmLabel;
- (IBAction)scanButtonTapped:(id)sender;
- (IBAction)stopButtonTapped:(id)sender;

@end

@implementation RCHeartViewController
{
    CBCentralManager *manager;
    CBPeripheral *peripheral;
    
    double _pulse;
    NSTimer *_timer;
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    _hearrrt.layer.cornerRadius = _hearrrt.bounds.size.width/2.0;
}

-(void)viewDidDisappear:(BOOL)animated
{
    // don't stop believin'
    //[self stopScan];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [self stopScan];
    manager = nil;
}

#pragma mark - Methods
-(void)startScan;
{
    // create the manager on the first press:
    if (manager == nil) {
        manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }

    if ([manager state] != CBCentralManagerStatePoweredOn) {
        NSLog(@"Central not powered on, avoiding scan.");
        return;
    }
    
    _bpmLabel.text = @"..<3..";
    [manager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"180D"]]
                                    options:nil];
}

-(void)stopScan;
{
    if ([manager state] == CBCentralManagerStatePoweredOn) {
        [manager stopScan];
    }
    
    if (peripheral) {
        [manager cancelPeripheralConnection:peripheral];
        
        peripheral.delegate = nil;
        peripheral = nil;
    }
    
    _bpmLabel.text = @"BPM";
    
    [_timer invalidate];
    _timer = nil;
}

#pragma mark - Actions
- (IBAction)scanButtonTapped:(id)sender {
    [self startScan];
}

- (IBAction)stopButtonTapped:(id)sender {
    [self stopScan];
}

#pragma mark - Heart Rate
/*
 Update UI with heart rate data received from device
 */
- (void) updateWithHRMData:(NSData *)data
{
    const uint8_t *reportData = [data bytes];
    uint16_t bpm = 0;
    
    if ((reportData[0] & 0x01) == 0)
    {
        /* uint8 bpm */
        bpm = reportData[1];
    }
    else
    {
        /* uint16 bpm */
        bpm = CFSwapInt16LittleToHost(*(uint16_t *)(&reportData[1]));
    }
    NSLog(@"%d BPM", bpm);
    
    // update the label
    _bpmLabel.text = [NSString stringWithFormat:@"%d", bpm];
    
    // update our pulse rate:
    _pulse = bpm;
    
    if (!_timer) {
        [self beat];
    }
    
    // store the data in the parse model
    RCHeartRateSample *sample = [RCHeartRateSample object];
    sample.ACL = [PFACL ACLWithUser:[PFUser currentUser]];

    sample.pulse = _pulse;
    sample.date  = [NSDate date];
    [sample saveEventually];
    
}

-(void)beat;
{
    NSTimeInterval pulseDuration = (60. / _pulse);
    CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    a.duration = pulseDuration * 0.3;
    a.repeatCount = 1;
    a.autoreverses = YES;
    
    a.fromValue = @1;
    a.toValue = @1.2;
    
    a.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    [_hearrrt.layer addAnimation:a forKey:@"scale"];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:pulseDuration
                                              target:self
                                            selector:@selector(beat)
                                            userInfo:nil
                                             repeats:NO];
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central;
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSString *state = nil;
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
            state = @"Bluetooth is currently powered on.";
            [self startScan];
            break;
        case CBCentralManagerStateUnknown:
        default:
            state = @"Central manager state unknown.";
            break;
    }
    
    NSLog(@"Central manager state: %@", state);
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)aPeripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI;
{
    // connect to this device, if it's a HR monitor
    NSLog(@"Found peripheral: %@", advertisementData[CBAdvertisementDataLocalNameKey]);
    peripheral = aPeripheral;
    peripheral.delegate = self;
    [manager connectPeripheral:peripheral options:nil];
    
    [manager stopScan];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)aPeripheral
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error;
{
    [self stopScan];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error;
{
    [self stopScan];
}

#pragma mark - CBPeripheral delegate methods
/*
 Invoked upon completion of a -[discoverServices:] request.
 Discover available characteristics on interested services
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    for (CBService *aService in aPeripheral.services)
    {
        NSLog(@"Service found with UUID: %@", aService.UUID);
        
        /* Heart Rate Service */
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:@"180D"]])
        {
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
        
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
    }
}

/*
 Invoked upon completion of a -[discoverCharacteristics:forService:] request.
 Perform appropriate operations on interested characteristics
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"180D"]])
    {
        for (CBCharacteristic *aChar in service.characteristics)
        {
            /* Set notification on heart rate measurement */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"2A37"]])
            {
                [peripheral setNotifyValue:YES forCharacteristic:aChar];
                NSLog(@"Found a Heart Rate Measurement Characteristic");
            }
            /* Read body sensor location */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"2A38"]])
            {
                [aPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Found a Body Sensor Location Characteristic");
            }
            
            /* Write heart rate control point */
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"2A39"]])
            {
                uint8_t val = 1;
                NSData* valData = [NSData dataWithBytes:(void*)&val length:sizeof(val)];
                [aPeripheral writeValue:valData forCharacteristic:aChar type:CBCharacteristicWriteWithResponse];
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
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    
    /* Updated value for heart rate measurement received */
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A37"]])
    {
        if( (characteristic.value)  || !error )
        {
            /* Update UI with heart rate data */
            [self updateWithHRMData:characteristic.value];
        }
    }
    /* Value for body sensor location received */
    else  if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A38"]])
    {
        NSData * updatedValue = characteristic.value;
        uint8_t* dataPointer = (uint8_t*)[updatedValue bytes];
        if(dataPointer)
        {
            uint8_t location = dataPointer[0];
            NSString*  locationString;
            switch (location)
            {
                case 0:
                    locationString = @"Other";
                    break;
                case 1:
                    locationString = @"Chest";
                    break;
                case 2:
                    locationString = @"Wrist";
                    break;
                case 3:
                    locationString = @"Finger";
                    break;
                case 4:
                    locationString = @"Hand";
                    break;
                case 5:
                    locationString = @"Ear Lobe";
                    break;
                case 6:
                    locationString = @"Foot";
                    break;
                default:
                    locationString = @"Reserved";
                    break;
            }
            NSLog(@"Body Sensor Location = %@ (%d)", locationString, location);
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
        NSString *manufacturer = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"Manufacturer Name = %@", manufacturer);
    }
}


#pragma mark - Segue
-(IBAction)exitToMainView:(UIStoryboardSegue*)segue;
{
    // NOP
}

@end

