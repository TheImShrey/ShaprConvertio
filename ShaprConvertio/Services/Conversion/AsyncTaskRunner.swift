//
//  AsyncTaskRunner.swift
//  ShaprConvertio
//
//  Created by Shreyash Shah on 10/02/24.
//

import Foundation
import UIKit

struct DeviceCapabilities {
    /// - Note If device is fully charged or plugged-in: 5 Conversions at a time, else 1 conversion per 20% batteryLevel
    static var maxConcurrentTasksNow: Int {
        switch UIDevice.current.batteryState {
        case .charging, .full:
            return 5
        default:
            return Int(min(5, max(1, round(UIDevice.current.batteryLevel * 100 / 20))))
        }
    }
}

/// As per the mock conversion code assuming that file conversion will be local on-device intended to run on one thread synchronously.
/// Hence this AsyncTaskRunner will make is pseudo-async without blocking UI.
class AsyncTaskRunner {
    class RunningItem {
        var taskId: UUID {
            return task.id
        }
        
        init(task: ConversionTask, qos: QoS, isPending: Bool) {
            self.task = task
            self.qos = qos
            self.isPending = isPending
        }
        
        let task: ConversionTask
        let qos: QoS
        var isPending: Bool
    }
    
    enum QoS: String {
        case foreground
        case `default`
        case background
        
        var dispatchQoS: DispatchQoS {
            switch self {
            case .foreground:
                return .userInteractive
            case .default:
                return .default
            case .background:
                return .userInitiated
            }
        }
    }
    
    let id: UUID
    private let foregroundQoSQueue: DispatchQueue
    private let defaultQoSQueue: DispatchQueue
    private let backgroundQoSQueue: DispatchQueue
    private var runningItems: [UUID: RunningItem]
    private var currentConcurrentTasks: Int {
        didSet {
            if oldValue > self.currentConcurrentTasks {
                self.runNext()
            }
        }
    }

    init() {
        self.currentConcurrentTasks = 0
        self.runningItems = [:]
        self.id = UUID()
        self.foregroundQoSQueue = DispatchQueue(label: "com.shapr.convertio.TaskRunner(QoS: \(QoS.foreground.rawValue), id: \(id.uuidString))",
                                                qos: QoS.foreground.dispatchQoS,
                                                attributes: .concurrent,
                                                autoreleaseFrequency: .workItem)
        
        self.defaultQoSQueue = DispatchQueue(label: "com.shapr.convertio.TaskRunner(QoS: \(QoS.default.rawValue), id: \(id.uuidString))",
                                             qos: QoS.default.dispatchQoS,
                                             attributes: .concurrent,
                                             autoreleaseFrequency: .workItem)
        
        self.backgroundQoSQueue = DispatchQueue(label: "com.shapr.convertio.TaskRunner(QoS: \(QoS.background.rawValue), id: \(id.uuidString))",
                                                qos: QoS.background.dispatchQoS,
                                                attributes: .concurrent,
                                                autoreleaseFrequency: .workItem)
    }
    
    deinit {
        runningItems.forEach { taskId, runningItem in
            try? self.abort(runningItem: runningItem)
        }
        
        runningItems.removeAll()
    }
    
    func run(task: ConversionTask, with qos: QoS = .default) {
        guard runningItems[task.id] == nil else {
            // TODO: Task is already managed by runner
            debugPrint("SyncTaskAsyncRunner(\(id)): Task(\(task.id)) is already managed by runner.")
            return
        }
        
        let runningItem = RunningItem(task: task, qos: qos, isPending: true)
        let taskId = runningItem.taskId
        
        self.runningItems[taskId] = runningItem
        
        guard currentConcurrentTasks < DeviceCapabilities.maxConcurrentTasksNow else { return }
        runNow(item: runningItem)
    }
    
    private func runNow(item: RunningItem) {
        let taskId = item.taskId
        item.isPending = false
        currentConcurrentTasks += 1
        queue(for: item.qos).async { [weak self, taskId] in
            guard let self,
                  let runningItem = self.runningItems[taskId]
            else {
                self?.currentConcurrentTasks -= 1
                return
            }
            
            do {
                try item.task.start()
                debugPrint("SyncTaskAsyncRunner(\(self.id)): Task(\(item.taskId)) COMPLETED")
            } catch {
                debugPrint("SyncTaskAsyncRunner(\(self.id)): Task(\(item.taskId)) FAILED ERROR: \(error)")
            }
            
            self.runningItems[item.taskId] = nil
            self.currentConcurrentTasks -= 1
        }
    }
    
    private func runNext() {
        let availableSlots = DeviceCapabilities.maxConcurrentTasksNow - self.currentConcurrentTasks
        guard availableSlots > 0 else { return }
        
        var slotsConsumed = 0
        for runningItem in self.runningItems.values where slotsConsumed <= availableSlots && runningItem.isPending && runningItem.task.status == .ready {
            slotsConsumed += 1
            self.runNow(item: runningItem)
        }
    }
    
    func stop(task: ConversionTask) throws {
        guard let runningItem = self.runningItems[task.id] else {
            // TODO: Task is not managed by runner
            debugPrint("SyncTaskAsyncRunner(\(id)): Task(\(task.id)) is not managed by runner.")
            return
        }
                
        self.runningItems[runningItem.taskId] = nil
        
        do {
            try self.abort(runningItem: runningItem)
            currentConcurrentTasks -= 1
        } catch {
            currentConcurrentTasks -= 1
            throw error
        }
    }
    
    private func abort(runningItem: RunningItem) throws {
        do {
             try runningItem.task.abort()
             debugPrint("SyncTaskAsyncRunner(\(id)): Task(\(runningItem.taskId)) ABORT REQUESTED")
         } catch {
             debugPrint("SyncTaskAsyncRunner(\(id)): Task(\(runningItem.taskId)) ABORT ERROR: \(error)")
             throw error
         }
    }
    
    func queue(for qos: QoS) -> DispatchQueue {
        switch qos {
        case .foreground:
            return foregroundQoSQueue
        case .default:
            return defaultQoSQueue
        case .background:
            return backgroundQoSQueue
        }
    }
}
