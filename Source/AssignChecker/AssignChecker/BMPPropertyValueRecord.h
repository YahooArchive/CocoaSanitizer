//
//  BMPPropertyValueRecord.h
//  AssignChecker
//
//  Created by Brian Tunning on 4/28/14.
//  Copyright (c) 2014 Yahoo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMPPropertyValueRecord : NSObject

@property (nonatomic, strong, readwrite) NSValue *object;
@property (nonatomic, strong, readwrite) NSArray *backtraceOfOriginalSet;

@end
