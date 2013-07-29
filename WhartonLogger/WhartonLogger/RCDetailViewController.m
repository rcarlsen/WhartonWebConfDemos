//
//  RCDetailViewController.m
//  WhartonLogger
//
//  Created by Robert Carlsen on 7/29/13.
//  Copyright (c) 2013 Robert Carlsen. All rights reserved.
//

#import "RCDetailViewController.h"
#import "Sensors.h" // just for a helpful conversion utility

@interface RCDetailViewController ()
- (void)configureView;
@end

@implementation RCDetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.detailItem) {
        self.detailDescriptionLabel.text = [[self.detailItem valueForKey:@"timeStamp"] description];
        self.detailTemperatureLabel.text = [NSString stringWithFormat:@"%.1f°F",
                                            fahrenheitValueFromCelcisus([[self.detailItem valueForKey:@"temperature"] floatValue])];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
