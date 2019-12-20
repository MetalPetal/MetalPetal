//
//  Alert.swift
//  DemoApp
//
//  Created by Yu Ao on 2019/12/17.
//  Copyright © 2019 Yu Ao. All rights reserved.
//

import Foundation
import UIKit

public struct Alert {
    
    public struct Action {
        let title: String
        let handler: (() -> Void)?
        public init(_ title: String, _ handler: (() -> Void)? = nil) {
            self.title = title
            self.handler = handler
        }
    }
    
    private let alertController: UIAlertController
    
    public init(error: Error, title: String? = nil, confirmActionTitle: String) {
        alertController = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: confirmActionTitle, style: .cancel, handler: nil))
    }
    
    public init(message: String, title: String? = nil, confirmAction: Action) {
        alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: confirmAction.title, style: .cancel, handler: { _ in
            confirmAction.handler?()
        }))
    }
    
    public init(message: String, title: String? = nil, confirmAction: Action, cancelActionTitle: String) {
        alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: confirmAction.title, style: .default, handler: { _ in
            confirmAction.handler?()
        }))
        alertController.addAction(UIAlertAction(title: cancelActionTitle, style: .cancel, handler: nil))
    }
    
    public init(message: String, title: String? = nil, destructiveAction: Action, cancelActionTitle: String) {
        alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: destructiveAction.title, style: .destructive, handler: { _ in
            destructiveAction.handler?()
        }))
        alertController.addAction(UIAlertAction(title: cancelActionTitle, style: .cancel, handler: nil))
    }
    
    public func show(in viewController: UIViewController, completion: (() -> Void)? = nil) {
        viewController.present(alertController, animated: true, completion: completion)
    }

    private struct AssociationKeys  {
        static var presentingWindow: UInt8 = 0
    }
    
    public func show(in application: UIApplication = UIApplication.shared, completion: (() -> Void)? = nil) {
        let presentingWindow = UIWindow(frame: UIScreen.main.bounds)
        presentingWindow.rootViewController = UIViewController()
        // set alert window above current top window
        if let topWindow = application.windows.last {
            presentingWindow.windowLevel = topWindow.windowLevel + 1
        }
        presentingWindow.makeKeyAndVisible()
        objc_setAssociatedObject(alertController, &AssociationKeys.presentingWindow, presentingWindow, .OBJC_ASSOCIATION_RETAIN)
        self.show(in: presentingWindow.rootViewController!, completion: completion)
    }
}
