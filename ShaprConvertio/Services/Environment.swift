//
//  Environment.swift
//  ShaprConvertio
//
//  Created by Shreyash Shah on 10/02/24.
//

import Foundation
import UIKit

enum EnvType: String {
    case release
    case debug
}

class Environment {
    let fileManager: ShaprFileManager
    let modelPreviewService: ModelPreviewService
    
    init(with type: EnvType) {
        UIDevice.current.isBatteryMonitoringEnabled = true

        // TODO: Configure environment variables depending `type` in future, ex: Mocked FileManager with debug logs etc
        self.fileManager = ShaprFileManager()
        self.modelPreviewService = ModelPreviewService.Mock()
    }
}
