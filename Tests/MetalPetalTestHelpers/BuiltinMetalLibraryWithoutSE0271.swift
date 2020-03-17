//
//  File.swift
//  
//
//  Created by YuAo on 2020/3/17.
//

import Foundation
import MetalPetal
import XCTest

//TODO: remove this when SE0271 is ready
public struct BuiltinMetalLibraryWithoutSE0271 {
    public static func makeBuiltinMetalLibrary(compileOptions: MTLCompileOptions? = nil) throws -> URL {
        var librarySource = ""
        let sourceFileDirectory = URL(fileURLWithPath: String(#file)).deletingLastPathComponent().appendingPathComponent("../../Sources/MetalPetalObjectiveC")
        let headerURL = sourceFileDirectory.appendingPathComponent("include/MTIShaderLib.h")
        librarySource += try String(contentsOf: headerURL)
        let fileManager = FileManager()
        for source in try fileManager.contentsOfDirectory(at: sourceFileDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
            if source.pathExtension == "metal" {
                librarySource += "\n"
                librarySource += try String(contentsOf: source).replacingOccurrences(of: "#include \"MTIShaderLib.h\"", with: "\n")
            }
        }
        return MTILibrarySourceRegistration.shared.registerLibrary(source: librarySource, compileOptions: compileOptions)
    }
}
