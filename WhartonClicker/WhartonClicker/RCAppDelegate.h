//
//  RCAppDelegate.h
//  WhartonClicker
//
//  Created by Robert Carlsen on 7/29/13.
//  Copyright (c) 2013 Robert Carlsen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface RCAppDelegate : NSObject
<NSApplicationDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>
{
    CBCentralManager *manager;
    CBPeripheral *peripheral;
    
    IBOutlet NSButton* connectButton;
    BOOL autoConnect;
    
    // Progress Indicator
    IBOutlet NSButton * indicatorButton;
    IBOutlet NSProgressIndicator *progressIndicator;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSWindow *scanSheet;
@property (weak) IBOutlet NSTextField *buttonPressLabel;

@property (assign) IBOutlet NSArrayController *arrayController;
@property (retain) NSMutableArray *clickers;

- (IBAction) openScanSheet:(id) sender;
- (IBAction) closeScanSheet:(id)sender;
- (IBAction) cancelScanSheet:(id)sender;
- (IBAction) connectButtonPressed:(id)sender;

- (void) startScan;
- (void) stopScan;
- (BOOL) isLECapableHardware;

@end
