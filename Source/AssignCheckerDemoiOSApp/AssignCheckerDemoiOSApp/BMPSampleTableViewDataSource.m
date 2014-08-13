//
//  BMPSampleTableViewDataSource.m
//  AssignCheckerDemoiOSApp
//
//  Created by Brian Tunning on 4/18/14.
//  Copyright (c) 2014 Yahoo. All rights reserved.
//

#import "BMPSampleTableViewDataSource.h"

@implementation BMPSampleTableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 100;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.textLabel.text = [indexPath description];
    
    return cell;
}

- (void)dealloc
{
    NSLog(@"bmp sample data source dealloc.");
}

@end
