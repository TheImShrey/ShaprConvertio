//
//  ConversionDetailsViewModel.swift
//  ShaprConvertio
//
//  Created by Shreyash Shah on 11/02/24.
//

import Foundation

enum ConversionDetailStateChanges {
    case reload(UUID)
    case refresh
    case invalidated
    case showError(String, Error)
}

protocol ConversionDetailsViewControllerDelegate: AnyObject {
    typealias DetailStateChangeTrigger = ((ConversionDetailStateChanges) -> Void)
    
    func conversionViewModel(for taskId: UUID) -> ConversionsListViewModel.ItemViewModel?
    func addDetailStateChangeHandler(for taskId: UUID, _ handler: @escaping DetailStateChangeTrigger)
    func removeDetailStateChangeHandler(for taskId: UUID)

    func triggerRestart(on taskId: UUID)
    func triggerDelete(on taskId: UUID)
    func triggerAbort(on taskId: UUID)
}

extension ConversionsListViewModel: ConversionDetailsViewControllerDelegate {
    func conversionViewModel(for taskId: UUID) -> ItemViewModel? {
        return self.conversionViewModels.first(where: { $0.task.id == taskId })
    }

    func addDetailStateChangeHandler(for taskId: UUID, _ handler: @escaping DetailStateChangeTrigger) {
        guard self.conversionViewModels.contains(where: { $0.task.id == taskId }) /// - Note Task should be managed
        else {
            handler(.invalidated)
            return
        }
        
        self.detailStateChangeTriggers[taskId] = handler
    }
    
    func removeDetailStateChangeHandler(for taskId: UUID) {
        guard self.conversionViewModels.contains(where: { $0.task.id == taskId }) else { return } /// - Note Task should be managed
        self.detailStateChangeTriggers[taskId] = nil
    }
}
