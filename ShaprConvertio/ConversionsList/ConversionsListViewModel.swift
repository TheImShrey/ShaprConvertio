//
//  ConversionsListViewModel.swift
//  ShaprConvertio
//
//  Created by Shreyash Shah on 10/02/24.
//

import Foundation

class ConversionsListViewModel {
    typealias StateChangeTrigger = ((StateChanges) -> Void)

    enum StateChanges {
        case conversionItemsRemoved([Int])
        case conversionItemsAdded([Int])
        case reloadItems([(index: Int, oldTaskId: UUID)])
        case reloadAll
        case showActionAlert(ItemViewModel.ActionType, ItemViewModel)
        case showError(UUID, String, Error)
    }
    
    class ItemViewModel {
        enum ActionType: String {
            case abort = "Abort"
            case restart = "Restart"
            case delete = "Delete"
            case statusTap = "Status"
        }
        
        typealias UITriggerAction = ((ActionType) -> Void)
        
        let task: ConversionTask
        let actionTriggered: UITriggerAction
        var statusChanged: ((ConversionTask.Status) -> Void)?
        weak var previewService: ModelPreviewService?

        init(task: ConversionTask, 
             previewService: ModelPreviewService,
             onActionTrigger: @escaping UITriggerAction) {
            self.actionTriggered = onActionTrigger
            self.task = task
            self.previewService = previewService
        }
        
        func renderPreview(in resolution: ModelPreviewService.Resolution, onLoaded: @escaping ModelPreviewService.LoadingResult) {
            guard let previewService
            else {
                onLoaded(.failure(AppError.somethingWentWrong))
                return
            }
            let modelURL = task.request.modelURL
            previewService.loadModelPreview(from: modelURL, resolution: resolution, onLoaded: onLoaded)
        }
    }
    
    var detailStateChangeTriggers: [UUID : DetailStateChangeTrigger?]
    var onStateChange: StateChangeTrigger?
    let taskRunner: AsyncTaskRunner
    let environment: Environment
    var conversionViewModels: [ItemViewModel]
    
    init(environment: Environment) {
        self.taskRunner = AsyncTaskRunner()
        self.conversionViewModels = []
        self.detailStateChangeTriggers = [:]
        self.environment = environment
    }
    
    private func createConversionTaskItem(for fileURL: URL) -> ItemViewModel {
        let conversionRequest = ConversionTask.Request(modelURL: fileURL,
                                                       destinationDirectory: environment.fileManager.documentsDirectoryURL,
                                                       convertTo: .obj)
        
        let conversionTask = ConversionTask(for: conversionRequest,
                                            using: environment.fileManager,
                                            delegate: self)
                
        let taskId = conversionTask.id
        let onActionTrigger: ItemViewModel.UITriggerAction = { [weak self, taskId] action in
            guard let self,
                  let conversionTaskItem = self.conversionViewModels.first(where: { $0.task.id == taskId })
            else { return }
            
            self.dispatch(stateChange: .showActionAlert(action, conversionTaskItem))
        }
        
        let conversionItemModel = ItemViewModel(task: conversionTask,
                                                previewService: environment.modelPreviewService,
                                                onActionTrigger: onActionTrigger)
        
        return conversionItemModel
    }
    
    func addFileForConversion(fileURL: URL) {
        let conversionTaskItem = self.createConversionTaskItem(for: fileURL)
        self.conversionViewModels.append(conversionTaskItem)
        
        /// - Note Ignore prepare failure as it won't fail since its just created
        try? self.prepare(conversionTask: conversionTaskItem.task)
        
        self.dispatch(stateChange: .conversionItemsAdded([conversionViewModels.count - 1]))
    }
    
    private func prepare(conversionTask: ConversionTask) throws {
        do {
            try conversionTask.prepare()
        } catch {
            debugPrint("Task(\(conversionTask.id)) prepare failed: \(error)")
            throw error
        }
    }
    
    func triggerAbort(on taskId: UUID) {
        guard let conversionTaskItemIndex = self.conversionViewModels.firstIndex(where: { $0.task.id == taskId }),
              let conversionTaskItem = self.conversionViewModels.item(at: conversionTaskItemIndex)
        else { return }
        do {
            try taskRunner.stop(task: conversionTaskItem.task)
        } catch {
            self.dispatch(stateChange: .showError(taskId, "Cant abort task", error))
        }
    }
    
    func triggerDelete(on taskId: UUID) {
        guard let conversionTaskItemIndex = self.conversionViewModels.firstIndex(where: { $0.task.id == taskId }),
              let conversionTaskItem = self.conversionViewModels.item(at: conversionTaskItemIndex)
        else { return }
        try? taskRunner.stop(task: conversionTaskItem.task)
        /// - Note Delete task regardless of abortion status
        self.conversionViewModels.remove(at: conversionTaskItemIndex)
        self.dispatch(stateChange: .conversionItemsRemoved([conversionTaskItemIndex]))
    }
    
    func triggerRestart(on taskId: UUID) {
        guard let conversionTaskItemIndex = self.conversionViewModels.firstIndex(where: { $0.task.id == taskId }),
              let conversionTaskItem = self.conversionViewModels.item(at: conversionTaskItemIndex)
        else { return }
        
        if !conversionTaskItem.task.status.isEnded {
            try? taskRunner.stop(task: conversionTaskItem.task)
        }
        
        /// - Note Recreate task regardless of abortion status
        /// - Note Input file URL from existing's task's private request folder is used, as we don't have guarantee that `modelURL` still exits
        let newConversionTaskItem = self.createConversionTaskItem(for: conversionTaskItem.task.workingInputModelURL)
        self.conversionViewModels.replaceItem(at: conversionTaskItemIndex, with: newConversionTaskItem)
        
        /// - Note Ignore prepare failure as it won't fail since its just created
        try? self.prepare(conversionTask: newConversionTaskItem.task)
        
        self.dispatch(stateChange: .reloadItems([(index: conversionTaskItemIndex, oldTaskId: conversionTaskItem.task.id)]))
    }
    
    func dispatch(stateChange: StateChanges) {
        self.triggerDetailStateChangeHandlers(for: stateChange)
        self.onStateChange?(stateChange)
    }
    
    func triggerDetailStateChangeHandlers(for stateChange: StateChanges) {
        guard !detailStateChangeTriggers.isEmpty else { return }
        
        switch stateChange {
        case .conversionItemsRemoved(let taskIndices):
            taskIndices.forEach { taskIndex in
                guard let conversionTaskItem = self.conversionViewModels.item(at: taskIndex) else { return }
                detailStateChangeTriggers[conversionTaskItem.task.id]??(.invalidated)
                detailStateChangeTriggers[conversionTaskItem.task.id] = nil
            }
            
        case .conversionItemsAdded(let taskIndices):
            taskIndices.forEach { taskIndex in
                guard let conversionTaskItem = self.conversionViewModels.item(at: taskIndex) else { return }
                detailStateChangeTriggers[conversionTaskItem.task.id]??(.refresh)
            }
            
        case .reloadItems(let itemTuples):
            itemTuples.forEach { itemTuple in
                let (taskIndex, oldTaskId) = itemTuple
                guard let newTaskId = self.conversionViewModels.item(at: taskIndex)?.task.id else { return }
                detailStateChangeTriggers[newTaskId] = detailStateChangeTriggers[oldTaskId]
                detailStateChangeTriggers[newTaskId]??(.reload(newTaskId))
            }
            
        case .reloadAll:
            detailStateChangeTriggers.forEach { (taskId, trigger) in
                let idTriggerValid = self.conversionViewModels.contains(where: {$0.task.id == taskId})
                if idTriggerValid {
                    trigger?(.refresh)
                }
            }
            
        case .showActionAlert(let actionType, let itemViewModel):
            return
        case .showError(let taskId, let string, let error):
            detailStateChangeTriggers[taskId]??(.showError(string, error))
        }
    }
}

extension ConversionsListViewModel: ConversionTaskDelegate {
    func task(_ task: ConversionTask, didChangeStatus status: ConversionTask.Status) {
        debugPrint("Task \(task.id) changed status to \(status)")
        if let taskIndex = conversionViewModels.firstIndex(where: { $0.task.id == task.id }) {
            conversionViewModels.item(at: taskIndex)?.statusChanged?(status)
            triggerDetailStateChangeHandlers(for: .reloadAll)
        }
        
        switch status {
        case .pending:
            break
        case .preparing:
            break
        case .ready:
            self.taskRunner.run(task: task, with: .foreground)
        case .ongoing(let progress):
            break
        case .completed:
            break
        case .exported:
            break
        case .aborting:
            break
        case .failed(let error):
            break
        }
    }
}
