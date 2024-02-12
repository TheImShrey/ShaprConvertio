//
//  Conversion+Ext.swift
//  ShaprConvertio
//
//  Created by Shreyash Shah on 11/02/24.
//

import UIKit

extension ConversionsListViewModel.ItemViewModel.ActionType {
    var image: UIImage {
        switch self {
        case .abort:
            return UIImage(systemName: "xmark.circle.fill") ?? UIImage()
        case .delete:
            return UIImage(systemName: "trash.circle.fill") ?? UIImage()
        case .restart:
            return UIImage(systemName: "arrow.counterclockwise.circle.fill") ?? UIImage()
        default:
            return UIImage()
        }
    }
    
    var backgroundColor: UIColor? {
        switch self {
        case .abort:
            return .systemOrange
        case .delete:
            return .systemRed
        case .restart:
            return .systemYellow
        default:
            return nil
        }
    }
}

extension ConversionTask.Status {
    var progress: Double {
        switch self {
        case .ongoing(let progress):
            return progress
        default:
            return 0.0
        }
    }
    
    var labelText: String {
        switch self {
        case .pending:
            return "🔖 Not Ready"
        case .preparing:
            return "⚒️ Readying"
        case .ready:
            return "⏳ Awaited"
        case .ongoing(let progress):
            let formattedProgress: String
            let value = progress * 100
            if value < 100 {
                formattedProgress = String(format: "%02.2f", value)
            } else {
                formattedProgress = String(format: "%.0f", value)
            }
            return "⚙️ Converting: \(formattedProgress) % "
        case .aborting:
            return "⚠️ Aborting"
        case .completed:
            return "✅ Completed"
        case .exported:
            return "📦 Exported"
        case .failed:
            return "‼️ Failed"
        }
    }
    
    var labelColor: UIColor {
        switch self {
        case .pending:
            return UIColor.systemGray // Not Ready
        case .preparing:
            return UIColor.systemCyan // Readying
        case .ready:
            return UIColor.systemTeal // Awaited
        case .ongoing:
            return UIColor.systemBlue // Converting
        case .aborting:
            return UIColor.systemOrange // Aborting
        case .completed:
            return UIColor.systemIndigo // Completed
        case .exported:
            return UIColor.systemGreen // Exported
        case .failed:
            return UIColor.systemRed // Failed
        }
    }
}

enum ImageLoadingState {
    case awaited
    case loaded(image: UIImage)
    case failed
    
    var image: UIImage {
        switch self {
        case .awaited:
            return UIImage(systemName: "square.stack.3d.up") ?? UIImage()
        case .loaded(let image):
            return image
        case .failed:
            return UIImage(systemName: "square.stack.3d.up.slash.fill") ?? UIImage()
        }
    }
    
    var tintColor: UIColor? {
        switch self {
        case .awaited:
            return .tintColor
        case .loaded:
            return nil
        case .failed:
            return .systemRed
        }
    }
}
