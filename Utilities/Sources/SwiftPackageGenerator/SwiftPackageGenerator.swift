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
    
    private let objectiveCModuleMapContents = """
    module MetalPetalObjectiveC {
        explicit module Core {
            header "MetalPetal.h"
            export *
        }
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
            SourceFileHandler(fileTypes: ["swift"], projectRoot: projectRoot, targetURL: swiftTargetDirectory, fileManager: fileManager),
            SourceFileHandler(fileTypes: ["MTIShaderLib.h"], projectRoot: projectRoot, targetURL: objectiveCTargetDirectory, fileManager: fileManager)
        ]
        
        try processSources(in: sourcesDirectory, fileHandlers: fileHandlers)
        
        //TODO: remove this in swift 5.3
        try generateBuiltinMetalLibrarySupportCode(directory: objectiveCTargetDirectory)
        
        try objectiveCModuleMapContents.write(to: objectiveCHeaderDirectory.appendingPathComponent("module.modulemap"), atomically: true, encoding: .utf8)
    }
    
    public func generateBuiltinMetalLibrarySupportCode(directory: URL) throws {
        try """
        // Auto generated.
        #import <Foundation/Foundation.h>

        FOUNDATION_EXPORT NSURL * _MTISwiftPMBuiltinLibrarySourceURL(void);
        
        """.write(to: directory.appendingPathComponent("MTISwiftPMBuiltinLibrarySupport.h"), atomically: true, encoding: .utf8)
        
        try """
        #import "MTISwiftPMBuiltinLibrarySupport.h"
        #import "MTILibrarySource.h"
        #import <Metal/Metal.h>

        static const char *MTIBuiltinLibrarySource = R"mtirawstring(
        \(try collectBuiltinMetalLibrarySource())
        )mtirawstring";

        NSURL * _MTISwiftPMBuiltinLibrarySourceURL(void) {
            static NSURL *url;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                NSString *targetConditionals = [NSString stringWithFormat:@"#ifndef TARGET_OS_SIMULATOR\\n#define TARGET_OS_SIMULATOR %@\\n#endif",@(TARGET_OS_SIMULATOR)];
                NSString *librarySource = [targetConditionals stringByAppendingString:[NSString stringWithCString:MTIBuiltinLibrarySource encoding:NSUTF8StringEncoding]];
                MTLCompileOptions *options = [[MTLCompileOptions alloc] init];
                options.fastMathEnabled = YES;
                options.languageVersion = MTLLanguageVersion1_2;
                url = [MTILibrarySourceRegistration.sharedRegistration registerLibraryWithSource:librarySource compileOptions:options];
            });
            return url;
        }
        """.write(to: directory.appendingPathComponent("MTISwiftPMBuiltinLibrarySupport.mm"), atomically: true, encoding: .utf8)
    }
    
    public func collectBuiltinMetalLibrarySource() throws -> String {
        var librarySource = ""
        let sourceFileDirectory = URL(fileURLWithPath: String(#file)).deletingLastPathComponent().appendingPathComponent("../../../Sources/MetalPetalObjectiveC")
        let headerURL = sourceFileDirectory.appendingPathComponent("include/MTIShaderLib.h")
        librarySource += try String(contentsOf: headerURL)
        let fileManager = FileManager()
        for source in try fileManager.contentsOfDirectory(at: sourceFileDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]).sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            if source.pathExtension == "metal" {
                librarySource += "\n"
                librarySource += try String(contentsOf: source)
                    .replacingOccurrences(of: "#include \"MTIShaderLib.h\"", with: "\n")
                    .replacingOccurrences(of: "#include <TargetConditionals.h>", with: "\n")
            }
        }
        return librarySource
    }
    
    private func processSources(in directory: URL, fileHandlers: [SourceFileHandler]) throws {
        let sourceFiles = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        for sourceFile in sourceFiles {
            if try sourceFile.resourceValues(forKeys: Set<URLResourceKey>([URLResourceKey.isDirectoryKey])).isDirectory == true {
                try processSources(in: sourceFile, fileHandlers: fileHandlers)
            } else {
                for fileHandler in fileHandlers {
                    try fileHandler.handle(sourceFile)
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
        
        @discardableResult func handle(_ file: URL) throws -> Bool {
            if fileTypes.contains(file.pathExtension) || fileTypes.contains(file.lastPathComponent) {
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
