//
//  RCMasterViewController.h
//  WhartonLogger
//
//  Created by Robert Carlsen on 7/29/13.
//  Copyright (c) 2013 Robert Carlsen. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreData/CoreData.h>

@interface RCMasterViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
