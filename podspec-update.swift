import Foundation

struct Command {
    static func execute(_ command: String, fromDirectory: String? = nil) -> String {
        print("Executing: \(command)\nIn: \(fromDirectory ?? "")")
        
        let ouputPipe = Pipe()
        let errorPipe = Pipe()
        let task = Process()
        task.standardOutput = ouputPipe
        task.standardError = errorPipe
        if let fromDirectory = fromDirectory {
            task.currentDirectoryPath = fromDirectory
        }
        task.launchPath = "/usr/bin/env"
        task.arguments = ["-S",command]
        task.launch()
        
        let outputData = ouputPipe.fileHandleForReading.readDataToEndOfFile()
        let outputString = String(data: outputData, encoding: .utf8)
        
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorString = String(data: errorData, encoding: .utf8)
        
        task.waitUntilExit()
        
        if task.terminationStatus == 0 {
            return outputString ?? ""
        } else {
            print(outputString ?? "")
            if let errorString = errorString {
                print(errorString)
            }
            print("Task exited with non-zero code: \(task.terminationStatus)\nCommand: \(command)")
            abort()
        }
    }
}

func updatePodspec(with projectRootDirecgtoryURL: URL) {
    let fileManager = FileManager()
    let developmentPodsDirectoryURL = projectRootDirecgtoryURL.appendingPathComponent("Frameworks")
    let contents = try! fileManager.contentsOfDirectory(at: developmentPodsDirectoryURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
    let currentVersion = Command.execute("git describe --abbrev=0 --tags", fromDirectory: projectRootDirecgtoryURL.path).trimmingCharacters(in: .whitespacesAndNewlines)
    print("Using version: \(currentVersion)")
    for podDirectoryURL in contents {
        let podName = podDirectoryURL.lastPathComponent
        let podSpecFileURL = podDirectoryURL.appendingPathComponent(podName).appendingPathExtension("podspec")
        if fileManager.fileExists(atPath: podSpecFileURL.path) {
            let jsonString = Command.execute("pod ipc spec \(podSpecFileURL.lastPathComponent)", fromDirectory: podDirectoryURL.path)
            var podJSON = try! JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!, options: []) as! [String:Any]
            
            //version
            podJSON["version"] = currentVersion
            
            //source
            var source = podJSON["source"] as! [String:Any]
            source["tag"] = currentVersion
            podJSON["source"] = source
            
            //files
            let pathPrefix = "Frameworks/\(podName)/"
            let fileFields = ["source_files","public_header_files","private_header_files","vendored_frameworks","vendored_library","resource_bundle","resource","exclude_files","preserve_path","module_map","resources"]
            
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
            let podSpecJSONURL = projectRootDirecgtoryURL.appendingPathComponent("\(podName).podspec.json")
            try! podJSONData.write(to: podSpecJSONURL)
            print("Write podspec to: \(podSpecJSONURL)")
        }
    }
}

let currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
updatePodspec(with: currentDirectoryURL)
