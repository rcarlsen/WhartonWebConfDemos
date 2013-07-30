//
//  RCViewController.m
//  WhartonProximity
//
//  Created by Robert Carlsen on 7/29/13.
//  Copyright (c) 2013 Robert Carlsen. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <QuartzCore/QuartzCore.h>

#import "RCViewController.h"

@interface RCViewController ()
<CBCentralManagerDelegate, CBPeripheralDelegate>

@property (weak, nonatomic) IBOutlet UIView *youView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *youSpace;

@end

@implementation RCViewController
{
    CBCentralManager *manager;
    CBPeripheral *peripheral;
    
    NSMutableArray *samples;
    int sampleIndex;
    int sampleSize;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    sampleSize = 10;
    samples = [NSMutableArray arrayWithCapacity:sampleSize];
    sampleIndex = 0;
    
    _youView.hidden = YES;
    _youView.layer.cornerRadius = _youView.bounds.size.width/2.0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Actions
- (IBAction)scanButtonTapped:(id)sender {
    [self startScan];
}

- (IBAction)stopButtonTapped:(id)sender {
    [self stopScan];
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
    
    [manager scanForPeripheralsWithServices:nil
                                    options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @1}]; // want to keep scanning to update RSSI
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

    sampleIndex = 0;
    [samples removeAllObjects];
    
    _youView.hidden = YES;
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
    //NSLog(@"Found peripheral: %@ (%d dB)", advertisementData[CBAdvertisementDataLocalNameKey], [RSSI integerValue]);
    
    /*
    peripheral = aPeripheral;
    peripheral.delegate = self;
    [manager connectPeripheral:peripheral options:nil];
    */
    
    //[manager stopScan];
    
    // I don't want to stop scanning in this case..i just want to update the youSpace constraint
    // mapped value is about -30 to -120 -> 8 to 300 (or so)
    if (RSSI) {
        _youView.hidden = NO;
        
        CGFloat rssiValue = -1.0 * [RSSI floatValue];
        CGFloat mappedValue = (((rssiValue - 30)/(120 - 30) * (400-8)) + 8);
        
        if (sampleIndex >= samples.count) {
            [samples addObject:@(mappedValue)];
        }
        else {
            [samples replaceObjectAtIndex:sampleIndex withObject:@(mappedValue)];
        }
        sampleIndex = (sampleIndex+1)%sampleSize;
        
        // doing some light smoothing.
        CGFloat smoothedValue = [[samples valueForKeyPath:@"@avg.floatValue"] floatValue];
    
        _youSpace.constant = smoothedValue;
        
        [_youView setNeedsUpdateConstraints];
        [UIView animateWithDuration:.3 animations:^{
            [_youView layoutIfNeeded];
        }];
    }
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

#pragma mark - CBPeripheralDelegate methods
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void) peripheral:(CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

@end
