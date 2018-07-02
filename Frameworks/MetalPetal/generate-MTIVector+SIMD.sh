#!/usr/bin/env xcrun swift

import Foundation

struct SIMDType {

    enum ScalarType {
        case `float`
        case `double`
        case `int`
        case `uint`

        static let allCases: [ScalarType] = [.float, .double, .int, .uint]

        var description: String {
            switch self {
            case .int:
                return "int"
            case .float:
                return "float"
            case .double:
                return "double"
            case .uint:
                return "uint"
            }
        }

        var capitalizedDescription: String {
            switch self {
            case .int:
                return "Int"
            case .float:
                return "Float"
            case .double:
                return "Double"
            case .uint:
                return "UInt"
            }
        }
    }

    static let scalarTypes = ScalarType.allCases
    static let cardinal = [2, 3, 4]
    static let prefix = "simd_"

    enum SubType {
        case vector(Int)
        case matrix(Int, Int)
    }

    let scalarType: ScalarType

    let subType: SubType

    var description: String {
        switch self.subType {
        case .vector(let c):
            return "\(SIMDType.prefix)\(self.scalarType.description)\(c)"
        case .matrix(let c, let r):
            return "\(SIMDType.prefix)\(self.scalarType.description)\(c)x\(r)"
        }
    }

    func description(prefix: String) -> String {
        switch self.subType {
        case .vector(let c):
            return "\(prefix)\(self.scalarType.description)\(c)"
        case .matrix(let c, let r):
            return "\(prefix)\(self.scalarType.description)\(c)x\(r)"
        }
    }

    var descriptionForMTISIMDType: String {
        switch self.subType {
        case .vector(let c):
            return "MTISIMDType\(self.scalarType.capitalizedDescription)\(c)"
        case .matrix(let c, let r):
            return "MTISIMDType\(self.scalarType.capitalizedDescription)\(c)x\(r)"
        }
    }

    var getterForMTIVector: String {
        switch self.subType {
        case .vector(let c):
            return "\(self.scalarType.description)\(c)Value"
        case .matrix(let c, let r):
            return "\(self.scalarType.description)\(c)x\(r)Value"
        }
    }

    var initializerForMTIVector: String {
        switch self.subType {
        case .vector(let c):
            return "vectorWith\(self.scalarType.capitalizedDescription)\(c):"
        case .matrix(let c, let r):
            return "vectorWith\(self.scalarType.capitalizedDescription)\(c)x\(r):"
        }

    }

    struct Enumerator: Sequence, IteratorProtocol {
        typealias Element = SIMDType

        private var currentScalarTypeIndex: Int = 0
        private var currentCardinalAIndex: Int = 0
        private var currentCardinalBIndex: Int = 0
        private var currentCardinalIndex: Int = 0

        mutating func next() -> SIMDType? {
            if self.currentCardinalIndex >= 0 {
                let scalarType = SIMDType.scalarTypes[self.currentScalarTypeIndex]
                let currentCardinal = SIMDType.cardinal[self.currentCardinalIndex];

                if self.currentCardinalIndex == SIMDType.cardinal.count - 1 {
                    if self.currentScalarTypeIndex == SIMDType.scalarTypes.count - 1 {
                        self.currentCardinalIndex = -1
                        self.currentScalarTypeIndex = 0
                    } else {
                        self.currentCardinalIndex = 0
                        self.currentScalarTypeIndex += 1
                    }
                } else {
                    self.currentCardinalIndex += 1
                }

                return SIMDType(scalarType: scalarType, subType: .vector(currentCardinal))
            }

            if self.currentScalarTypeIndex >= 0 {
                let scalarType = SIMDType.scalarTypes[self.currentScalarTypeIndex]
                let currentCardinalA = SIMDType.cardinal[self.currentCardinalAIndex];
                let currentCardinalB = SIMDType.cardinal[self.currentCardinalBIndex];

                if self.currentCardinalBIndex == SIMDType.cardinal.count - 1 {
                    if self.currentCardinalAIndex == SIMDType.cardinal.count - 1 {
                        if self.currentScalarTypeIndex == SIMDType.scalarTypes.count - 1 {
                            self.currentScalarTypeIndex = -1
                        } else {
                            self.currentCardinalAIndex = 0
                            self.currentCardinalBIndex = 0
                            self.currentScalarTypeIndex += 1
                        }
                    } else {
                        self.currentCardinalBIndex = 0
                        self.currentCardinalAIndex += 1
                    }
                } else {
                    self.currentCardinalBIndex += 1
                }

                return SIMDType(scalarType: scalarType, subType: .matrix(currentCardinalA, currentCardinalB))
            }

            return nil
        }

    }
}

extension SIMDType: Equatable {
    static func == (lhs: SIMDType, rhs: SIMDType) -> Bool {
        if lhs.scalarType == rhs.scalarType {
            switch lhs.subType {
            case .vector(let c):
                switch rhs.subType {
                case .vector(let c2):
                    return c == c2
                default:
                    return false
                }
            case .matrix(let c, let r):
                switch rhs.subType {
                case .matrix(let c2, let r2):
                    return c == c2 && r == r2
                default:
                    return false
                }
            }
        }
        return false
    }
}

struct MTIVectorSIMDTypeSupportGenerator {

    struct HeaderTemplate {
        private let template =
        """
        //
        //  MTIVector+SIMD.h
        //  MetalPetal
        //
        //  Created by Yu Ao on 2018/6/30.
        //
        //  Auto generated by generate-MTIVector+SIMD.sh

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
            lines.append("+ (instancetype)\(type.initializerForMTIVector)(\(type.description))value NS_SWIFT_NAME(init(value:));")
            lines.append("@property (nonatomic, readonly) \(type.description) \(type.getterForMTIVector);");
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
        //  Auto generated by generate-MTIVector+SIMD.sh

        #import "MTIVector+SIMD.h"

        @implementation MTIVector (SIMD)

        {MTIVectorSIMDSupport}

        @end

        """

        private var lines: [String] = []

        mutating func append(type: SIMDType) {
            let getterIMP =
            """
            \(type.description) value = {0};
            if (self.scalarType == MTIVectorScalarType\(type.scalarType.capitalizedDescription) && self.byteLength == sizeof(\(type.description))) {
            memcpy(&value, self.bytes, sizeof(\(type.description)));
            }
            return value;
            """

            let initializerIMP: String =
            """
            NSParameterAssert(sizeof(value) == sizeof(\(type.description)));
            const \(type.scalarType.description) * valuePtr = (void *)&value;
            return [self vectorWith\(type.scalarType.capitalizedDescription)Values:valuePtr count:sizeof(value)/sizeof(\(type.scalarType.description))];
            """

            lines.append(
                """
                + (instancetype)\(type.initializerForMTIVector)(\(type.description))value {
                \(initializerIMP)
                }

                """)

            lines.append(
                """
                - (\(type.description))\(type.getterForMTIVector) {
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

    static func run() {
        let currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let scriptURL: URL
        if CommandLine.arguments[0].hasPrefix("/") {
            scriptURL = URL(fileURLWithPath: CommandLine.arguments[0])
        } else {
            scriptURL = currentDirectoryURL.appendingPathComponent(CommandLine.arguments[0])
        }
        let directoryURL = scriptURL.deletingLastPathComponent()
        let headerFileURL = directoryURL.appendingPathComponent("MTIVector+SIMD.h")
        let implementationFileURL = directoryURL.appendingPathComponent("MTIVector+SIMD.m")

        var headerTemplate = HeaderTemplate()
        var implementationTemplate = ImplementationTemplate()

        for type in SIMDType.Enumerator() {
            if type.scalarType != .double {
                switch type.subType {
                case .matrix(_, _):
                    if type.scalarType == .int || type.scalarType == .uint {
                        continue
                    }
                default:
                    break
                }
                headerTemplate.append(type: type)
                implementationTemplate.append(type: type)
            }
        }

        try! headerTemplate.makeContent().write(to: headerFileURL, atomically: true, encoding: .utf8)
        try! implementationTemplate.makeContent().write(to: implementationFileURL, atomically: true, encoding: .utf8)

        //print(headerTemplate.makeContent())
        //print(implementationTemplate.makeContent())
        print("Done!")
    }
}

MTIVectorSIMDTypeSupportGenerator.run()
