//
//  File.swift
//  
//
//  Created by YuAo on 2020/3/16.
//

import Foundation
import ArgumentParser
import BoilerplateGenerator
import SwiftPackageGenerator
import UmbrellaHeaderGenerator
import PodspecGenerator

struct Main: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Code Generator Utilities for MetalPetal.",
        subcommands: [BoilerplateGenerator.self, SwiftPackageGenerator.self, UmbrellaHeaderGenerator.self,PodspecGenerator.self],
        defaultSubcommand: nil)
}

Main.main()
