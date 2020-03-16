import Foundation
import SIMDType

extension SIMDType {
    
    var getterForMTIVector: String {
        switch self.dimension {
        case .vector(let c):
            return "\(self.scalarType.description(capitalized: false))\(c)Value"
        case .matrix(let c, let r):
            return "\(self.scalarType.description(capitalized: false))\(c)x\(r)Value"
        }
    }
    
    var initializerForMTIVector: String {
        switch self.dimension {
        case .vector(let c):
            return "vectorWith\(self.scalarType.description(capitalized: true))\(c):"
        case .matrix(let c, let r):
            return "vectorWith\(self.scalarType.description(capitalized: true))\(c)x\(r):"
        }
    }
}

public struct MTIVectorSIMDTypeSupportCodeGenerator {

    struct HeaderTemplate {
        private let template =
        """
        //
        //  MTIVector+SIMD.h
        //  MetalPetal
        //
        //  Created by Yu Ao on 2018/6/30.
        //
        //  Auto generated.

        #import <Foundation/Foundation.h>
        #import <simd/simd.h>
        #import "MTIVector.h"

        NS_ASSUME_NONNULL_BEGIN

        // WARNING: -[MTIVector isEqual:] may not work on MTIVector which contains a simd_type3 or simd_typeNx3 value.

        @interface MTIVector (SIMD)

        {MTIVectorSIMDSupport}

        @end

        NS_ASSUME_NONNULL_END

        """

        private var lines: [String] = []

        mutating func append(type: SIMDType) {
            lines.append("+ (instancetype)\(type.initializerForMTIVector)(\(type.description()))value NS_SWIFT_NAME(init(value:));")
            lines.append("@property (nonatomic, readonly) \(type.description()) \(type.getterForMTIVector);");
        }

        func makeContent() -> String {
            return self.template.replacingOccurrences(of: "{MTIVectorSIMDSupport}", with: self.lines.reduce("", {
                $0.count > 0 ? ($0 + "\n\n" + $1) : $1
            }))
        }
    }

    struct ImplementationTemplate {
        private let template =
        """
        //
        //  MTIVector+SIMD.m
        //  MetalPetal
        //
        //  Created by Yu Ao on 2018/6/30.
        //
        //  Auto generated.

        #import "MTIVector+SIMD.h"

        @implementation MTIVector (SIMD)

        {MTIVectorSIMDSupport}

        @end

        """

        private var lines: [String] = []

        mutating func append(type: SIMDType) {
            let getterIMP =
            """
                \(type.description()) value = {0};
                if (self.scalarType == MTIVectorScalarType\(type.scalarType.description(capitalized: true)) && self.byteLength == sizeof(\(type.description()))) {
                    memcpy(&value, self.bytes, sizeof(\(type.description())));
                } else {
                    NSAssert(NO, @"Cannot get a \(type.description()) value from %@", self);
                }
                return value;
            """

            let initializerIMP: String =
            """
                NSParameterAssert(sizeof(value) == sizeof(\(type.description())));
                const \(type.scalarType.description(capitalized: false)) * valuePtr = (void *)&value;
                return [self vectorWith\(type.scalarType.description(capitalized: true))Values:valuePtr count:sizeof(value)/sizeof(\(type.scalarType.description(capitalized:false)))];
            """

            lines.append(
                """
                + (instancetype)\(type.initializerForMTIVector)(\(type.description()))value {
                \(initializerIMP)
                }

                """)

            lines.append(
                """
                - (\(type.description()))\(type.getterForMTIVector) {
                \(getterIMP)
                }

                """);

        }

        func makeContent() -> String {
            return self.template.replacingOccurrences(of: "{MTIVectorSIMDSupport}", with: self.lines.reduce("", {
                $0.count > 0 ? ($0 + "\n" + $1) : $1
            }))
        }
    }

    public static func generate() -> [String: String] {
        var headerTemplate = HeaderTemplate()
        var implementationTemplate = ImplementationTemplate()

        for type in SIMDType.metalSupportedSIMDTypes {
            headerTemplate.append(type: type)
            implementationTemplate.append(type: type)
        }
        
        return [
            "MTIVector+SIMD.h": headerTemplate.makeContent(),
            "MTIVector+SIMD.m": implementationTemplate.makeContent()
        ]
    }
}

