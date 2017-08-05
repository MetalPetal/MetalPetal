//
//  MTIFilter+Property.m
//  Pods
//
//  Created by yi chen on 2017/7/26.
//
//

#import "MTIFilter+Property.h"
#import "MTIDefer.h"
#import "MTIVector+Private.h"

@import ObjectiveC;

#if DEBUG

#define mti_debug_print(fmt, ...) \
do { NSLog(fmt, __VA_ARGS__); } while (0)

#else

#define mti_debug_print(fmt, ...) do { } while (0)

#endif

// Used to cache the reflection performed in NSDictionary * parametersDictionaryFor(NSObject *object).
static void *MTIModelCachedPropertyKeysWithTypeDescriptionKey = &MTIModelCachedPropertyKeysWithTypeDescriptionKey;

NSString * const MTIFilterPropertyErrorDomain = @"MTIFilterPropertyErrorDomain";
typedef NS_ENUM(NSInteger, MTIFilterPropertyError) {
    MTIFilterPropertyErrorAttributeStringNotFound = 1000,
    MTIFilterPropertyErrorInvalidAttributeString = 1001,
    MTIFilterPropertyErrorMemory = 1002,
    MTIFilterPropertyErrorInvalidTypeString = 1003,
    MTIFilterPropertyErrorInvalidFlagString = 1004,
    MTIFilterPropertyErrorOldStyleEncoding = 1005,
    MTIFilterPropertyErrorUnparsedLeft = 1006
};

/**
 * Describes the memory management policy of a property.
 */
typedef enum {
    /**
     * The value is assigned.
     */
    MTIPropertyMemoryManagementPolicyAssign = 0,
    
    /**
     * The value is retained.
     */
    MTIPropertyMemoryManagementPolicyRetain,
    
    /**
     * The value is copied.
     */
    MTIPropertyMemoryManagementPolicyCopy
} MTIPropertyMemoryManagementPolicy;

/**
 * Describes the attributes and type information of a property.
 */
typedef struct {
    /**
     * Whether this property was declared with the \c readonly attribute.
     */
    BOOL readonly;
    
    /**
     * Whether this property was declared with the \c nonatomic attribute.
     */
    BOOL nonatomic;
    
    /**
     * Whether the property is a weak reference.
     */
    BOOL weak;
    
    /**
     * Whether the property is eligible for garbage collection.
     */
    BOOL canBeCollected;
    
    /**
     * Whether this property is defined with \c \@dynamic.
     */
    BOOL dynamic;
    
    /**
     * The memory management policy for this property. This will always be
     * #MTIPropertyMemoryManagementPolicyAssign if #readonly is \c YES.
     */
    MTIPropertyMemoryManagementPolicy memoryManagementPolicy;
    
    /**
     * The selector for the getter of this property. This will reflect any
     * custom \c getter= attribute provided in the property declaration, or the
     * inferred getter name otherwise.
     */
    SEL getter;
    
    /**
     * The selector for the setter of this property. This will reflect any
     * custom \c setter= attribute provided in the property declaration, or the
     * inferred setter name otherwise.
     *
     * @note If #readonly is \c YES, this value will represent what the setter
     * \e would be, if the property were writable.
     */
    SEL setter;
    
    /**
     * The backing instance variable for this property, or \c NULL if \c
     * \c @synthesize was not used, and therefore no instance variable exists. This
     * would also be the case if the property is implemented dynamically.
     */
    const char *ivar;
    
    /**
     * If this property is defined as being an instance of a specific class,
     * this will be the class object representing it.
     *
     * This will be \c nil if the property was defined as type \c id, if the
     * property is not of an object type, or if the class could not be found at
     * runtime.
     */
    Class objectClass;
    
    /**
     * The type encoding for the value of this property. This is the type as it
     * would be returned by the \c \@encode() directive.
     */
    char type[];
} MTIPropertyAttributes;

static MTIPropertyAttributes *mtiCopyPropertyAttributes (objc_property_t property, NSError * _Nullable __autoreleasing *inOutError) {
    const char * const attrString = property_getAttributes(property);
    if (!attrString) {
        if (inOutError) {
            NSString *description = [NSString stringWithFormat:@"ERROR: Could not get attribute string from property %s\n", property_getName(property)];
            *inOutError = [NSError errorWithDomain:MTIFilterPropertyErrorDomain code:MTIFilterPropertyErrorAttributeStringNotFound userInfo:@{NSLocalizedDescriptionKey:description}];
        }
        return NULL;
    }
    
    if (attrString[0] != 'T') {
        if (inOutError) {
            NSString *description = [NSString stringWithFormat:@"ERROR: Expected attribute string \"%s\" for property %s to start with 'T'\n", attrString, property_getName(property)];
            *inOutError = [NSError errorWithDomain:MTIFilterPropertyErrorDomain code:MTIFilterPropertyErrorInvalidAttributeString userInfo:@{NSLocalizedDescriptionKey:description}];
        }
        return NULL;
    }
    
    const char *typeString = attrString + 1;
    const char *next = NULL;
    @try {
        next = NSGetSizeAndAlignment(typeString, NULL, NULL);
    } @catch (NSException *exception) {
        if (inOutError) {
            NSString *description = [NSString stringWithFormat:@"WARNING: Invalid type in attribute string \"%s\" for property %s\n", attrString, property_getName(property)];
            *inOutError = [NSError errorWithDomain:MTIFilterPropertyErrorDomain code:MTIFilterPropertyErrorInvalidTypeString userInfo:@{NSLocalizedDescriptionKey:description}];
        }
        next = strchr(typeString, ',');
    } @finally {
        
    }
    
    if (!next) {
        NSString *description = [NSString stringWithFormat:@"WARNING: Could not read past type in attribute string \"%s\" for property %s\n", attrString, property_getName(property)];
        *inOutError = [NSError errorWithDomain:MTIFilterPropertyErrorDomain code:MTIFilterPropertyErrorInvalidAttributeString userInfo:@{NSLocalizedDescriptionKey:description}];
        return NULL;
    }
    
    size_t typeLength = next - typeString;
    
    // allocate enough space for the structure and the type string (plus a NUL)
    MTIPropertyAttributes *attributes = calloc(1, sizeof(MTIPropertyAttributes) + typeLength + 1);
    if (!attributes) {
        if (inOutError) {
            NSString *description = [NSString stringWithFormat:@"ERROR: Could not allocate MTIPropertyAttributes structure for attribute string \"%s\" for property %s\n", attrString, property_getName(property)];
            *inOutError = [NSError errorWithDomain:MTIFilterPropertyErrorDomain code:MTIFilterPropertyErrorMemory userInfo:@{NSLocalizedDescriptionKey:description}];
        }
        return NULL;
    }
    
    if (typeLength > 0) {
        // copy the type string
        strncpy(attributes->type, typeString, typeLength);
        attributes->type[typeLength] = '\0';
    }else {
        if (inOutError) {
            NSString *description = [NSString stringWithFormat:@"WARNING: Invalid type in attribute string \"%s\" for property %s\n", attrString, property_getName(property)];
            *inOutError = [NSError errorWithDomain:MTIFilterPropertyErrorDomain code:MTIFilterPropertyErrorInvalidTypeString userInfo:@{NSLocalizedDescriptionKey:description}];
        }
    }
    
    // if this is an object type, and immediately followed by a quoted string...
    if (typeString[0] == *(@encode(id)) && typeString[1] == '"') {
        // we should be able to extract a class name
        const char *className = typeString + 2;
        next = strchr(className, '"');
        
        if (!next) {
            if (inOutError) {
                NSString *description = [NSString stringWithFormat:@"ERROR: Could not read class name in attribute string \"%s\" for property %s\n", attrString, property_getName(property)];
                *inOutError = [NSError errorWithDomain:MTIFilterPropertyErrorDomain code:MTIFilterPropertyErrorInvalidTypeString userInfo:@{NSLocalizedDescriptionKey:description}];
            }
            return NULL;
        }
        
        if (className != next) {
            size_t classNameLength = next - className;
            char trimmedName[classNameLength + 1];
            
            strncpy(trimmedName, className, classNameLength);
            trimmedName[classNameLength] = '\0';
            
            // attempt to look up the class in the runtime
            attributes->objectClass = objc_getClass(trimmedName);
        }
    }
    
    if (*next != '\0') {
        // skip past any junk before the first flag
        next = strchr(next, ',');
    }
    
    while (next && *next == ',') {
        char flag = next[1];
        next += 2;
        
        switch (flag) {
            case '\0':
                break;
                
            case 'R':
                attributes->readonly = YES;
                break;
                
            case 'C':
                attributes->memoryManagementPolicy = MTIPropertyMemoryManagementPolicyCopy;
                break;
                
            case '&':
                attributes->memoryManagementPolicy = MTIPropertyMemoryManagementPolicyRetain;
                break;
                
            case 'N':
                attributes->nonatomic = YES;
                break;
                
            case 'G':
            case 'S':
            {
                const char *nextFlag = strchr(next, ',');
                SEL name = NULL;
                
                if (!nextFlag) {
                    // assume that the rest of the string is the selector
                    const char *selectorString = next;
                    next = "";
                    
                    name = sel_registerName(selectorString);
                } else {
                    size_t selectorLength = nextFlag - next;
                    if (!selectorLength) {
                        if (inOutError) {
                            NSString *description = [NSString stringWithFormat:@"ERROR: Found zero length selector name in attribute string \"%s\" for property %s\n", attrString, property_getName(property)];
                            *inOutError = [NSError errorWithDomain:MTIFilterPropertyErrorDomain code:MTIFilterPropertyErrorInvalidFlagString userInfo:@{NSLocalizedDescriptionKey:description}];
                        }


                        goto errorOut;
                    }
                    
                    char selectorString[selectorLength + 1];
                    
                    strncpy(selectorString, next, selectorLength);
                    selectorString[selectorLength] = '\0';
                    
                    name = sel_registerName(selectorString);
                    next = nextFlag;
                }
                
                if (flag == 'G')
                    attributes->getter = name;
                else
                    attributes->setter = name;
            }
                
                break;
                
            case 'D':
                attributes->dynamic = YES;
                attributes->ivar = NULL;
                break;
                
            case 'V':
                // assume that the rest of the string (if present) is the ivar name
                if (*next == '\0') {
                    // if there's nothing there, let's assume this is dynamic
                    attributes->ivar = NULL;
                } else {
                    attributes->ivar = next;
                    next = "";
                }
                
                break;
                
            case 'W':
                attributes->weak = YES;
                break;
                
            case 'P':
                attributes->canBeCollected = YES;
                break;
                
            case 't':
            {
                if (inOutError) {
                    NSString *description = [NSString stringWithFormat:@"ERROR: Old-style type encoding is unsupported in attribute string \"%s\" for property %s\n", attrString, property_getName(property)];
                    *inOutError = [NSError errorWithDomain:MTIFilterPropertyErrorDomain code:MTIFilterPropertyErrorOldStyleEncoding userInfo:@{NSLocalizedDescriptionKey:description}];
                }

                // skip over this type encoding
                while (*next != ',' && *next != '\0')
                    ++next;
                
            }
                break;
                
            default:
            {
                if (inOutError) {
                    NSString *description = [NSString stringWithFormat:@"ERROR: Unrecognized attribute string flag '%c' in attribute string \"%s\" for property %s\n", flag, attrString, property_getName(property)];
                    *inOutError = [NSError errorWithDomain:MTIFilterPropertyErrorDomain code:MTIFilterPropertyErrorInvalidFlagString userInfo:@{NSLocalizedDescriptionKey:description}];
                }

            }
        }
    }
    
    if (next && *next != '\0') {
        if (inOutError) {
            NSString *description = [NSString stringWithFormat:@"Warning: Unparsed data \"%s\" in attribute string \"%s\" for property %s\n", next, attrString, property_getName(property)];
            *inOutError = [NSError errorWithDomain:MTIFilterPropertyErrorDomain code:MTIFilterPropertyErrorUnparsedLeft userInfo:@{NSLocalizedDescriptionKey:description}];
        }

    }
    
    if (!attributes->getter) {
        // use the property name as the getter by default
        attributes->getter = sel_registerName(property_getName(property));
    }
    
    if (!attributes->setter) {
        const char *propertyName = property_getName(property);
        size_t propertyNameLength = strlen(propertyName);
        
        // we want to transform the name to setProperty: style
        size_t setterLength = propertyNameLength + 4;
        
        char setterName[setterLength + 1];
        strncpy(setterName, "set", 3);
        strncpy(setterName + 3, propertyName, propertyNameLength);
        
        // capitalize property name for the setter
        setterName[3] = (char)toupper(setterName[3]);
        
        setterName[setterLength - 1] = ':';
        setterName[setterLength] = '\0';
        
        attributes->setter = sel_registerName(setterName);
    }
    
    return attributes;
    
errorOut:
    free(attributes);
    return NULL;
}

typedef void(^PropertiesEnumerateBlock)(objc_property_t property, BOOL *stop);
static void enumerateObjectPropertiesUsingBlock(NSObject *object, PropertiesEnumerateBlock block) {
    Class cls = object.class;
    BOOL stop = NO;
    
    while (!stop && (cls != Nil && ![cls isEqual:NSObject.class]) ) {
        unsigned count = 0;
        objc_property_t *properties = class_copyPropertyList(cls, &count);
        
        cls = class_getSuperclass(cls);
        if (properties == NULL) continue;
        
        @MTI_DEFER {
            free(properties);
        };
        
        for (unsigned i = 0; i < count; i++) {
            block(properties[i], &stop);
            if (stop) break;
        }
    }
}

static BOOL storageExistInObjectForPropertyWithKey(Class objectClass, NSString *propertyKey) {
    
    if (objectClass == Nil) return NO;
    
    objc_property_t property = class_getProperty(objectClass, propertyKey.UTF8String);
    
    if (property == NULL) return NO;
    
    NSError *error;
    MTIPropertyAttributes *attributes = mtiCopyPropertyAttributes(property, &error);
    if (attributes == NULL) return YES;
    @MTI_DEFER {
        free(attributes);
    };
    
    BOOL hasGetter = [objectClass instancesRespondToSelector:attributes->getter];
    BOOL hasSetter = [objectClass instancesRespondToSelector:attributes->setter];
    if (!attributes->dynamic && attributes->ivar == NULL && !hasGetter && !hasSetter) {
        return NO;
    } else if (attributes->readonly && attributes->ivar == NULL) {
            // Check superclass in case the subclass redeclares a property that
            // falls through
        if ([objectClass isEqual: NSObject.class]) return NO;
        return storageExistInObjectForPropertyWithKey(class_getSuperclass(objectClass), propertyKey);
    } else {
        return YES;
    }
}

static NSDictionary *propertyKeysWithTypeDescriptionFor(NSObject *object) {
    NSDictionary *cachedKeys = objc_getAssociatedObject(object, MTIModelCachedPropertyKeysWithTypeDescriptionKey);
    if (cachedKeys != nil) return cachedKeys;
    
    NSMutableDictionary *keysWithTypeDescription = [NSMutableDictionary dictionary];
    
    enumerateObjectPropertiesUsingBlock(object, ^(objc_property_t property, BOOL *stop) {
        NSString *propertyKey = @(property_getName(property));
        
        if (property == NULL) return;
        
        if (storageExistInObjectForPropertyWithKey(object.class, propertyKey)) {
            NSError *error;
            MTIPropertyAttributes *attributes = mtiCopyPropertyAttributes(property, &error);
            if (error.code == MTIFilterPropertyErrorInvalidTypeString) {
                mti_debug_print(@"%@override -(id)valueForKey:(NSString *)key; to provide a value for %@. E.g.: MTIColorMatrixFilter.", error.localizedDescription, propertyKey);
            }else {
                if (error) {
                    mti_debug_print(@"%@", error.localizedDescription);   
                }
            }
            if (attributes == NULL) return;
            
            @MTI_DEFER {
                free(attributes);
            };

            NSString *type = [NSString stringWithCString:attributes->type encoding:NSUTF8StringEncoding];
            [keysWithTypeDescription setObject:type forKey:propertyKey];
        }
    });
    
    // It doesn't really matter if we replace another thread's work, since we do
    // it atomically and the result should be the same.
    objc_setAssociatedObject(object, MTIModelCachedPropertyKeysWithTypeDescriptionKey, keysWithTypeDescription, OBJC_ASSOCIATION_COPY);
    
    return keysWithTypeDescription;
}

NSDictionary * MTIGetParametersDictionaryForFilter(id<MTIFilter> filter) {
    NSObject *object = filter;
    NSCAssert([object conformsToProtocol:@protocol(MTIFilter)], @"");
    NSDictionary *keys = propertyKeysWithTypeDescriptionFor(object);
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:keys.count];
    NSMutableSet *otherKeys = [NSMutableSet setWithCapacity:keys.count];
    const NSArray *valueTypesNeedsRepresentedByMTIVector = @[@"{CGPoint=dd}", @"{CGSize=dd}", @"{CGRect={CGPoint=dd}{CGSize=dd}}", @"{CGAffineTransform=dddddd}"];
    [keys enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull propertyKey, NSString * _Nonnull typeDescription, BOOL * _Nonnull stop) {
        if ([valueTypesNeedsRepresentedByMTIVector containsObject:typeDescription]) {
            NSValue *nsValue = [object valueForKey:propertyKey];
            NSUInteger size;
            NSGetSizeAndAlignment(nsValue.objCType, &size, NULL);
            void *valuePtr = malloc(size);
            @MTI_DEFER {
                free(valuePtr);
            };
            [nsValue getValue:valuePtr];
            
            MTIVector *vector = [MTIVector vectorWithDoubleValues:valuePtr count:size/sizeof(double)];
            [result setObject:vector forKey:propertyKey];
        }else {
            [otherKeys addObject:propertyKey];
        }

    }];
    [result addEntriesFromDictionary:[object dictionaryWithValuesForKeys:otherKeys.allObjects]];
    return result;
}
