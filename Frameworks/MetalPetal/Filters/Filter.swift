//
//  MTIFilter.swift
//  Pods
//
//  Created by YuAo on 22/09/2017.
//

import Foundation

public protocol OutputPort {
    associatedtype Object: AnyObject
    associatedtype Value
    var object: Object { get }
    var keyPath: KeyPath<Object, Value> { get }
}

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
    
    static func add(connection: PortConnection) {
        precondition(self.contexts.count > 0, "No avaliable PortConnectionsBuildingContext. You can only use `=>` operator in FilterGraph.makeImage function.")
        self.contexts[self.contexts.count - 1].connections.append(connection)
    }
    
    private var connections: [PortConnection] = []
    
    static func push() {
        contexts.append(PortConnectionsBuildingContext())
    }
    
    static func pop() -> [PortConnection] {
        guard let current = Self.contexts.popLast() else {
            fatalError()
        }
        return current.connections
    }
}

public class FilterGraph {
    
    fileprivate struct Connection<FromPort, ToPort>: PortConnection where FromPort: OutputPort, ToPort: InputPort, FromPort.Value == MTIImage?, ToPort.Value == MTIImage? {
        
        var fromObject: AnyObject {
            return self.from.object
        }
        
        var toObject: AnyObject {
            return self.to.object
        }
        
        let from: FromPort
        let to: ToPort
        
        init(from: FromPort, to: ToPort) {
            self.from = from
            self.to = to
        }
        
        func connect(context: PortConnectionContext) {
            var object = to.object
            if let c = context.portValueCache[ObjectIdentifier(from.object)], let v = c[from.keyPath]  {
                object[keyPath: to.writableKeyPath] = v
            } else {
                let value = from.object[keyPath: from.keyPath]
                if var c = context.portValueCache[ObjectIdentifier(from.object)] {
                    c[from.keyPath] = value
                    context.portValueCache[ObjectIdentifier(from.object)] = c
                } else {
                    if let value = value {
                        context.portValueCache[ObjectIdentifier(from.object)] = [from.keyPath: value]
                    }
                }
                object[keyPath: to.writableKeyPath] = value
            }
            context.portValueCache[ObjectIdentifier(to.object)] = [:]
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
    
    public static func makeImage<T>(input: T, builder: (T, Port<ImageReceiver,MTIImage?,WritableKeyPath<ImageReceiver,MTIImage?>>) -> Void) throws -> MTIImage?  {
        let outputReceiver = ImageReceiver()
        PortConnectionsBuildingContext.push()
        builder(input, Port(outputReceiver, \.image))
        let connections = PortConnectionsBuildingContext.pop()
        
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
    let filter: Filter
    
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

infix operator =>: AdditionPrecedence

@discardableResult
public func =><Output, Input>(lhs: Output, rhs: Input) -> Input where Input: InputPort, Output: OutputPort, Input.Value == Output.Value, Output.Value == MTIImage? {
    let connection = FilterGraph.Connection<Output, Input>(from: lhs, to: rhs)
    PortConnectionsBuildingContext.add(connection: connection)
    return rhs
}

@discardableResult
public func =><Input>(lhs: MTIImage, rhs: Input) -> Input where Input: InputPort, Input.Value == MTIImage? {
    let connection = FilterGraph.Connection(from: lhs.outputPort, to: rhs)
    PortConnectionsBuildingContext.add(connection: connection)
    return rhs
}

@discardableResult
public func =><Input>(lhs: MTIImage, rhs: Input) -> Input where Input: MTIUnaryFilter {
    let connection = FilterGraph.Connection(from: lhs.outputPort, to: rhs.ioPort)
    PortConnectionsBuildingContext.add(connection: connection)
    return rhs
}

@discardableResult
public func =><Output, Input>(lhs: Output, rhs: Input) -> Input where Output: MTIFilter, Input: MTIUnaryFilter {
    let connection = FilterGraph.Connection(from: lhs.outputPort, to: rhs.ioPort)
    PortConnectionsBuildingContext.add(connection: connection)
    return rhs
}

@discardableResult
public func =><Output, Input>(lhs: Output, rhs: Input) -> Input where Output: MTIFilter, Input: InputPort, Input.Value == MTIImage? {
    let connection = FilterGraph.Connection(from: lhs.outputPort, to: rhs)
    PortConnectionsBuildingContext.add(connection: connection)
    return rhs
}

import Combine

extension FilterGraph {
    @available(iOS 13.0, *)
    public static func makePublisher<T>(upstream: T, builder: @escaping (T.Output, Port<ImageReceiver,MTIImage?,WritableKeyPath<ImageReceiver,MTIImage?>>) -> Void) -> AnyPublisher<MTIImage?,Never> where T: Publisher, T.Failure == Never {
        return upstream.map { value -> MTIImage? in
            return try? makeImage(input: value, builder: builder)
        }.eraseToAnyPublisher()
    }
}
