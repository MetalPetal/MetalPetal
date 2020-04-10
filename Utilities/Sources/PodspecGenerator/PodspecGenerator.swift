//
//  File.swift
//  
//
//  Created by YuAo on 2020/3/16.
//

import Foundation
import URLExpressibleByArgument
import ArgumentParser
import RunCommand

public struct PodspecGenerator: ParsableCommand {
    
    @Argument(help: "The root directory of the MetalPetal repo.")
    var projectRoot: URL
    
    enum CodingKeys: CodingKey {
        case projectRoot
    }
    
    private let fileManager = FileManager()
    
    public init() { }
    
    public func run() throws {
        try updatePodspec(with: projectRoot)
    }
    
    private func updatePodspec(with projectRootDirectoryURL: URL) throws {
        let fileManager = FileManager()
        let developmentPodsDirectoryURL = projectRootDirectoryURL.appendingPathComponent("Frameworks")
        let contents = try fileManager.contentsOfDirectory(at: developmentPodsDirectoryURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        let currentVersion = try Command.execute("git describe --abbrev=0 --tags", fromDirectory: projectRootDirectoryURL.path).trimmingCharacters(in: .whitespacesAndNewlines)
        print("Using version: \(currentVersion)")
        for podDirectoryURL in contents {
            let podName = podDirectoryURL.lastPathComponent
            let podSpecFileURL = podDirectoryURL.appendingPathComponent(podName).appendingPathExtension("podspec")
            if fileManager.fileExists(atPath: podSpecFileURL.path) {
                let jsonString = try Command.execute("pod ipc spec \(podSpecFileURL.lastPathComponent)", fromDirectory: podDirectoryURL.path)
                var podJSON = try! JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!, options: []) as! [String:Any]
                
                //version
                podJSON["version"] = currentVersion
                
                //source
                var source = podJSON["source"] as! [String:Any]
                source["tag"] = currentVersion
                podJSON["source"] = source
                
                //files
                let pathPrefix = "Frameworks/\(podName)/"
                let fileFields = ["source_files","public_header_files","private_header_files","vendored_frameworks","vendored_library","resource_bundle","resource_bundles","resource","exclude_files","preserve_path","module_map","resources"]
                
                func updateFields(in json: [String: Any]) -> [String: Any] {
                    var podJSON = json
                    for field in fileFields {
                        if let value = podJSON[field] {
                            switch value {
                            case let text as String:
                                podJSON[field] = pathPrefix.appending(text)
                            case let array as [String]:
                                var newContents = [String]()
                                for text in array {
                                    newContents.append(pathPrefix.appending(text))
                                }
                                podJSON[field] = newContents
                            case let dic as [String: [String]]:
                                var newContents = dic
                                for (key, value) in dic {
                                    var newValues = [String]()
                                    for text in value {
                                        newValues.append(pathPrefix.appending(text))
                                    }
                                    newContents[key] = newValues
                                }
                                podJSON[field] = newContents
                            default:
                                abort()
                            }
                        }
                    }
                    return podJSON
                }
                
                if let subspecs = podJSON["subspecs"] as? [[String: Any]] {
                    var subpods = [[String: Any]]()
                    for subpod in subspecs {
                        subpods.append(updateFields(in: subpod))
                    }
                    podJSON["subspecs"] = subpods
                }
                
                podJSON = updateFields(in: podJSON)
                
                //create JSON file
                let podJSONData = try! JSONSerialization.data(withJSONObject: podJSON, options: [.prettyPrinted])
                let podSpecJSONURL = projectRootDirectoryURL.appendingPathComponent("\(podName).podspec.json")
                try! podJSONData.write(to: podSpecJSONURL)
                print("Write podspec to: \(podSpecJSONURL)")
            }
        }
    }
}
