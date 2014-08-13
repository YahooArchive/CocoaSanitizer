//
//  BMPPropertyInfo.m
//  AssignChecker
//
//  Created by Brian Tunning on 4/28/14.
//  Copyright (c) 2014 Yahoo. All rights reserved.
//

#import "BMPPropertyInfo.h"

@implementation BMPPropertyInfo

@dynamic isScalar;

- (BOOL)isScalar
{
    return self.class == NULL;
}

@end