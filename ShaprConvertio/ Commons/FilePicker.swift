//
//  FilePicker.swift
//  ShaprConvertio
//
//  Created by Shreyash Shah on 10/02/24.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

protocol FilePickable: UIDocumentPickerDelegate where Self: UIViewController {
    func presentFilePicker(having types: UTType..., forExternalFiles: Bool, withMultipleSelection: Bool) -> UIDocumentPickerViewController
}

extension FilePickable {
    func presentFilePicker(having types: UTType..., forExternalFiles: Bool, withMultipleSelection: Bool) -> UIDocumentPickerViewController {
        let documentPickerController = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: forExternalFiles)
        documentPickerController.shouldShowFileExtensions = true
        documentPickerController.allowsMultipleSelection = withMultipleSelection
        documentPickerController.delegate = self
        self.present(documentPickerController, animated: true, completion: nil)
        return documentPickerController
    }
}
