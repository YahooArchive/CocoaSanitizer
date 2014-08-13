//
//  BMPAppDelegate.m
//  AssignCheckerDemoiOSApp
//
//  Created by Brian Tunning on 4/17/14.
//  Copyright (c) 2014 Yahoo. All rights reserved.
//

#import "BMPAppDelegate.h"
#import "BMPAssignChecker.h"

@implementation BMPAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [BMPAssignChecker startWithOptions:
        BMPAssignCheckerOptionCheckAssigns |
        BMPAssignCheckerOptionOutputToConsole |
        BMPAssignCheckerOptionOutputToFile
     ];
    
    return YES;
}

@end
