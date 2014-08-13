//
//  BMPAssignChecker.m
//  AssignChecker
//
//  Created by Brian Tunning on 4/17/14.
//  Copyright (c) 2014 Yahoo. All rights reserved.
//

#import "BMPAssignChecker.h"
#import "BMPPropertyInfo.h"
#import "BMPInstanceWithSetterRecord.h"
#import "BMPPropertyValueRecord.h"
#import <pthread.h>
#import <objc/runtime.h>

typedef NS_ENUM(NSUInteger, BMPSanitizerMessageSeverity) {
    
    BMPSanitizerMessageSeverityInformational,
    BMPSanitizerMessageSeverityWarning,
    BMPSanitizerMessageSeverityError
};


@interface BMPAssignChecker ()

@property (nonatomic, strong, readonly) NSMutableDictionary *propertySlotsByInstance;
@property (nonatomic, assign, readonly) BMPAssignCheckerOptions options;
@property (nonatomic, strong, readonly) NSRecursiveLock *lock;

@end

@implementation BMPAssignChecker

static NSNumber *s_mainThreadId = nil;
static BMPAssignChecker *s_shared = nil;

#define k_BMPAssignSwizzleClassPrefix @"bmp_swz_"

#pragma mark - Support

+ (BOOL)p_isInApplicationImageForClass:(Class)class
{
    NSParameterAssert(class != NULL);
    
    NSBundle *bundle = [NSBundle bundleForClass:class];
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    return bundle == mainBundle;
}

+ (BOOL)p_shouldAttachToClass:(Class)targetClass
{
    NSParameterAssert(targetClass != NULL);
    
    NSString *className = NSStringFromClass(targetClass);
    
    if ([className hasPrefix:@"AX"] ||
        [className hasPrefix:@"IM"] ||
        [className hasPrefix:@"PC"] ||
        [className hasPrefix:@"NSIS"] ||
        [className hasPrefix:@"_"]) {
        
        return NO;
    }
    else {
        
        return YES;
    }
}

// TODO: make generic, this is really specific for the assign checker, and is used to determine
// based on the value type of a property set call.
//
+ (BOOL)p_propertyAppropriateForMonitoring:(objc_property_t)property ofClass:(Class)propertyValueClass
{
    if (![self p_isInApplicationImageForClass:propertyValueClass]) {
        
        return NO;
    }
    else if ([NSStringFromClass(propertyValueClass) hasPrefix:@"NSKVONotifying"]) {
        
        return NO;
    }
    else {
        
        NSString *selfClassNameStr = NSStringFromClass(self);
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"];
        NSArray *nonBmpStackTrace = [[NSThread callStackSymbols] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *evaluatedObject, NSDictionary *bindings) {
            return [evaluatedObject rangeOfString:selfClassNameStr].location == NSNotFound;
        }]];
        
        const BOOL callIsInAppImage = [nonBmpStackTrace.firstObject rangeOfString:appName].location != NSNotFound;
        
        if (callIsInAppImage) {
            return YES;
        }
        else {
            return NO;
        }
    }
}

- (void)p_monitorSetterOfProperty:(objc_property_t)property ofClass:(Class)classWithSetter
{
    NSMutableDictionary *propertySlots = self.propertySlotsByInstance;
    
    // Identify implementation of the setter method
    const char *propertyName = property_getName(property);
    NSString *propertyNameStr = [NSString stringWithUTF8String:propertyName];
    NSString *upperCasedPropertyName = [NSString stringWithFormat:@"%@%@",[[propertyNameStr substringToIndex:1] uppercaseString],[propertyNameStr substringFromIndex:1]];
    SEL accessorSel = NSSelectorFromString([NSString stringWithFormat:@"set%@:", upperCasedPropertyName]);
    Method method = class_getInstanceMethod(classWithSetter, accessorSel);
    NSString *classWithSetterName = [NSMutableString stringWithString:NSStringFromClass(classWithSetter)];
    IMP originalImp = method_getImplementation(method);
    
    // Early return if we can't find a method for this selector
    if (method == NULL) {
        [self p_logMessage:[NSString stringWithFormat:@"can't find method for %s.%@, skipping...",
                            classWithSetterName.UTF8String,
                            propertyNameStr]
              withSeverity:BMPSanitizerMessageSeverityInformational];
        return;
    }
    
    // TODO: not casting the _self as unsafe_unretained causes _self to never get deallocated.
    //
    IMP replacementSetter = imp_implementationWithBlock(^void (id _self, id newValue) {
        
        [self.lock lock];
        
        // Prepare a mapping of properties which are set for this object
        id instanceWithSetterKey = [NSValue valueWithNonretainedObject:_self];
        BMPInstanceWithSetterRecord *instanceWithSetterRecord = [propertySlots objectForKey:instanceWithSetterKey];
        
        void *instanceWithSetterPtr = NULL;
        [instanceWithSetterKey getValue:&instanceWithSetterPtr];
        
        if (instanceWithSetterRecord == nil) {
            
            // Setup new record object
            instanceWithSetterRecord = [[BMPInstanceWithSetterRecord alloc] init];
            instanceWithSetterRecord.valuePackagesByPropertyName = [NSMutableDictionary dictionary];
            
            // Assign
            [propertySlots setObject:instanceWithSetterRecord forKey:instanceWithSetterKey];
        }
        
        // We're setting a value on the property
        if (newValue != nil) {
            
            Class propertyValueClass = object_getClass(newValue);
            const char *propertyValueClassName = class_getName(propertyValueClass);
            
            // Determine if the value type meets our requirements (being set by the application, etc.),
            // and not already swizzled
            if ([[self class] p_propertyAppropriateForMonitoring:property ofClass:propertyValueClass]
                && ![NSStringFromClass(propertyValueClass) hasPrefix:k_BMPAssignSwizzleClassPrefix]) {
                
                // Identify original dealloc implementation
                SEL deallocSel = sel_registerName("dealloc");
                Method deallocMethod = class_getInstanceMethod(propertyValueClass, deallocSel);
                void (*originalDealloc)(__unsafe_unretained id, SEL) = (__typeof__(originalDealloc))method_getImplementation(deallocMethod);
                
                // Specify new dealloc
                id newDealloc = ^(__unsafe_unretained id __self) {
                    
                    __unsafe_unretained id expiredSelf = __self;
                    NSValue *expiredSelfAsValue = [NSValue valueWithNonretainedObject:expiredSelf];
                    
                    originalDealloc(__self, deallocSel);
                    
                    [self.lock lock];
                    
                    // For each object with setter being tracked
                    for (NSValue *instanceKey in propertySlots) {
                        
                        BMPInstanceWithSetterRecord *instanceRecord = [propertySlots objectForKey:instanceKey];
                        
                        // Get the ptr to the instance
                        void *instancePtr = NULL;
                        [instanceKey getValue:&instancePtr];
                        
                        // For each property tracked on that object
                        NSDictionary *valuePackages = instanceRecord.valuePackagesByPropertyName;
                        
                        for (NSString *propName in valuePackages) {
                            
                            BMPPropertyValueRecord *valueRecord = [valuePackages objectForKey:propName];
                            NSValue *objectValue = valueRecord.object;
                            
                            // Determine if the value matches the instance being deallocated
                            // (determine if the object being deallocated is still visible after the dealloc)
                            //
                            if ([objectValue isEqual:expiredSelfAsValue]) {
                                
                                // TODO: find a safer way to pull out the class name of the instance with the setters
                                // (instanceKey object class name below)

                                [self p_logMessage:
                                 [NSString stringWithFormat:
                                  @"Assign error: %p (%@) %s now points to a deallocated object %p (%s)\n via: \n%s \n\n original set: %@\n",
                                  (void *)instancePtr,
                                  instanceRecord.className,
                                  propName.UTF8String,
                                  expiredSelf,
                                  class_getName(propertyValueClass),
                                  [[NSThread callStackSymbols] description].UTF8String,
                                  valueRecord.backtraceOfOriginalSet]
                                      withSeverity:BMPSanitizerMessageSeverityError];
                            }
                        }
                    }
                    
                    [self.lock unlock];
                };
                
                // Generate and assign a new class
                NSString *newClassName = [NSString stringWithFormat:@"%@%p_%s", k_BMPAssignSwizzleClassPrefix, newValue, propertyValueClassName];
                Class newClass = objc_allocateClassPair(propertyValueClass, newClassName.UTF8String, 0);
                if (newClass != Nil) {
                    
                    class_addMethod(newClass, deallocSel, imp_implementationWithBlock(newDealloc), method_getTypeEncoding(deallocMethod));
                    objc_registerClassPair(newClass);
                    object_setClass(newValue, newClass);
                    
                    [self p_logMessage:[NSString stringWithFormat:@"tracking dealloc of type %s on property %s.%s...",
                                        propertyValueClassName,
                                        classWithSetterName.UTF8String,
                                        propertyNameStr.UTF8String]
                          withSeverity:BMPSanitizerMessageSeverityInformational];
                }
                else {
                    
                    [self p_logMessage:[NSString stringWithFormat:@"can't create class: %@", newClassName]
                          withSeverity:BMPSanitizerMessageSeverityInformational];
                }
            }
            
            // Record the set
            
            BMPPropertyValueRecord *valueRecord = [[BMPPropertyValueRecord alloc] init];
            
            valueRecord.object = [NSValue valueWithNonretainedObject:newValue];
            valueRecord.backtraceOfOriginalSet = [NSThread callStackSymbols];
            
            [instanceWithSetterRecord.valuePackagesByPropertyName setObject:valueRecord forKey:propertyNameStr];
        }
        // Value is being cleared
        else {
            
            [instanceWithSetterRecord.valuePackagesByPropertyName removeObjectForKey:propertyNameStr];
        }
        
        instanceWithSetterRecord.className = [NSString stringWithUTF8String:class_getName(object_getClass(_self))];
        
        [self.lock unlock];
        
        return ((void(*)(id, SEL, id))originalImp)(_self, accessorSel, newValue);
    });
    
    method_setImplementation(method, replacementSetter);
    
    [self p_logMessage:[NSString stringWithFormat:@"tracking %s.%s...", classWithSetterName.UTF8String, propertyName] withSeverity:BMPSanitizerMessageSeverityInformational];
}

- (void)p_enumeratePropertyInfoForClass:(Class)targetClass usingBlock:(void (^)(BMPPropertyInfo *info, objc_property_t property, BOOL *stop))block
{
    NSParameterAssert(targetClass != NULL);
    NSParameterAssert(block != NULL);
    
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(targetClass, &outCount);
    
    for (i = 0; i < outCount; i++) {
        
        objc_property_t property = properties[i];
        
        unsigned int numOfAttributes;
        objc_property_attribute_t *propertyAttributes = property_copyAttributeList(property, &numOfAttributes);
        
        BMPPropertyInfo *info = [[BMPPropertyInfo alloc] init];
        info.propertyName = [NSString stringWithUTF8String:property_getName(property)];
        
        // Special case
        
        /**
         *  For some reason, the runtime doesn't report 'parentViewController' as read-only, even though the docs,
         *  and header file claim it to be.
         */
        if ([info.propertyName isEqualToString:@"parentViewController"] && [NSStringFromClass(targetClass) isEqualToString:@"UIViewController"]) {
            info.readOnly = YES;
        }
        
        for (unsigned int ai = 0; ai < numOfAttributes; ai++) {
            
            switch (propertyAttributes[ai].name[0]) {
                    
                case 'T': // type
                    break;
                    
                case 'R': // readonly
                    info.readOnly = YES;
                    break;
                    
                case 'C': // copy
                    info.isRetain = YES;
                    break;
                    
                case '&': // retain
                    info.isRetain = YES;
                    break;
                    
                case 'N': // nonatomic
                    break;
                    
                case 'G': // custom getter
                    info.hasCustomAccessors = YES;
                    break;
                    
                case 'S': // custom setter
                    info.hasCustomAccessors = YES;
                    break;
                    
                case 'D': // dynamic
                    info.isDynamic = YES;
                    break;
                    
                case 'W': // weak
                    info.isWeak = YES;
                    break;
                    
                default:
                    break;
            }
        }
        
        // Determine type of property
        const char *valueType = propertyAttributes[0].value;
        
        if (strlen(valueType) > 0) {
            
            /**
             *  Inputs like:
             *      @"<AVSpeechSynthesizerDelegate>"
             *      @"<NSISEngineDelegate>"
             *      @"NSString"
             *      @"NSArray"
             *      GPoint=ff
             *      ^{__CFRunLoopObserver=}
             */
            NSString *trimmed = [NSString stringWithUTF8String:valueType];
            
            if ([trimmed hasPrefix:@"@"] && trimmed.length > 3) {
                
                NSRange range = NSMakeRange(2, trimmed.length-3);
                trimmed = [trimmed substringWithRange:range];
                
                if ([trimmed hasPrefix:@"<"] && [trimmed hasSuffix:@">"]) {
                    info.hasProtocol = YES;
                }
                
                Class valueClass = NSClassFromString(trimmed);
                if (valueClass) {
                    info.class = valueClass;
                }
            }
        }
        
        // Call block
        BOOL stop = NO;
        block(info, property, &stop);
        
        // Cleanup
        free(propertyAttributes);
        
        // Check
        if (stop) {
            break;
        }
    }
    
    free(properties);
}

- (BOOL)p_attachWithError:(__autoreleasing NSError **)error
{
    NSAssert([NSThread isMainThread], @"init must be done on main thread.");
    NSParameterAssert(error != nil);
    
    const NSInteger classCount = objc_getClassList(NULL, 0);
    Class *classes = (__unsafe_unretained Class *) malloc(sizeof(Class) * classCount);
    
    objc_getClassList(classes, classCount);
    
    __block NSInteger propertyCount = 0;
    
    // For each class
    for (int i=0; i<classCount; i++) {
        
        Class class = classes[i];
        
        if (![[self class] p_shouldAttachToClass:class]) {
            continue;
        }
        
        // Identify properties which are object type, which are writable, of the assign type,
        // and allow those which point to protocols:
        //
        [self p_enumeratePropertyInfoForClass:class usingBlock:^(BMPPropertyInfo *info, objc_property_t property, BOOL *stop) {
            
            if ((!info.isScalar || info.hasProtocol) &&
                !info.isRetain &&
                !info.isWeak &&
                !info.readOnly &&
                ![info.propertyName hasPrefix:@"_"]) {
                
                propertyCount++;
                
                [self p_monitorSetterOfProperty:property ofClass:class];
            }
        }];
    }
    
    [self p_logMessage:[NSString stringWithFormat:@"found %i properties.", propertyCount]
          withSeverity:BMPSanitizerMessageSeverityInformational];
    
    free(classes);
    
    return (*error == nil);
}

- (void)p_logMessage:(NSString *)message withSeverity:(BMPSanitizerMessageSeverity)severity
{
    static NSOutputStream *outputStream = nil;
    static dispatch_once_t onceToken;
    
    // Provision output file
    dispatch_once(&onceToken, ^{
        
        if (self.options & BMPAssignCheckerOptionOutputToFile) {
            
            NSString *fileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], @"thread_accessor_warnings.txt"];
            NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
            
            NSLog(@"AssignChecker outputting to file at path: %@", fileURL);
            
            outputStream = [[NSOutputStream alloc] initWithURL:fileURL append:YES];
            [outputStream open];
        }
    });
    
    // Ouput
    if (self.options & BMPAssignCheckerOptionOutputToConsole) {
        printf("AssignChecker [%i]: %s\n", severity, message.UTF8String);
    }

    if (self.options & BMPAssignCheckerOptionOutputToFile) {
        
        NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
        [outputStream write:data.bytes maxLength:data.length];
        
        NSString *newline = @"\n";
        NSData *newlineData = [newline dataUsingEncoding:NSUTF8StringEncoding];
        [outputStream write:newlineData.bytes maxLength:newlineData.length];
    }
}

- (void)p_start
{
    NSError *error = nil;
    [self p_attachWithError:&error];
    
    if (!error) {
        NSLog(@"AssignChecker ready.");
    }
    else {
        NSLog(@"AssignChecker failed to start: %@", error);
    }
}

#pragma mark - Init / Cleanup

- (id)initWithOptions:(BMPAssignCheckerOptions)options
{
    self = [super init];
    
    if (self != nil) {
        
        s_mainThreadId = @(pthread_mach_thread_np(pthread_self()));
        _options = options;
        _lock = [[NSRecursiveLock alloc] init];
        _propertySlotsByInstance = [NSMutableDictionary dictionary];
        
        [self p_start];
    }
    
    return self;
}

#pragma mark - Public

+ (void)startWithOptions:(BMPAssignCheckerOptions)options
{
    NSAssert([NSThread isMainThread], @"init must be done on main thread.");
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_shared = [[BMPAssignChecker alloc] initWithOptions:options];
    });
}

+ (void)start
{
    [[self class] startWithOptions:kDefaultStartupOptions];
}

@end
