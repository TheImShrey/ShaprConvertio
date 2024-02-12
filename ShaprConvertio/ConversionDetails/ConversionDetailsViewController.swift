//
//  ConversionDetailsViewController.swift
//  ShaprConvertio
//
//  Created by Shreyash Shah on 11/02/24.
//

import UIKit
import SnapKit

class ConversionDetailsViewController: UIViewController, AlertPresentable {
    struct Theme {
        static let backgroundColor: UIColor = .systemBackground
        static let previewThumbnailBackgroundColor: UIColor = .secondarySystemBackground
        static let fileNameTextColor: UIColor = .label
        static let progressTintColor: UIColor = .systemGreen
        static let progressBackgroundTintColor: UIColor = .tertiarySystemGroupedBackground
        static let conversionEndedDescriptionTextColor: UIColor = .secondaryLabel
        static let controlButtonTextColor: UIColor = .white
        static let controlButtonTintColor: UIColor = .white
        static let deleteButtonTintColor: UIColor = .white
        static let conversionModeFromTypeColor: UIColor = .systemGreen
        static let conversionModeToTypeColor: UIColor = .systemBlue
    }
    
    struct Metrics {
        static let standardPadding: CGFloat = 20
        static let extraPadding: CGFloat = 40
        static let statusBorderWidth: CGFloat = 2
        static let statusLabelHeight: CGFloat = 42
        static let progressBarHeight: CGFloat = 30
        static let standardCornerRadius: CGFloat = 10
        static let smallCornerRadius: CGFloat = 5
    }

    private let previewThumbnail: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = Metrics.standardCornerRadius
        imageView.clipsToBounds = true
        imageView.image = ImageLoadingState.awaited.image
        imageView.backgroundColor = Theme.previewThumbnailBackgroundColor
        return imageView
    }()

    private let conversionModeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20)
        label.numberOfLines = 1
        label.text = "-"
        return label
    }()

    private let progressBar: UIProgressView = {
        let progressView = UIProgressView()
        progressView.progressTintColor = Theme.progressTintColor
        progressView.trackTintColor = Theme.progressBackgroundTintColor
        progressView.layer.cornerRadius = Metrics.smallCornerRadius
        progressView.clipsToBounds = true
        progressView.progress = 0
        progressView.isHidden = false
        return progressView
    }()

    private let conversionEndedDescriptionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.numberOfLines = 1
        label.text = "-"
        label.textColor = Theme.conversionEndedDescriptionTextColor
        label.isHidden = true
        return label
    }()

    private let statusLabel: PaddingLabel = {
        let label = PaddingLabel()
        label.textInsets = UIEdgeInsets(top: 10, left: 6, bottom: 10, right: 6)
        label.font = UIFont.monospacedSystemFont(ofSize: 20, weight: .semibold)
        label.numberOfLines = 1
        label.layer.cornerRadius = Metrics.standardCornerRadius
        label.layer.borderWidth = Metrics.statusBorderWidth
        label.clipsToBounds = true
        let status = ConversionTask.Status.pending
        label.text = status.labelText
        label.textColor = status.labelColor
        label.backgroundColor = status.labelColor.withAlphaComponent(0.4)
        label.layer.borderColor = status.labelColor.cgColor
        label.isUserInteractionEnabled = true
        return label
    }()

    /// - Note Instead of separate viewModel we follow single source of truth principle, where parent viewModel will be acting as delegate for this ViewController
    weak var delegate: ConversionDetailsViewControllerDelegate?
    private(set) var taskId: UUID
    var currentControlActionType: ConversionsListViewModel.ItemViewModel.ActionType?
    
    var conversionTaskItem: ConversionsListViewModel.ItemViewModel? {
        if let conversionTaskItem = self.delegate?.conversionViewModel(for: self.taskId) {
            return conversionTaskItem
        } else {
            self.handle(stateChange: .invalidated)
            return nil
        }
    }
    
    init(taskId: UUID, delegate: ConversionDetailsViewControllerDelegate) {
        self.taskId = taskId
        self.delegate = delegate
        self.currentControlActionType = nil
        super.init(nibName: nil, bundle: nil)
        
        guard let conversionTaskItem  else { return }

        self.delegate?.addDetailStateChangeHandler(for: conversionTaskItem.task.id) { [weak self] in self?.handle(stateChange: $0) }
    }
    
    deinit {
        self.delegate?.removeDetailStateChangeHandler(for: self.taskId)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        view.backgroundColor = Theme.backgroundColor
        setupConstraints()
        
        let statusLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector(statusLabelTapped))
        statusLabel.addGestureRecognizer(statusLabelTapGesture)

        guard let conversionTaskItem  else { return }
        self.configure(with: conversionTaskItem)
    }
    
    func setupConstraints() {
        view.addSubview(previewThumbnail)
        view.addSubview(conversionModeLabel)
        view.addSubview(statusLabel)
        view.addSubview(progressBar)
        view.addSubview(conversionEndedDescriptionLabel)

        conversionModeLabel.snp.makeConstraints { make in
            make.bottom.equalTo(previewThumbnail.snp.top).offset(-Metrics.standardPadding)
            make.centerX.equalToSuperview()
            make.height.greaterThanOrEqualTo(Metrics.statusLabelHeight)
        }
        
        previewThumbnail.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-Metrics.extraPadding)
            make.leading.equalToSuperview().offset(Metrics.extraPadding)
            make.trailing.equalToSuperview().inset(Metrics.extraPadding)
            make.width.equalTo(previewThumbnail.snp.height)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(previewThumbnail.snp.bottom).offset(Metrics.standardPadding)
            make.centerX.equalTo(previewThumbnail.snp.centerX)
            make.height.greaterThanOrEqualTo(Metrics.statusLabelHeight)
        }
        statusLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        statusLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        progressBar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Metrics.extraPadding)
            make.trailing.equalToSuperview().inset(Metrics.extraPadding)
            make.height.greaterThanOrEqualTo(Metrics.progressBarHeight)
            make.bottom.equalToSuperview().inset(Metrics.extraPadding)
        }

        conversionEndedDescriptionLabel.snp.makeConstraints { make in
            make.edges.equalTo(progressBar)
        }
    }
    
    private func configure(with conversionTaskItem: ConversionsListViewModel.ItemViewModel) {
        self.setPreviewThumbnail(with: conversionTaskItem)
        self.setConversionMode(with: conversionTaskItem)
        self.setFileName(with: conversionTaskItem)
        self.setProgressBarAndConversionEndedLabel(with: conversionTaskItem)
        self.setControlButton(with: conversionTaskItem)
        self.setDeleteButton()
        self.setStatusLabel(with: conversionTaskItem)
    }
    
    func handle(stateChange: ConversionDetailStateChanges) {
        switch stateChange {
        case .refresh:
            self.onStatusChange()
        case .reload(let newTaskId):
            self.taskId = newTaskId
            guard let conversionTaskItem else { break }
            self.configure(with: conversionTaskItem)
        case .invalidated:
            self.dismiss(animated: true)
        case .showError(let title, let error):
            self.presentAlert(title: title, message: "TaskId: \(taskId)\nError: \(error.localizedDescription)")
        }
    }
    
    private func setPreviewThumbnail(with conversionTaskItem: ConversionsListViewModel.ItemViewModel) {
        let taskId = conversionTaskItem.task.id
        conversionTaskItem.renderPreview(in: .hd) { [weak self, taskId] result in
            DispatchQueue.main.async {
                let imageLoadingState: ImageLoadingState
                switch result {
                case .success(let image):
                    imageLoadingState = .loaded(image: image)
                case .failure(let error):
                    imageLoadingState = .failed
                    debugPrint("Preview loading failed for model task: \(taskId) reason: \(error)")
                }
                
                self?.previewThumbnail.image = imageLoadingState.image
                self?.previewThumbnail.tintColor = imageLoadingState.tintColor
            }
        }
    }
    
    private func setConversionMode(with conversionTaskItem: ConversionsListViewModel.ItemViewModel) {
        let request = conversionTaskItem.task.request
        let fromFileSize = request.fileSize?.fileSizeString() ?? "** KB"
        let fromType = [fromFileSize, conversionTaskItem.task.request.modelURL.pathExtension].joined(separator: " @ ")
        
        let output = conversionTaskItem.task.output
        let toFileSize = output.fileSize?.fileSizeString() ?? "** KB"
        let toType = [toFileSize, conversionTaskItem.task.request.convertTo.rawValue].joined(separator: " @ ")

        let greenAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: Theme.conversionModeFromTypeColor,
            .font: UIFont.systemFont(ofSize: 20, weight: .semibold)
        ]

        let blueAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: Theme.conversionModeToTypeColor,
            .font: UIFont.systemFont(ofSize: 20, weight: .semibold)
        ]

        let conversionModeString = NSMutableAttributedString(string: "\(fromType) -> \(toType)")

        conversionModeString.addAttributes(greenAttributes, range: NSRange(location: 0, length: fromType.count))
        conversionModeString.addAttributes(blueAttributes, range: NSRange(location: fromType.count + 4, length: toType.count))

        conversionModeLabel.attributedText = conversionModeString
    }
    
    private func setFileName(with conversionTaskItem: ConversionsListViewModel.ItemViewModel) {
        navigationItem.title = conversionTaskItem.task.request.modelURL.lastPathComponent
    }
    
    private func setProgressBarAndConversionEndedLabel(with conversionTaskItem: ConversionsListViewModel.ItemViewModel) {
        let taskStatus = conversionTaskItem.task.status
        
        let conversionEnded = taskStatus.isEnded
        progressBar.progress = Float(taskStatus.progress)
        progressBar.isHidden = conversionEnded
        conversionEndedDescriptionLabel.isHidden = !conversionEnded
        if conversionEnded {
            let durationString = conversionTaskItem.task.endTime.shortHandedDuration(since: conversionTaskItem.task.startTime)
            conversionEndedDescriptionLabel.text = "Duration: \(durationString)"
        } else {
            conversionEndedDescriptionLabel.text = "-"
        }
    }
    
    private func setControlButton(with conversionTaskItem: ConversionsListViewModel.ItemViewModel) {
        let controlAction: ConversionsListViewModel.ItemViewModel.ActionType = conversionTaskItem.task.status.isEnded ? .restart : .abort
        guard self.currentControlActionType != controlAction else { return }
        self.currentControlActionType = controlAction
        let barItem = UIBarButtonItem(title: controlAction.rawValue,
                                      style: .plain,
                                      target: self,
                                      action: #selector(controlButtonTapped))
        barItem.tintColor = controlAction.backgroundColor
        navigationItem.rightBarButtonItem = barItem
    }
    
    private func setDeleteButton() {
        let deleteAction: ConversionsListViewModel.ItemViewModel.ActionType = .delete
        let barItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteButtonTapped))
        barItem.tintColor = deleteAction.backgroundColor
        navigationItem.leftBarButtonItem = barItem
    }
    
    private func setStatusLabel(with conversionTaskItem: ConversionsListViewModel.ItemViewModel) {
        let taskStatus = conversionTaskItem.task.status
        statusLabel.text = taskStatus.labelText
        statusLabel.textColor = taskStatus.labelColor
        statusLabel.layer.borderColor = taskStatus.labelColor.cgColor
        statusLabel.backgroundColor = taskStatus.labelColor.withAlphaComponent(0.4)
    }
    
    private func onStatusChange() {
        DispatchQueue.main.async {
            guard let conversionTaskItem = self.delegate?.conversionViewModel(for: self.taskId) else { return }
            self.setStatusLabel(with: conversionTaskItem)
            self.setProgressBarAndConversionEndedLabel(with: conversionTaskItem)
            self.setControlButton(with: conversionTaskItem)
        }
    }
    
    @objc
    func controlButtonTapped() {
        guard let conversionTaskItem else { return }
        let controlAction: ConversionsListViewModel.ItemViewModel.ActionType = conversionTaskItem.task.status.isEnded ? .restart : .abort

        let taskId = conversionTaskItem.task.id
        let onAccept = { [weak self] in
            switch controlAction {
            case .abort:
                self?.delegate?.triggerAbort(on: taskId)
            case .restart:
                self?.delegate?.triggerRestart(on: taskId)
            default:
                break
            }
        }
        
        self.presentAlert(title: "\(controlAction.rawValue)",
                          message: "Are you sure you want to \(controlAction.rawValue) the conversion for \(conversionTaskItem.task.request.modelURL.lastPathComponent)?\nYou will loose all un-exported data.",
                          isDestructive: controlAction == .restart ? false : true,
                          yesAction: onAccept,
                          noAction: nil,
                          anchor: navigationController?.navigationBar)
    }
    
    @objc
    func deleteButtonTapped() {
        guard let conversionTaskItem else { return }
        let controlAction: ConversionsListViewModel.ItemViewModel.ActionType = .delete

        let taskId = conversionTaskItem.task.id
        let onAccept = { [weak self] in
            self?.delegate?.triggerDelete(on: taskId)
            self?.dismiss(animated: true)
        }
        
        self.presentAlert(title: "\(controlAction.rawValue)",
                          message: "Are you sure you want to \(controlAction.rawValue) the conversion for \(conversionTaskItem.task.request.modelURL.lastPathComponent)?\nYou will loose all un-exported data.",
                          isDestructive: true,
                          yesAction: onAccept,
                          noAction: nil,
                          anchor: navigationController?.navigationBar)
    }
    
    @objc
    func statusLabelTapped() {
        guard let conversionTaskItem else { return }

        switch conversionTaskItem.task.status {
        case .failed(let error):
            self.presentAlert(title: "Conversion Failed", message: "\(error.localizedDescription)")
        default:
            break
        }
    }
}
