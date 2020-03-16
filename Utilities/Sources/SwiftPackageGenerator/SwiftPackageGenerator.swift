import Foundation
import ArgumentParser
import URLExpressibleByArgument
import MetalPetalSourceLocator

public struct SwiftPackageGenerator: ParsableCommand {
    
    @Argument(help: "The root directory of the MetalPetal repo.")
    var projectRoot: URL
    
    enum CodingKeys: CodingKey {
        case projectRoot
    }
    
    private let fileManager = FileManager()
    
    private let packageFileContents = """
    // swift-tools-version:5.1
    
    // requires SE-0271

    import PackageDescription

    let package = Package(
        name: "MetalPetal",
        platforms: [.macOS(.v10_13), .iOS(.v10)],
        products: [
            .library(
                name: "MetalPetal",
                targets: ["MetalPetal"]
            )
        ],
        dependencies: [],
        targets: [
            .target(
                name: "MetalPetal",
                dependencies: ["MetalPetalObjectiveC"]),
            .target(
                name: "MetalPetalObjectiveC",
                dependencies: []),
        ],
        cxxLanguageStandard: .cxx14
    )
    """
    
    private let objectiveCModuleMapContents = """
    module MetalPetalObjectiveC {
        header "MetalPetal.h"
        export *

        explicit module Extension {
            header "MTIContext+Internal.h"
            header "MTIImage+Promise.h"
            export *
        }
    }
    """
    
    public init() { }
    
    public func run() throws {
        let sourcesDirectory = MetalPetalSourcesRootURL(in: projectRoot)
        let packageSourcesDirectory = projectRoot.appendingPathComponent("Sources/")
        try? fileManager.removeItem(at: packageSourcesDirectory)
        try fileManager.createDirectory(at: packageSourcesDirectory, withIntermediateDirectories: true, attributes: nil)
        let swiftTargetDirectory = packageSourcesDirectory.appendingPathComponent("MetalPetal/")
        let objectiveCTargetDirectory = packageSourcesDirectory.appendingPathComponent("MetalPetalObjectiveC/")
        let objectiveCHeaderDirectory = packageSourcesDirectory.appendingPathComponent("MetalPetalObjectiveC/include/")
        try fileManager.createDirectory(at: swiftTargetDirectory, withIntermediateDirectories: true, attributes: nil)
        try fileManager.createDirectory(at: objectiveCTargetDirectory, withIntermediateDirectories: true, attributes: nil)
        try fileManager.createDirectory(at: objectiveCHeaderDirectory, withIntermediateDirectories: true, attributes: nil)
        
        let fileHandlers = [
            SourceFileHandler(fileTypes: ["h"], projectRoot: projectRoot, targetURL: objectiveCHeaderDirectory, fileManager: fileManager),
            SourceFileHandler(fileTypes: ["m", "mm", "metal"], projectRoot: projectRoot, targetURL: objectiveCTargetDirectory, fileManager: fileManager),
            SourceFileHandler(fileTypes: ["swift"], projectRoot: projectRoot, targetURL: swiftTargetDirectory, fileManager: fileManager)
        ]
        
        try processSources(in: sourcesDirectory, fileHandlers: fileHandlers)
        
        try objectiveCModuleMapContents.write(to: objectiveCHeaderDirectory.appendingPathComponent("module.modulemap"), atomically: true, encoding: .utf8)
        
        let packageFileURL = projectRoot.appendingPathComponent("Package.swift")
        try? fileManager.removeItem(at: packageFileURL)
        try packageFileContents.write(to: packageFileURL, atomically: true, encoding: .utf8)
    }
    
    private func processSources(in directory: URL, fileHandlers: [SourceFileHandler]) throws {
        let sourceFiles = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        for sourceFile in sourceFiles {
            if try sourceFile.resourceValues(forKeys: Set<URLResourceKey>([URLResourceKey.isDirectoryKey])).isDirectory == true {
                try processSources(in: sourceFile, fileHandlers: fileHandlers)
            } else {
                for fileHandler in fileHandlers {
                    if try fileHandler.handle(sourceFile) {
                        break
                    }
                }
            }
        }
    }
    
    struct SourceFileHandler {
        let fileTypes: [String]
        let projectRoot: URL
        let targetURL: URL
        let fileManager: FileManager
        
        enum Error: String, Swift.Error, LocalizedError {
            case cannotCreateRelativePath
            var errorDescription: String? {
                return self.rawValue
            }
        }
        
        func handle(_ file: URL) throws -> Bool {
            if fileTypes.contains(file.pathExtension) {
                let fileRelativeToProjectRoot = try relativePathComponents(for: file, baseURL: projectRoot)
                let targetRelativeToProjectRoot = try relativePathComponents(for: targetURL, baseURL: projectRoot)
                let destinationURL = URL(string: (Array<String>(repeating: "..", count: targetRelativeToProjectRoot.count) + fileRelativeToProjectRoot).joined(separator: "/"))!
                try fileManager.createSymbolicLink(at: targetURL.appendingPathComponent(file.lastPathComponent), withDestinationURL: destinationURL)
                return true
            } else {
                return false
            }
        }
        
        private func relativePathComponents(for url: URL, baseURL: URL) throws -> [String] {
            let filePathComponents = url.standardized.pathComponents
            let basePathComponents = baseURL.standardized.pathComponents
            let r: [String] = filePathComponents.dropLast(filePathComponents.count - basePathComponents.count)
            if r == basePathComponents {
                return [String](filePathComponents.dropFirst(basePathComponents.count))
            } else {
                throw Error.cannotCreateRelativePath
            }
        }
    }
}
