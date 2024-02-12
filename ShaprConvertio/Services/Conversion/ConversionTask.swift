//
//  ConversionTask.swift
//  ShaprConvertio
//
//  Created by Shreyash Shah on 10/02/24.
//

import Foundation

protocol ConversionTaskDelegate: AnyObject {
    func task(_ task: ConversionTask, didChangeStatus: ConversionTask.Status)
}

class ConversionTask {
    struct Request {
        let modelURL: URL
        let destinationDirectory: URL
        let convertTo: Filetypes
        var fileSize: Int?
        
        init(modelURL: URL, destinationDirectory: URL, convertTo: Filetypes) {
            self.modelURL = modelURL
            self.destinationDirectory = destinationDirectory
            self.convertTo = convertTo
            self.fileSize = modelURL.fileSize()
        }
    }
    
    struct Output {
        let convertedFileURL: URL
        
        var fileName: String {
            convertedFileURL.lastPathComponent
        }
        
        var fileSize: Int? {
            convertedFileURL.fileSize()
        }
    }
    
    indirect enum Error: Swift.Error {
        case taskCanBeStartedOnlyOnce(previousStatus: Status)
        case taskCantBeAbortedIfNotOngoing(previousStatus: Status)
        case conversionError(error: ConversionService.Error)
        case cantStartTaskIsNotPrepared
        case cantStartWhileTaskIsPreparing
        case cantBeExportedInState(status: Status)
        case taskCanBePreparedOnlyOnce(previousStatus: Status)
        case somethingWentWrong(error: Swift.Error)
        case unexpected(message: String)
        
        var localizedDescription: String {
            switch self {
            case .taskCanBeStartedOnlyOnce:
                return NSLocalizedString("The task can be started only once.", comment: "")
            case .taskCantBeAbortedIfNotOngoing:
                return NSLocalizedString("The task can't be aborted if it's not ongoing.", comment: "")
            case .conversionError(let error):
                return NSLocalizedString("Conversion error: \(error.localizedDescription)", comment: "")
            case .cantStartTaskIsNotPrepared:
                return NSLocalizedString("The task can't be started because it's not prepared.", comment: "")
            case .cantStartWhileTaskIsPreparing:
                return NSLocalizedString("The task can't be started while it's preparing.", comment: "")
            case .cantBeExportedInState(let status):
                return NSLocalizedString("The task can't be exported in state: \(status).", comment: "")
            case .taskCanBePreparedOnlyOnce:
                return NSLocalizedString("The task can be prepared only once.", comment: "")
            case .somethingWentWrong(let error):
                return NSLocalizedString("Something went wrong: \(error.localizedDescription)", comment: "")
            case .unexpected(let message):
                return NSLocalizedString("Unexpected error: \(message)", comment: "")
            }
        }
    }
    
    enum Status: Equatable {
        case pending
        case preparing
        case ready
        case ongoing(progress: Double)
        case aborting
        case completed
        case exported
        case failed(error: Error)
        
        static func == (lhs: Status, rhs: Status) -> Bool {
            switch (lhs, rhs) {
            case (.pending, .pending),
                 (.preparing, .preparing),
                 (.ready, .ready),
                 (.completed, .completed),
                 (.exported, .exported),
                 (.aborting, .aborting),
                 (.ongoing, .ongoing),
                 (.failed, .failed):
                return true
            default:
                return false
            }
        }
        
        var isEnded: Bool {
            switch self {
            case .pending, .preparing, .ready, .ongoing, .aborting:
                return false
            case .completed, .exported, .failed:
                return true
            }
        }
    }
    
    private(set) var startTime: Date
    private(set) var endTime: Date
    private let service: ConversionService
    let output: Output
    private var fileManager: ShaprFileManager
    private var workingDirectoryURL: URL!
    private var workingOutputModelURL: URL!
    private(set) var workingInputModelURL: URL!
    private var abortRequested: Bool
    private weak var delegate: ConversionTaskDelegate?
    
    let id: UUID
    let request: Request
    var status: Status {
        willSet {
            if !self.status.isEnded && newValue.isEnded {
                endTime = Date()
            }
        } didSet {
            delegate?.task(self, didChangeStatus: status)
        }
    }
    
    init(for request: Request, using fileManager: ShaprFileManager, delegate: ConversionTaskDelegate) {
        let id = UUID()
        self.id = id
        self.fileManager = fileManager
        self.delegate = delegate
        self.service = ConversionService(fileManager: fileManager)
        self.request = request
        let outputFileURL = Self.createOutputURL(from: request)
        self.output = Output(convertedFileURL: outputFileURL)
        self.status = .pending
        self.abortRequested = false
        self.startTime = .distantPast
        self.endTime = .distantPast
    }
    
    deinit {
        try? self.abort()
        self.cleanUp()
    }
    
    func prepare() throws {
        guard status == .pending
        else {
            throw Error.taskCanBePreparedOnlyOnce(previousStatus: status)
        }
              
        status = .preparing
        self.setupWorkingDirectory { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(_):
                self.status = .ready
            case .failure(let error):
                let error = Error.somethingWentWrong(error: error)
                self.status = .failed(error: error)
            }
            debugPrint("Task(\(self.id)) prepare: (\(result))")
        }
    }
    
    func start() throws {
        guard status == .ready else {
            switch status {
            case .pending:
                throw Error.cantStartTaskIsNotPrepared
            case .preparing:
                throw Error.cantStartWhileTaskIsPreparing
            default:
                throw Error.taskCanBeStartedOnlyOnce(previousStatus: status)
            }
        }
        startTime = Date()
        do {
            /// - Note: As per given mock code following is not escaping closure, so assuming that file conversion will be local intended to run on same thread synchronously.
            /// Hence it will be Task Runner's responsibility to manage the concurrency of the task without blocking UI.
            try service.convert(from: workingInputModelURL, to: workingOutputModelURL) { progress in
                return self.manage(progress: progress)
            }
        } catch let error as ConversionService.Error {
            let error: Error = .conversionError(error: error)
            status = .failed(error: error)
            throw error
        } catch {
            let error: Error = .somethingWentWrong(error: error)
            status = .failed(error: error)
            throw error
        }
    }
    
    func abort() throws {
        switch status {
        case .ongoing(_):
            status = .aborting
            abortRequested = true
        default:
            throw Error.taskCantBeAbortedIfNotOngoing(previousStatus: status)
        }
    }
    
    private func manage(progress: Double) -> ConversionService.Action {
        if progress < 1.0 {
            status = .ongoing(progress: progress)
        } else { /// - Note: Completed on 1.0; as 100% progress
            status = .completed
            do {
                try export()
                status = .exported
            } catch {
                status = .failed(error: .somethingWentWrong(error: error))
            }
        }
        
        return abortRequested ? .abort : .continue
    }
    
    private func cleanUp() {
        do {
            try fileManager.deleteItemIfExists(at: workingDirectoryURL)
        } catch {
            debugPrint("Task(\(id)) Failed to cleanup: \(String(describing: workingDirectoryURL))")
        }
    }
    
    private func export() throws {
        guard status == .completed 
        else {
            throw Error.cantBeExportedInState(status: status)
        }
        
        guard fileManager.isItemExists(at: workingOutputModelURL)
        else {
            throw Error.unexpected(message: "Conversion completed, but output missing at: \(String(describing: workingOutputModelURL))")
        }
        
        do {
            try fileManager.moveFile(at: workingOutputModelURL,
                                     byCreatingIntermediateDirectoriesTo: output.convertedFileURL,
                                     shouldOverwrite: true)
        } catch {
            let failureMessage = "Task(\(id)) Failed to export: \(error)"
            debugPrint(failureMessage)
            throw Error.unexpected(message: failureMessage)
        }
    }
    
    private static func createOutputURL(from request: Request) -> URL {
        let outputFileExtension = request.convertTo.rawValue
        let plainModelFileName = request.modelURL.deletingPathExtension().lastPathComponent
        return request.destinationDirectory.appendingPathComponent(plainModelFileName).appendingPathExtension(outputFileExtension)
    }
    
    private func setupWorkingDirectory(completion: @escaping ((Result<Void, Swift.Error>) -> Void)) {
        /// - Note  Model files can be big in size and can take time to copy, so it's better to do it in background queue.
        // TODO: Find better alternative for async file operations
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let privateConversionDirectoryURL = self.fileManager.privateConversionDirectoryURL
                
                // MARK: Create empty working directory
                let taskWorkingDirectoryURL = privateConversionDirectoryURL.appending(component: self.id.uuidString)
                try self.fileManager.deleteItemIfExists(at: taskWorkingDirectoryURL)
                try self.fileManager.createDirectory(at: taskWorkingDirectoryURL, withIntermediateDirectories: true)
                self.workingDirectoryURL = taskWorkingDirectoryURL
                
                // MARK: Copy working directory
                let modelFileName = self.request.modelURL.lastPathComponent
                let workingConversionInputModelURL = taskWorkingDirectoryURL
                    .appending(component: "Request")
                    .appending(component: modelFileName)
                
                try self.fileManager.copyFile(at: self.request.modelURL,
                                              byCreatingIntermediateDirectoriesTo: workingConversionInputModelURL,
                                              shouldOverwrite: true)
                
                self.workingInputModelURL = workingConversionInputModelURL
                
                let workingConversionOutputDirectoryURL = taskWorkingDirectoryURL
                    .appending(component: "Output")
                
                try self.fileManager.createDirectory(at: workingConversionOutputDirectoryURL, withIntermediateDirectories: true)
                
                self.workingOutputModelURL = workingConversionOutputDirectoryURL.appending(component: modelFileName)

                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
