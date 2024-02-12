//
//  ConversionListCollectionViewCell.swift
//  ShaprConvertio
//
//  Created by Shreyash Shah on 11/02/24.
//

import UIKit
import SnapKit

class ConversionItemCell: UICollectionViewCell, CollectionViewCellCustomizing {
    struct Theme {
        static let contentViewBackgroundColor: UIColor = .secondarySystemGroupedBackground
        static let previewThumbnailBackgroundColor: UIColor = .secondarySystemBackground
        static let fileNameTextColor: UIColor = .label
        static let progressTintColor: UIColor = .systemGreen
        static let progressBackgroundTintColor: UIColor = .tertiarySystemGroupedBackground
        static let conversionEndedDescriptionTextColor: UIColor = .secondaryLabel
        static let controlButtonTintColor: UIColor = .white
        static let deleteButtonTintColor: UIColor = .white
        static let conversionModeFromTypeColor: UIColor = .systemGreen
        static let conversionModeToTypeColor: UIColor = .systemBlue
    }

    private var imageLoadingState: ImageLoadingState = .awaited
    private weak var viewModel:  ConversionsListViewModel.ItemViewModel?

    private let previewThumbnail: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        imageView.image = ImageLoadingState.awaited.image
        imageView.backgroundColor = Theme.previewThumbnailBackgroundColor
        return imageView
    }()

    private let midBodyStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 6
        stackView.distribution = .fillProportionally
        stackView.alignment = .leading
        return stackView
    }()

    private let fileNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        label.numberOfLines = 1
        label.text = "-"
        label.textColor = Theme.fileNameTextColor
        return label
    }()

    private let conversionModeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 1
        label.text = "-"
        return label
    }()

    private let progressBar: UIProgressView = {
        let progressView = UIProgressView()
        progressView.progressTintColor = Theme.progressTintColor
        progressView.trackTintColor = Theme.progressBackgroundTintColor
        progressView.layer.cornerRadius = 5
        progressView.clipsToBounds = true
        progressView.progress = 0
        progressView.isHidden = false
        return progressView
    }()

    private let conversionEndedDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.numberOfLines = 1
        label.text = "-"
        label.textColor = Theme.conversionEndedDescriptionTextColor
        label.isHidden = true
        return label
    }()

    private let statusLabel: PaddingLabel = {
        let label = PaddingLabel()
        label.textInsets = UIEdgeInsets(top: 5, left: 3, bottom: 5, right: 3)
        label.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .semibold)
        label.numberOfLines = 1
        label.layer.cornerRadius = 5
        label.layer.borderWidth = 1
        label.clipsToBounds = true
        let status = ConversionTask.Status.pending
        label.text = status.labelText
        label.textColor = status.labelColor
        label.backgroundColor = status.labelColor.withAlphaComponent(0.4)
        label.layer.borderColor = status.labelColor.cgColor
        label.isUserInteractionEnabled = true
        return label
    }()

    private let controlButton: UIButton = {
        let button = UIButton()
        button.imageView?.contentMode = .scaleAspectFill
        let actionType = ConversionsListViewModel.ItemViewModel.ActionType.abort
        button.setImage(actionType.image, for: .normal)
        button.backgroundColor = actionType.backgroundColor
        button.tintColor = Theme.controlButtonTintColor
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        return button
    }()

    private let deleteButton: UIButton = {
        let button = UIButton()
        button.imageView?.contentMode = .scaleAspectFill
        let actionType = ConversionsListViewModel.ItemViewModel.ActionType.delete
        button.setImage(actionType.image, for: .normal)
        button.backgroundColor = actionType.backgroundColor
        button.tintColor = Theme.deleteButtonTintColor
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        return button
    }()
    

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupUI() {
        contentView.backgroundColor = Theme.contentViewBackgroundColor
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true

        contentView.addSubview(previewThumbnail)
        contentView.addSubview(midBodyStackView)
        midBodyStackView.addArrangedSubview(fileNameLabel)
        midBodyStackView.addArrangedSubview(conversionModeLabel)
        midBodyStackView.addArrangedSubview(statusLabel)
        contentView.addSubview(progressBar)
        contentView.addSubview(conversionEndedDescriptionLabel)
        contentView.addSubview(controlButton)
        contentView.addSubview(deleteButton)

        previewThumbnail.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().inset(10)
            make.leading.equalToSuperview().offset(10)
            make.width.equalTo(previewThumbnail.snp.height)
        }
        
        statusLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        statusLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        statusLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        statusLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        midBodyStackView.snp.makeConstraints { make in
            make.leading.equalTo(previewThumbnail.snp.trailing).offset(10)
            make.top.equalToSuperview().offset(10)
            make.trailing.equalTo(controlButton.snp.leading).offset(-10)
        }

        progressBar.snp.makeConstraints { make in
            make.leading.equalTo(previewThumbnail.snp.trailing).offset(10)
            make.trailing.equalToSuperview().inset(10)
            make.height.equalTo(20)
            make.top.greaterThanOrEqualTo(midBodyStackView.snp.bottom).offset(10)
            make.bottom.lessThanOrEqualToSuperview().inset(10)
        }

        conversionEndedDescriptionLabel.snp.makeConstraints { make in
            make.edges.equalTo(progressBar)
        }

        controlButton.snp.makeConstraints { make in
            make.top.greaterThanOrEqualToSuperview().offset(10)
            make.trailing.equalToSuperview().inset(10)
            make.height.equalTo(controlButton.snp.width)
            make.width.equalTo(30)
        }

        deleteButton.snp.makeConstraints { make in
            make.top.equalTo(controlButton.snp.bottom).offset(10)
            make.trailing.equalToSuperview().inset(10)
            make.bottom.greaterThanOrEqualTo(progressBar.snp.top).offset(-10)
            make.height.equalTo(deleteButton.snp.width)
            make.width.equalTo(30)
        }
        
        controlButton.addAction { [unowned self] in
            guard let viewModel = self.viewModel else { return }
            let isTaskEnded = viewModel.task.status.isEnded
            viewModel.actionTriggered(isTaskEnded ? .restart : .abort)
        }
        
        deleteButton.addAction { [unowned self] in
            guard let viewModel = self.viewModel else { return }
            viewModel.actionTriggered(.delete)
        }
        
        let statusLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector(statusLabelTapped))
        statusLabel.addGestureRecognizer(statusLabelTapGesture)
    }
    
    func configure(using viewModel: ConversionsListViewModel.ItemViewModel) {
        self.viewModel = viewModel
        self.updateUI()
    }
    
    func updateUI() {
        trackProgress()
        setPreviewThumbnail()
        setFileName()
        setConversionMode()
        setProgressBarAndConversionEndedLabel()
        setStatusLabel()
        setControlButtonIcon()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel = nil
        updateUI()
    }
    
    private func setPreviewThumbnail() {
        if let viewModel {
            let taskId = viewModel.task.id
            viewModel.renderPreview(in: .low) { [weak self, taskId] result in
                DispatchQueue.main.async {
                    guard let self else { return }
                    guard let viewModel = self.viewModel else { return }
                    guard viewModel.task.id == taskId else { return } /// - Note cases where cell was recycled for another task, ignore old image load
                    
                    switch result {
                    case .success(let image):
                        self.imageLoadingState = .loaded(image: image)
                    case .failure(let error):
                        self.imageLoadingState = .failed
                        debugPrint("Preview loading failed for model task: \(taskId) reason: \(error)")
                    }
                    
                    self.previewThumbnail.image = self.imageLoadingState.image
                    self.previewThumbnail.tintColor = self.imageLoadingState.tintColor
                }
            }
        } else {
            self.imageLoadingState = .awaited
            self.previewThumbnail.image = imageLoadingState.image
            self.previewThumbnail.tintColor = imageLoadingState.tintColor
        }
    }
    
    private func setConversionMode() {
        if let viewModel {
            let fromType = viewModel.task.request.modelURL.pathExtension
            let toType = viewModel.task.request.convertTo.rawValue

            let greenAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: Theme.conversionModeFromTypeColor,
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
            ]

            let blueAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: Theme.conversionModeToTypeColor,
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
            ]

            let conversionModeString = NSMutableAttributedString(string: "\(fromType) -> \(toType)")

            conversionModeString.addAttributes(greenAttributes, range: NSRange(location: 0, length: fromType.count))
            conversionModeString.addAttributes(blueAttributes, range: NSRange(location: fromType.count + 4, length: toType.count))

            conversionModeLabel.attributedText = conversionModeString
        } else {
            conversionModeLabel.text = "-"
        }
    }
    
    private func setFileName() {
        if let viewModel {
            fileNameLabel.text = viewModel.task.request.modelURL.deletingPathExtension().lastPathComponent
        } else {
            fileNameLabel.text = "-"
        }
    }
    
    private func setProgressBarAndConversionEndedLabel() {
        let taskStatus = viewModel?.task.status ?? .pending
        
        let conversionEnded = taskStatus.isEnded
        progressBar.progress = Float(taskStatus.progress)
        progressBar.isHidden = conversionEnded
        conversionEndedDescriptionLabel.isHidden = !conversionEnded
        if let viewModel, viewModel.task.status.isEnded {
            let durationString = viewModel.task.endTime.shortHandedDuration(since: viewModel.task.startTime)
            conversionEndedDescriptionLabel.text = "Duration: \(durationString)"
        } else {
            conversionEndedDescriptionLabel.text = "-"
        }
    }
    
    private func setControlButtonIcon() {
        let taskStatus = viewModel?.task.status ?? .pending
        
        let isTaskEnded = taskStatus.isEnded
        let actionType: ConversionsListViewModel.ItemViewModel.ActionType = isTaskEnded ? .restart : .abort
        
        let iconImage = actionType.image
        controlButton.setImage(iconImage, for: .normal)
        controlButton.backgroundColor = actionType.backgroundColor
    }
    
    private func setStatusLabel() {
        let taskStatus = viewModel?.task.status ?? .pending
        statusLabel.text = taskStatus.labelText
        statusLabel.textColor = taskStatus.labelColor
        statusLabel.layer.borderColor = taskStatus.labelColor.cgColor
        statusLabel.backgroundColor = taskStatus.labelColor.withAlphaComponent(0.4)
    }
    
    @objc
    private func statusLabelTapped() {
        self.viewModel?.actionTriggered(.statusTap)
    }
    
    private func onStatusChange(_ status: ConversionTask.Status) {
        DispatchQueue.main.async {
            self.setStatusLabel()
            self.setProgressBarAndConversionEndedLabel()
            self.setControlButtonIcon()
        }
    }
    
    private func trackProgress() {
        self.viewModel?.statusChanged = onStatusChange
    }
}
