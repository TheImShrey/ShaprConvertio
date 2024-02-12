//
//  ConversionsListViewController+Alert.swift
//  ShaprConvertio
//
//  Created by Shreyash Shah on 11/02/24.
//

import UIKit
protocol AlertPresentable {
    func presentAlert(title: String, message: String, isDestructive: Bool, yesAction: (() -> Void)?, noAction: (() -> Void)?, anchor: UIView?)
    func presentAlert(title: String, message: String)
}

extension AlertPresentable where Self: UIViewController {
    func presentAlert(title: String, message: String, isDestructive: Bool, yesAction: (() -> Void)?, noAction: (() -> Void)?, anchor: UIView? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

        let yesButton = UIAlertAction(title: "Yes",
                                      style: isDestructive ? .destructive : .default) { _ in
            yesAction?()
        }

        let noButton = UIAlertAction(title: "No",
                                     style: .cancel) { _ in
            noAction?()
        }

        alertController.addAction(yesButton)
        alertController.addAction(noButton)
        alertController.popoverPresentationController?.sourceView = anchor

        self.present(alertController, animated: true, completion: nil)
    }
    
    func presentAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let okayAction = UIAlertAction(title: "Okay", style: .default, handler: nil)

        alertController.addAction(okayAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}
