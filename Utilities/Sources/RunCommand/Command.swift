//
//  File.swift
//  
//
//  Created by YuAo on 2020/3/16.
//

import Foundation

public struct Command {
    public enum Error: Swift.Error, LocalizedError {
        case abnormalExit(String,Int32)
        
        public var errorDescription: String? {
            switch self {
            case .abnormalExit(let task, let code):
                return "Command failed: \"\(task)\"\nExited with non-zero code: \(code)"
            }
        }
    }
    public static func execute(_ command: String, fromDirectory: String? = nil) throws -> String {
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
            throw Error.abnormalExit(command, task.terminationStatus)
        }
    }
}
