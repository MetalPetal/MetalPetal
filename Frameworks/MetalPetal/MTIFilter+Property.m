//
//  MTIFilter+Property.m
//  Pods
//
//  Created by yi chen on 2017/7/26.
//
//

#import "MTIFilter+Property.h"
#import "MTIUtilities.h"
@import ObjectiveC;

// Used to cache the reflection performed in +propertyKeys.
static void *MTIModelCachedPropertyKeysKey = &MTIModelCachedPropertyKeysKey;

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

MTIPropertyAttributes *mtiCopyPropertyAttributes (objc_property_t property) {
    const char * const attrString = property_getAttributes(property);
    if (!attrString) {
        fprintf(stderr, "ERROR: Could not get attribute string from property %s\n", property_getName(property));
        return NULL;
    }
    
    if (attrString[0] != 'T') {
        fprintf(stderr, "ERROR: Expected attribute string \"%s\" for property %s to start with 'T'\n", attrString, property_getName(property));
        return NULL;
    }
    
    const char *typeString = attrString + 1;
    const char *next = NSGetSizeAndAlignment(typeString, NULL, NULL);
    if (!next) {
        fprintf(stderr, "ERROR: Could not read past type in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
        return NULL;
    }
    
    size_t typeLength = next - typeString;
    if (!typeLength) {
        fprintf(stderr, "ERROR: Invalid type in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
        return NULL;
    }
    
    // allocate enough space for the structure and the type string (plus a NUL)
    MTIPropertyAttributes *attributes = calloc(1, sizeof(MTIPropertyAttributes) + typeLength + 1);
    if (!attributes) {
        fprintf(stderr, "ERROR: Could not allocate MTIPropertyAttributes structure for attribute string \"%s\" for property %s\n", attrString, property_getName(property));
        return NULL;
    }
    
    // copy the type string
    strncpy(attributes->type, typeString, typeLength);
    attributes->type[typeLength] = '\0';
    
    // if this is an object type, and immediately followed by a quoted string...
    if (typeString[0] == *(@encode(id)) && typeString[1] == '"') {
        // we should be able to extract a class name
        const char *className = typeString + 2;
        next = strchr(className, '"');
        
        if (!next) {
            fprintf(stderr, "ERROR: Could not read class name in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
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
                        fprintf(stderr, "ERROR: Found zero length selector name in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
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
                fprintf(stderr, "ERROR: Old-style type encoding is unsupported in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
                
                // skip over this type encoding
                while (*next != ',' && *next != '\0')
                    ++next;
                
                break;
                
            default:
                fprintf(stderr, "ERROR: Unrecognized attribute string flag '%c' in attribute string \"%s\" for property %s\n", flag, attrString, property_getName(property));
        }
    }
    
    if (next && *next != '\0') {
        fprintf(stderr, "Warning: Unparsed data \"%s\" in attribute string \"%s\" for property %s\n", next, attrString, property_getName(property));
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


@implementation MTIFilter (Property)

+ (NSSet *)propertyKeys {
    NSSet *cachedKeys = objc_getAssociatedObject(self, MTIModelCachedPropertyKeysKey);
    if (cachedKeys != nil) return cachedKeys;
    
    NSMutableSet *keys = [NSMutableSet set];
    
    [self enumeratePropertiesUsingBlock:^(objc_property_t property, BOOL *stop) {
        NSString *key = @(property_getName(property));
        
        if ([self storageExistForPropertyWithKey:key]) {
            [keys addObject:key];
        }
    }];
    
    // It doesn't really matter if we replace another thread's work, since we do
    // it atomically and the result should be the same.
    objc_setAssociatedObject(self, MTIModelCachedPropertyKeysKey, keys, OBJC_ASSOCIATION_COPY);
    
    return keys;
}

+ (void)enumeratePropertiesUsingBlock:(void (^)(objc_property_t property, BOOL *stop))block {
    Class cls = self;
    BOOL stop = NO;
    
    while (!stop && ![cls isEqual:MTIFilter.class]) {
        unsigned count = 0;
        objc_property_t *properties = class_copyPropertyList(cls, &count);
        
        cls = cls.superclass;
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

+ (BOOL)storageExistForPropertyWithKey:(NSString *)propertyKey {
    objc_property_t property = class_getProperty(self.class, propertyKey.UTF8String);
    
    if (property == NULL) return NO;
    
    MTIPropertyAttributes *attributes = mtiCopyPropertyAttributes(property);
    @MTI_DEFER {
        free(attributes);
    };
    
    BOOL hasGetter = [self instancesRespondToSelector:attributes->getter];
    BOOL hasSetter = [self instancesRespondToSelector:attributes->setter];
    if (!attributes->dynamic && attributes->ivar == NULL && !hasGetter && !hasSetter) {
        return NO;
    } else if (attributes->readonly && attributes->ivar == NULL) {
        if ([self isEqual:MTIFilter.class]) {
            return NO;
        } else {
            // Check superclass in case the subclass redeclares a property that
            // falls through
            return [self.superclass storageExistForPropertyWithKey:propertyKey];
        }
    } else {
        return YES;
    }
}

@end
