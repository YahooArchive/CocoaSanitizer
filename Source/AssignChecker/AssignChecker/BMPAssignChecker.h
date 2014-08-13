//
//  BMPAssignChecker.h
//  AssignChecker
//
//  Created by Brian Tunning on 4/17/14.
//  Copyright (c) 2014 Yahoo. All rights reserved.

#import <Foundation/Foundation.h>

/**
 *  Specifies startup options.
 */
typedef NS_OPTIONS(NSUInteger, BMPAssignCheckerOptions) {
    /**
     *  Generates errors whenever an id-assign style property has been set, and not cleaned up,
     *  leaving a deallocated object visible.
     */
    BMPAssignCheckerOptionCheckAssigns = 1 << 0,
    /**
     *  Generates a warning whenever a property access is detected across multiple threads.
     */
    BMPAssignCheckerOptionCheckMultithreadedPropertyAccess = 1 << 1,
    /**
     *  Set to enable file output of messages.
     */
    BMPAssignCheckerOptionOutputToFile = 1 << 2,
    /**
     *  Set to enable console messages.
     */
    BMPAssignCheckerOptionOutputToConsole = 1 << 3
};

static const BMPAssignCheckerOptions kDefaultStartupOptions = BMPAssignCheckerOptionCheckAssigns | BMPAssignCheckerOptionOutputToConsole | BMPAssignCheckerOptionOutputToFile;

@interface BMPAssignChecker : NSObject

/**
 *  Starts with a default set of options (kDefaultStartupOptions)
 */
+ (void)start;

/**
 *  Starts the sanitizer with specified options.
 *
 *  @param options a bit mask of options to specify the behavior of the sanitizer.
 */
+ (void)startWithOptions:(BMPAssignCheckerOptions)options;

@end
