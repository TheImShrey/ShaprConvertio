//
//  ConversionListCollectionView.swift
//  ShaprConvertio
//
//  Created by Shreyash Shah on 11/02/24.
//

import UIKit

protocol ConversionListCollectionViewDelegate: AnyObject {
    func conversionListCollectionView(_ conversionListCollectionView: ConversionListCollectionView, didSelectItemAt indexPath: IndexPath)
}

class ConversionListCollectionView: UICollectionView, CollectionViewCustomizing {
    struct Theme {
        static let backgroundColor: UIColor = .systemGroupedBackground
    }
    
    struct Metrics {
        static let interItemSpacing: CGFloat = 10
        static let idealItemWidth: CGFloat = 350
        static let fixedItemHeight: CGFloat = 120
    }
    
    weak var conversionItemsDelegate: ConversionListCollectionViewDelegate?
    var emptyStateView: UIView?

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = Metrics.interItemSpacing
        layout.minimumInteritemSpacing = Metrics.interItemSpacing
        layout.sectionInset = .zero
        super.init(frame: .zero, collectionViewLayout: layout)
        self.backgroundColor = Theme.backgroundColor
        self.delegate = self
        self.registerCells()
    }
    
        
    func checkIfEmpty() {
        if (0..<self.numberOfSections).map { self.numberOfItems(inSection: $0) }.reduce(0, +) == 0 {
            self.backgroundView = emptyStateView
        } else {
            self.backgroundView = nil
        }
    }
    
    override func reloadData() {
        super.reloadData()
        self.checkIfEmpty()
    }
    
    override func deleteItems(at indexPaths: [IndexPath]) {
        super.deleteItems(at: indexPaths)
        self.checkIfEmpty()
    }
    
    override func insertItems(at indexPaths: [IndexPath]) {
        super.insertItems(at: indexPaths)
        self.checkIfEmpty()
    }
    
    override func reloadItems(at indexPaths: [IndexPath]) {
        super.reloadItems(at: indexPaths)
        self.checkIfEmpty()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func registerCells() {
        self.register(ConversionItemCell.self)
    }
}

extension ConversionListCollectionView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard collectionView === self else { return .zero }
        
        let availableWidth = collectionView.frame.size.width
        let possibleCellsPerRow = availableWidth / Metrics.idealItemWidth
        let totalSpacing = floor(possibleCellsPerRow) * Metrics.interItemSpacing
        let possibleCellsPerRowWithSpacing = (availableWidth - totalSpacing) / Metrics.idealItemWidth

        let width: CGFloat
        
        /// - Note Assume 25% margin to shrink the cell size
        if possibleCellsPerRowWithSpacing < 1.75 {
            /// - Note If can't show two cells then we show one cell respecting available total width and spacing
            width = availableWidth - Metrics.interItemSpacing
        } else {
            width = (availableWidth - totalSpacing) / floor(possibleCellsPerRowWithSpacing)
        }

        return CGSize(width: width, height: Metrics.fixedItemHeight)
    }
}


extension ConversionListCollectionView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView === self else { return }

        conversionItemsDelegate?.conversionListCollectionView(self, didSelectItemAt: indexPath)
    }
}
