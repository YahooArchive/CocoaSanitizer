//
//  BMPViewController.m
//  AssignCheckerDemoiOSApp
//
//  Created by Brian Tunning on 4/17/14.
//  Copyright (c) 2014 Yahoo. All rights reserved.
//

#import "BMPViewController.h"
#import "BMPSampleTableViewDataSource.h"

@interface BMPViewController ()

@property (nonatomic, strong, readwrite) BMPSampleTableViewDataSource *dataSource;

@end

@implementation BMPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    BMPSampleTableViewDataSource *dataSource = [[BMPSampleTableViewDataSource alloc] init];
    self.dataSource = dataSource;
    
    self.tableView.dataSource = dataSource;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)didTapTestButton:(id)sender
{
    //self.tableView.dataSource = nil;
    self.dataSource = nil;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        id x = [[BMPSampleTableViewDataSource alloc] init];
        NSLog(@"x: %@", x);
    });
}

@end
