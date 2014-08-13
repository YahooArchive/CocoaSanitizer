//
//  BMPPropertyInfo.h
//  AssignChecker
//
//  Created by Brian Tunning on 4/28/14.
//  Copyright (c) 2014 Yahoo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMPPropertyInfo : NSObject

@property (nonatomic, strong, readwrite) NSString *propertyName;
@property (nonatomic, assign, readwrite) BOOL readOnly;
@property (nonatomic, assign, readwrite) BOOL isWeak;
@property (nonatomic, assign, readwrite) BOOL isRetain;
@property (nonatomic, assign, readwrite) BOOL isDynamic;
@property (nonatomic, assign, readwrite) BOOL hasCustomAccessors;
@property (nonatomic, assign, readwrite) Class class;
@property (nonatomic, assign, readwrite) BOOL hasProtocol;
@property (nonatomic, assign, readonly) BOOL isScalar;

@end
