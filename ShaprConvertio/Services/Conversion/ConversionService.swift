//
//  ConversionService.swift
//  ShaprConvertio
//
//  Created by Shreyash Shah on 10/02/24.
//

import Foundation

class ConversionService {
    
    enum Action {
        case `continue`
        case abort // this can be returned from the progress callback to cancel an ongoing conversion
    }

    // Cleaning up after any error is the responsibility of the caller
    enum `Error`: Swift.Error {
        case aborted // the conversion was cancelled by returning .abort from the progress callback
        case inputError(error: Swift.Error? = nil) // something went wrong while opening/reading the input file
        case outputError(error: Swift.Error? = nil) // something went wrong while opening/writing the output file
        case dataError // something went wrong with the conversion logic
        
        var localizedDescription: String {
            switch self {
            case .aborted:
                return NSLocalizedString("The conversion was cancelled.", comment: "")
            case .inputError(let error):
                return NSLocalizedString("An error occurred while opening/reading the input file: \(error?.localizedDescription ?? "Unknown error")", comment: "")
            case .outputError(let error):
                return NSLocalizedString("An error occurred while opening/writing the output file: \(error?.localizedDescription ?? "Unknown error")", comment: "")
            case .dataError:
                return NSLocalizedString("An error occurred with the conversion logic.", comment: "")
            }
        }
    }
    
    let fileManager: ShaprFileManager
    
    init(fileManager: ShaprFileManager) {
        self.fileManager = fileManager
    }
    
    func convert(from sourceURL: URL, // must be a file:// URL readable by this process
                 to targetURL: URL, // must be a file:// URL writable by this process
                 progress: ((_ progress: Double) -> Action)?) throws { // progress is [0.0, 1.0] When the callback is nil it behaves as if it always returned .continue
        
        let totalBytes: UInt64
        do {
            let attributes = try fileManager.attributesOfItem(atPath: sourceURL.path)
            guard let size = attributes[FileAttributeKey.size] as? UInt64 else { throw Error.inputError() }
            totalBytes = size
        } catch {
            throw Error.inputError(error: error)
        }
        
        let input: FileHandle
        do {
            input = try FileHandle(forReadingFrom: sourceURL)
        } catch {
            throw Error.inputError(error: error)
        }
        
        guard fileManager.createFile(atPath: targetURL.path, contents: nil, attributes: nil)
        else {
            throw Error.outputError()
        }
        
        let output: FileHandle
        do {
            output = try FileHandle(forWritingTo: targetURL)
        } catch {
            throw Error.outputError(error: error)
        }
        
        var bytesWritten = 0
        while true {
            guard UInt.random(in: 0..<10000) != 0 else { throw Error.dataError } // 0.01% chance of failure
            
            usleep(UInt32.random(in: 1000...10000)) // some artificial delay
            var readData: Data
            do {
                guard let data = try input.read(upToCount: 1024),
                      !data.isEmpty
                else { return }
                readData = data
            } catch {
                throw Error.inputError(error: error)
            }
            
            for i in 0..<readData.count {
                readData[i] = ~readData[i] // top secret conversion algorithm :^)
            }
            
            do {
                try output.write(contentsOf: readData)
            }
            catch {
                throw Error.outputError(error: error)
            }
            
            bytesWritten += readData.count
            let progressPercentage = Double(bytesWritten) / Double(totalBytes)
            if let progress {
                if progressPercentage < 1.0 {
                    if progress(progressPercentage) == .abort {
                        throw Error.aborted
                    }
                } else {
                    progress(progressPercentage)
                }
            }
        }
    }
}

