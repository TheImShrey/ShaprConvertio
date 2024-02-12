//
//  ConversionsListViewController.swift
//  ShaprConvertio
//
//  Created by Shreyash Shah on 10/02/24.
//

import UIKit
import SnapKit
import UniformTypeIdentifiers

class ConversionsListViewController: UIViewController, FilePickable, AlertPresentable {
    struct Theme {
        static let backgroundColor: UIColor = .systemBackground
        static let emptyStateLabelColor: UIColor = .secondaryLabel
        static let convertButtonColor: UIColor = .tintColor
    }
    
    struct Metrics {
        static let convertButtonHeight: CGFloat = 80
        static let standardPadding: CGFloat = 20
    }
    
    var currentFilePicker: UIDocumentPickerViewController?
    let viewModel: ConversionsListViewModel
    
    let conversionsListView: ConversionListCollectionView = {
        let collectionView = ConversionListCollectionView()
        return collectionView
    }()
    
    let emptyStateView: UILabel = {
        let label = UILabel()
        let firstPart = NSAttributedString(string: "No conversions yet, tap ")
        let imageAttachment = NSTextAttachment(image: UIImage.add.withTintColor(Theme.convertButtonColor))
        let imagePart = NSAttributedString(attachment: imageAttachment)
        let restOfText = NSAttributedString(string: " in top corner to start converting!")
        let attributedString = NSMutableAttributedString()
        attributedString.append(firstPart)
        attributedString.append(imagePart)
        attributedString.append(restOfText)
        attributedString.addAttributes([.font: UIFont.systemFont(ofSize: 22, weight: .semibold)],
                                       range: NSRange(location: 0,
                                                      length: attributedString.length))


        label.attributedText = attributedString
        label.textAlignment = .center
        label.textColor = Theme.emptyStateLabelColor
        label.numberOfLines = 0
        return label
    }()

    init(environment: Environment) {
        self.viewModel = ConversionsListViewModel(environment: environment)
        super.init(nibName: nil, bundle: nil)
        
        self.viewModel.onStateChange = { [weak self] in self?.handle(stateChange: $0)}
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard let flowLayout = conversionsListView.collectionViewLayout as? UICollectionViewFlowLayout
        else {
            return
        }
        flowLayout.invalidateLayout()
    }


    func setupUI() {
        view.backgroundColor = Theme.backgroundColor
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.add.withTintColor(Theme.convertButtonColor),
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(convertButtonTapped))

        navigationItem.title = "Shapr Convertio"
        setupConstraints()

        conversionsListView.emptyStateView = emptyStateView
        self.conversionsListView.conversionItemsDelegate = self
        self.conversionsListView.dataSource = self
    }
    
    func setupConstraints() {
        view.addSubview(conversionsListView)

        conversionsListView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @objc
    func convertButtonTapped() {
        guard currentFilePicker == nil else { return } /// - Note Edge case future proofing, if picker is already shown let user dismiss that first
        guard let shapr3DModelFileType = UTType(filenameExtension: Constants.Conversion.inputType.rawValue) else { return }
                                            
        currentFilePicker = presentFilePicker(having: shapr3DModelFileType, 
                                              forExternalFiles: true,
                                              withMultipleSelection: true)
    }
    
    func handle(stateChange: ConversionsListViewModel.StateChanges) {
        switch stateChange {
        case .reloadAll:
            self.conversionsListView.performBatchUpdates { [weak self] in
                self?.conversionsListView.reloadData()
            }
        case .reloadItems(let itemTuples):
            self.conversionsListView.performBatchUpdates { [weak self] in
                let indexPaths = itemTuples.map { IndexPath(item: $0.index, section: 0) }
                self?.conversionsListView.reloadItems(at: indexPaths)
            }
        case .conversionItemsAdded(let indices):
            self.conversionsListView.performBatchUpdates { [weak self] in
                let indexPaths = indices.map { IndexPath(item: $0, section: 0) }
                self?.conversionsListView.insertItems(at: indexPaths)
            }
        case .conversionItemsRemoved(let indices):
            self.conversionsListView.performBatchUpdates { [weak self] in
                let indexPaths = indices.map { IndexPath(item: $0, section: 0) }
                self?.conversionsListView.deleteItems(at: indexPaths)
            }
        case .showActionAlert(let actionType, let conversionItem):
            switch actionType {
            case .statusTap:
                switch conversionItem.task.status {
                case .failed(let error):
                    self.presentAlert(title: "Conversion Failed", message: "\(error.localizedDescription)")
                default:
                    self.openTaskDetailsScreen(for: conversionItem)
                }
            default:
                let taskId = conversionItem.task.id
                let onAccept = { [weak self] in
                    switch actionType {
                    case .abort:
                        self?.viewModel.triggerAbort(on: taskId)
                    case .restart:
                        self?.viewModel.triggerRestart(on: taskId)
                    case .delete:
                        self?.viewModel.triggerDelete(on: taskId)
                    default:
                        break
                    }
                }
                self.presentAlert(title: "\(actionType.rawValue)",
                                  message: "Are you sure you want to \(actionType.rawValue) the conversion for \(conversionItem.task.request.modelURL.lastPathComponent)?\nYou will loose all un-exported data.",
                                  isDestructive: actionType == .restart ? false : true,
                                  yesAction: onAccept,
                                  noAction: nil,
                                  anchor: navigationController?.navigationBar)
            }
        case .showError(let taskId, let title, let error):
            self.presentAlert(title: title, message: "TaskId: \(taskId)\nError: \(error.localizedDescription)")
        }
    }
    
    func openTaskDetailsScreen(for conversionTaskItem: ConversionsListViewModel.ItemViewModel) {
        let conversionDetailsVC = ConversionDetailsViewController(taskId: conversionTaskItem.task.id,
                                                                  delegate: self.viewModel)
        let navigationController = UINavigationController(rootViewController: conversionDetailsVC)
        self.navigationController?.present(navigationController, animated: true)
    }
}

extension ConversionsListViewController {
    @objc
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard currentFilePicker == controller else { return } /// - Note will come into picture when app might have multiple picker instances from same screen
        urls.forEach { pickedFileURL in
            viewModel.addFileForConversion(fileURL: pickedFileURL)
        }
        currentFilePicker = nil
    }
    
    @objc
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        guard currentFilePicker == controller else { return } /// - Note will come into picture when app might have multiple picker instances from same screen
        controller.dismiss(animated: true) { [weak self] in
            self?.currentFilePicker = nil
        }
    }
}


extension ConversionsListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        lazy var defaultItemsCount = 0
        
        switch collectionView {
        case is ConversionListCollectionView:
            return viewModel.conversionViewModels.count
        default:
            return defaultItemsCount
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        lazy var emptyCell = UICollectionViewCell()
        
        switch collectionView {
        case self.conversionsListView:
            guard let conversionItemViewModel = viewModel.conversionViewModels.item(at: indexPath.row),
                  let conversionCell = conversionsListView.dequeueReusableCell(of: ConversionItemCell.self, for: indexPath)
            else {
                return emptyCell
            }
            
            conversionCell.configure(using: conversionItemViewModel)
            return conversionCell
        default:
            return emptyCell
        }
    }
}

extension ConversionsListViewController: ConversionListCollectionViewDelegate {
    func conversionListCollectionView(_ conversionListCollectionView: ConversionListCollectionView, didSelectItemAt indexPath: IndexPath) {
        switch conversionListCollectionView {
        case self.conversionsListView:
            guard let conversionItem = viewModel.conversionViewModels.item(at: indexPath.row) else { return }
            self.openTaskDetailsScreen(for: conversionItem)
            debugPrint("Tapped: \(conversionItem.task.request.modelURL.lastPathComponent)")
            break
        default:
            break
        }
    }
}

