//
//  ShaprFileManager.swift
//  ShaprConvertio
//
//  Created by Shreyash Shah on 10/02/24.
//

import Foundation

class ShaprFileManager: FileManager {
    var documentsDirectoryURL: URL {
        return self.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL.documentsDirectory
    }
    
    var privateDirectoryURL: URL {
        return self.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL.applicationSupportDirectory
    }
    
    var privateConversionDirectoryURL: URL {
        return self.privateDirectoryURL.appendingPathComponent("Conversions")
    }
    
    func deleteItemIfExists(at url: URL) throws {
        guard self.fileExists(atPath: url.path(percentEncoded: false)) else { return }
        try self.removeItem(at: url)
    }
    
    func isDirectoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let isPathExists = self.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory)
        return isPathExists && isDirectory.boolValue
    }
    
    func isFileExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let isPathExists = self.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory)
        return isPathExists && !isDirectory.boolValue
    }
    
    func isItemExists(at url: URL) -> Bool {
        return self.fileExists(atPath: url.path(percentEncoded: false))
    }
    
    func copyFile(at sourceURL: URL, byCreatingIntermediateDirectoriesTo destinationURL: URL, shouldOverwrite: Bool) throws {
        let destinationDirectoryURL = destinationURL.deletingLastPathComponent()
        
        if self.isDirectoryExists(at: destinationDirectoryURL) == false {
            try self.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true)
        } else {
            if shouldOverwrite {
                try self.deleteItemIfExists(at: destinationURL)
            }
        }
        
        try self.copyItem(at: sourceURL, to: destinationURL)
    }
    
    func moveFile(at sourceURL: URL, byCreatingIntermediateDirectoriesTo destinationURL: URL, shouldOverwrite: Bool) throws {
        let destinationDirectoryURL = destinationURL.deletingLastPathComponent()
        
        if self.isDirectoryExists(at: destinationDirectoryURL) == false {
            try self.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true)
        } else {
            if shouldOverwrite {
                try self.deleteItemIfExists(at: destinationURL)
            }
        }
        
        try self.moveItem(at: sourceURL, to: destinationURL)
    }
    
    override init() {
        super.init()
        // MARK: Enable Debugging
        try? contentsOfDirectory(atPath: documentsDirectoryURL.path(percentEncoded: false)).forEach { item in
            try? removeItem(atPath: documentsDirectoryURL.appending(path: item).path(percentEncoded: false))
        }
        try? contentsOfDirectory(atPath: privateDirectoryURL.path(percentEncoded: false)).forEach { item in
            try? removeItem(atPath: privateDirectoryURL.appending(path: item).path(percentEncoded: false))
        }
    }
}
