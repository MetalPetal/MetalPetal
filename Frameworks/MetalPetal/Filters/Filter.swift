//
//  MTIFilter.swift
//  Pods
//
//  Created by YuAo on 22/09/2017.
//

import Foundation

/// Port for read `Value` from `Object`
public protocol OutputPort {
    associatedtype Object: AnyObject
    associatedtype Value
    var object: Object { get }
    var keyPath: KeyPath<Object, Value> { get }
}

/// Port for write `Value` to `Object`
public protocol InputPort {
    associatedtype Object: AnyObject
    associatedtype Value
    var object: Object { get }
    var writableKeyPath: WritableKeyPath<Object, Value> { get }
}

public struct Port<Object, Value, Property> where Property: KeyPath<Object, Value>, Object: AnyObject {
    public let object: Object
    let property: Property
    
    init(_ object: Object, _ property: Property) {
        self.object = object
        self.property = property
    }
}

extension Port: OutputPort {
    public var keyPath: KeyPath<Object, Value> {
        return self.property
    }
}

extension Port: InputPort where Property: WritableKeyPath<Object, Value> {
    public var writableKeyPath: WritableKeyPath<Object, Value> {
        return self.property
    }
}

public struct ProxyPortTarget {
    public let object: AnyObject
    public let keyPath: AnyKeyPath?
    public let writableKeyPath: AnyKeyPath?
    
    public init(object: AnyObject, keyPath: AnyKeyPath? = nil, writableKeyPath: AnyKeyPath? = nil) {
        self.object = object
        self.keyPath = keyPath
        self.writableKeyPath = writableKeyPath
    }
}

public protocol ProxyPort {
    var target: ProxyPortTarget { get }
}

private class PortConnectionContext {
    fileprivate var portValueCache: [ObjectIdentifier: [AnyKeyPath: MTIImage]] = [:]
}

private protocol PortConnection {
    var fromObject: AnyObject { get }
    var toObject: AnyObject { get }
    func connect(context: PortConnectionContext)
}

private struct PortConnectionsBuildingContext {
    static var contexts: [PortConnectionsBuildingContext] = []
    
    private var connections: [PortConnection] = []

    static func add(connection: PortConnection) {
        precondition(contexts.count > 0, "No avaliable PortConnectionsBuildingContext. You can only use `=>` operator in FilterGraph.makeImage function.")
        contexts[contexts.count - 1].connections.append(connection)
    }
        
    static func push() {
        contexts.append(PortConnectionsBuildingContext())
    }
    
    static func pop() -> [PortConnection] {
        guard let current = contexts.popLast() else {
            fatalError()
        }
        return current.connections
    }
}

public class FilterGraph {
    
    fileprivate struct Connection<FromPort, ToPort>: PortConnection where FromPort: OutputPort, ToPort: InputPort, FromPort.Value == MTIImage?, ToPort.Value == MTIImage? {
        
        var fromObject: AnyObject {
            return (self.from as? ProxyPort)?.target.object ?? self.from.object
        }
        
        var toObject: AnyObject {
            return (self.to as? ProxyPort)?.target.object ?? self.to.object
        }
        
        let from: FromPort
        let to: ToPort
        
        init(from: FromPort, to: ToPort) {
            self.from = from
            self.to = to
        }
        
        func connect(context: PortConnectionContext) {
            let fromObjectIdentifier = ObjectIdentifier(self.fromObject)
            let toObjectIdentifier = ObjectIdentifier(self.toObject)
            let fromKeyPath = (self.from as? ProxyPort)?.target.keyPath ?? self.from.keyPath
            var object = to.object
            if let c = context.portValueCache[fromObjectIdentifier], let v = c[fromKeyPath]  {
                object[keyPath: to.writableKeyPath] = v
            } else {
                let value = from.object[keyPath: from.keyPath]
                if var c = context.portValueCache[fromObjectIdentifier] {
                    c[fromKeyPath] = value
                    context.portValueCache[fromObjectIdentifier] = c
                } else {
                    if let value = value {
                        context.portValueCache[fromObjectIdentifier] = [fromKeyPath: value]
                    }
                }
                object[keyPath: to.writableKeyPath] = value
            }
            context.portValueCache[toObjectIdentifier] = [:]
        }
    }
    
    public class ImageReceiver {
        var image: MTIImage?
    }
    
    public enum Error: Swift.Error, LocalizedError {
        case invalidOutputConnection(count: Int)
        
        public var failureReason: String? {
            switch self {
            case .invalidOutputConnection(let count):
                return "One and only one port is allowed to connect to the graph output port. (\(count) currently)"
            }
        }
    }
    
    public static func makeImage(builder: (Port<ImageReceiver,MTIImage?,WritableKeyPath<ImageReceiver,MTIImage?>>) -> Void) throws -> MTIImage? {
        return try makeImage(input: ()) { _, output in
            builder(output)
        }
    }
    
    private static let builderLock = MTILockCreate()
    
    public static func makeImage<T>(input: T, builder: (T, Port<ImageReceiver,MTIImage?,WritableKeyPath<ImageReceiver,MTIImage?>>) -> Void) throws -> MTIImage?  {
        let outputReceiver = ImageReceiver()
        
        builderLock.lock()
        PortConnectionsBuildingContext.push()
        builder(input, Port(outputReceiver, \.image))
        let connections = PortConnectionsBuildingContext.pop()
        builderLock.unlock()
        
        let rootConnections = connections.filter({ $0.toObject === outputReceiver })
        if rootConnections.count != 1 {
            throw Error.invalidOutputConnection(count: rootConnections.count)
        }
        
        let context = PortConnectionContext()
        for connection in connections {
            connection.connect(context: context)
        }
        return outputReceiver.image
    }
}

@dynamicMemberLookup
public struct FilterInputPorts<Filter> where Filter: AnyObject {
    private let filter: Filter
    
    public init(filter: Filter) {
        self.filter = filter
    }
    
    public subscript(dynamicMember keyPath: WritableKeyPath<Filter, MTIImage?>) -> Port<Filter, MTIImage?, WritableKeyPath<Filter, MTIImage?>> {
        return Port(self.filter, keyPath)
    }
}

extension MTIFilter {
    public var outputPort: Port<Self, MTIImage?, KeyPath<Self, MTIImage?>> {
        return Port(self, \.outputImage)
    }
    
    public var inputPorts: FilterInputPorts<Self> {
        return FilterInputPorts(filter: self)
    }
}

public struct UnaryFilterIOPort<Filter>: InputPort, OutputPort where Filter: MTIUnaryFilter {
    
    public let object: Filter
    
    public let keyPath: KeyPath<Filter, MTIImage?> = \.outputImage
    
    public let writableKeyPath: WritableKeyPath<Filter, MTIImage?> = \.inputImage
}

extension MTIUnaryFilter {
    public var ioPort: UnaryFilterIOPort<Self> {
        return UnaryFilterIOPort(object: self)
    }
}

extension MTIImage {
    private var _self: MTIImage? {
        return self
    }
    
    public struct Port: OutputPort {
        public let object: MTIImage
        public let keyPath: KeyPath<MTIImage, MTIImage?>
    }
    
    public var outputPort: Port {
        return Port(object: self, keyPath: \._self)
    }
}

public class PassthroughPort<Value>: InputPort, OutputPort {
    public var object: PassthroughPort {
        return self
    }
    
    private var value: Value
    
    public var writableKeyPath: WritableKeyPath<PassthroughPort, Value> = \.value
    
    public var keyPath: KeyPath<PassthroughPort, Value> = \.value
    
    public init(_ value: Value) {
        self.value = value
    }
}

public typealias ImagePassthroughPort = PassthroughPort<MTIImage?>

extension PassthroughPort where Value == MTIImage? {
    public convenience init() {
        self.init(nil)
    }
}

public struct AnyIOPort<Value>: InputPort, OutputPort, ProxyPort {
    public class ObjectProxy {
        
        var readableValue: Value {
            return self.rReader()
        }
        
        var writableValue: Value {
            get {
                return self.wReader()
            }
            set {
                self.wWriter(newValue)
            }
        }
        
        private var rReader: () -> Value
        private var wReader: () -> Value
        private var wWriter: (Value) -> ()
        
        init<T>(object: T, keyPath: KeyPath<T,Value>, writableKeyPath: WritableKeyPath<T, Value>) where T: AnyObject {
            var object = object
            self.rReader = {
                return object[keyPath: keyPath]
            }
            self.wReader = {
                return object[keyPath: writableKeyPath]
            }
            self.wWriter = { value in
                return object[keyPath: writableKeyPath] = value
            }
        }
    }
    
    public let object: ObjectProxy
    public let keyPath: KeyPath<ObjectProxy, Value> = \ObjectProxy.readableValue
    public let writableKeyPath: WritableKeyPath<ObjectProxy, Value> = \ObjectProxy.writableValue
    
    public let target: ProxyPortTarget
    
    public init<T>(_ port: T) where T: InputPort, T: OutputPort, T.Value == Value {
        self.object = ObjectProxy(object: port.object, keyPath: port.keyPath, writableKeyPath: port.writableKeyPath)
        self.target = ProxyPortTarget(object: port.object, keyPath: port.keyPath, writableKeyPath: port.writableKeyPath)
    }
}

extension AnyIOPort {
    public init<T>(_ filter: T) where T: MTIUnaryFilter, Value == MTIImage? {
        self.init(filter.ioPort)
    }
}

public struct AnyInputPort<Value>: InputPort, ProxyPort {
    public class ObjectProxy {
        var writableValue: Value {
            get {
                return self.wReader()
            }
            set {
                self.wWriter(newValue)
            }
        }
        
        private var wReader: () -> Value
        private var wWriter: (Value) -> ()
        
        init<T>(object: T, writableKeyPath: WritableKeyPath<T, Value>) where T: AnyObject {
            var object = object
            self.wReader = {
                return object[keyPath: writableKeyPath]
            }
            self.wWriter = { value in
                return object[keyPath: writableKeyPath] = value
            }
        }
    }
    
    public let object: ObjectProxy
    public let writableKeyPath: WritableKeyPath<ObjectProxy, Value> = \ObjectProxy.writableValue
    
    public let target: ProxyPortTarget
    
    public init<T>(_ port: T) where T: InputPort, T.Value == Value {
        self.object = ObjectProxy(object: port.object, writableKeyPath: port.writableKeyPath)
        self.target = ProxyPortTarget(object: port.object, keyPath: nil, writableKeyPath: port.writableKeyPath)
    }
}

extension AnyInputPort {
    public init<T>(_ filter: T) where T: MTIUnaryFilter, Value == MTIImage? {
        self.init(filter.ioPort)
    }
}

public struct AnyOutputPort<Value>: OutputPort, ProxyPort {
    public class ObjectProxy {
        var readableValue: Value {
            return self.rReader()
        }
        private var rReader: () -> Value
        init<T>(object: T, keyPath: KeyPath<T,Value>) where T: AnyObject {
            self.rReader = {
                return object[keyPath: keyPath]
            }
        }
    }
    
    public let object: ObjectProxy
    public let keyPath: KeyPath<ObjectProxy, Value> = \ObjectProxy.readableValue
    
    public let target: ProxyPortTarget
    
    public init<T>(_ port: T) where T: OutputPort, T.Value == Value {
        self.object = ObjectProxy(object: port.object, keyPath: port.keyPath)
        self.target = ProxyPortTarget(object: port.object, keyPath: port.keyPath, writableKeyPath: nil)
    }
}

extension AnyOutputPort {
    public init<T>(_ filter: T) where T: MTIFilter, Value == MTIImage? {
        self.init(filter.outputPort)
    }
}

extension AnyOutputPort where Value == MTIImage? {
    public init(_ image: MTIImage) {
        self.init(image.outputPort)
    }
}

infix operator =>: AdditionPrecedence

extension OutputPort where Value == MTIImage? {
    fileprivate func connect<Input>(to port: Input) where Input: InputPort, Input.Value == Self.Value {
        let connection = FilterGraph.Connection<Self, Input>(from: self, to: port)
        PortConnectionsBuildingContext.add(connection: connection)
    }
}

@discardableResult
public func =><Output, Input>(lhs: Output, rhs: Input) -> Input where Input: InputPort, Output: OutputPort, Input.Value == Output.Value, Output.Value == MTIImage? {
    lhs.connect(to: rhs)
    return rhs
}

@discardableResult
public func =><Input>(lhs: MTIImage, rhs: Input) -> Input where Input: InputPort, Input.Value == MTIImage? {
    lhs.outputPort.connect(to: rhs)
    return rhs
}

@discardableResult
public func =><Input>(lhs: MTIImage, rhs: Input) -> Input where Input: MTIUnaryFilter {
    lhs.outputPort.connect(to: rhs.ioPort)
    return rhs
}

@discardableResult
public func =><Output, Input>(lhs: Output, rhs: Input) -> Input where Output: MTIFilter, Input: MTIUnaryFilter {
    lhs.outputPort.connect(to: rhs.ioPort)
    return rhs
}

@discardableResult
public func =><Output, Input>(lhs: Output, rhs: Input) -> Input where Output: OutputPort, Input: MTIUnaryFilter, Output.Value == MTIImage? {
    lhs.connect(to: rhs.ioPort)
    return rhs
}

@discardableResult
public func =><Output, Input>(lhs: Output, rhs: Input) -> Input where Output: MTIFilter, Input: InputPort, Input.Value == MTIImage? {
    lhs.outputPort.connect(to: rhs)
    return rhs
}

import Combine

@available(iOS 13.0, macOS 10.15, *)
extension FilterGraph {
    public static func makePublisher<T>(upstream: T, builder: @escaping (T.Output, Port<ImageReceiver,MTIImage?,WritableKeyPath<ImageReceiver,MTIImage?>>) -> Void) -> AnyPublisher<MTIImage?,Never> where T: Publisher, T.Failure == Never {
        return upstream.map { value -> MTIImage? in
            return try? makeImage(input: value, builder: builder)
        }.eraseToAnyPublisher()
    }
}
