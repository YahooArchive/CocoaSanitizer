//
//  BMPViewController.h
//  AssignCheckerDemoiOSApp
//
//  Created by Brian Tunning on 4/17/14.
//  Copyright (c) 2014 Yahoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BMPViewController : UIViewController

@property (nonatomic, weak, readwrite) IBOutlet UITableView *tableView;

- (IBAction)didTapTestButton:(id)sender;

@end
