//
//  BMPInstanceWithSetterRecord.h
//  AssignChecker
//
//  Created by Brian Tunning on 4/28/14.
//  Copyright (c) 2014 Yahoo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMPInstanceWithSetterRecord : NSObject

@property (nonatomic, strong, readwrite) NSMutableDictionary *valuePackagesByPropertyName;
@property (nonatomic, strong, readwrite) NSString *className;

@end
