//
//  File.swift
//  
//
//  Created by YuAo on 2020/3/16.
//

import Foundation
import ArgumentParser

extension URL: ExpressibleByArgument {
    public init?(argument: String) {
        if let url = URL(string: argument), url.scheme != nil {
            self.init(url: url)
        } else {
            //Assuming it is a file url.
            if argument.hasPrefix("/") {
                //Absolute path.
                self.init(fileURLWithPath: argument)
            } else {
                //Relative to FileManager.default.currentDirectoryPath
                let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(argument)
                self.init(url: url.standardizedFileURL)
            }
        }
    }
    private init(url: URL) {
        self.init(string: url.absoluteString)!
    }
}
