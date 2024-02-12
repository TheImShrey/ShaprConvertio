//
//  CollectionView+Ext.swift
//  ShaprConvertio
//
//  Created by Shreyash Shah on 11/02/24.
//

import UIKit

protocol CollectionViewCellCustomizing where Self: UICollectionViewCell {
    static var reuseIdentifier: String { get }
    
}

extension CollectionViewCellCustomizing {
    static var reuseIdentifier: String {
        return String(describing: type(of: Self.self))
    }
}


protocol CollectionViewCustomizing where Self: UICollectionView {
    func registerCells()
    func register<CellType>(_ cellType: CellType.Type) where CellType: CollectionViewCellCustomizing
    func dequeueReusableCell<CellType>(of cellType: CellType.Type, for indexPath: IndexPath) -> CellType? where CellType: CollectionViewCellCustomizing

}

extension CollectionViewCustomizing {
    func register<CellType>(_ cellType: CellType.Type) where CellType: CollectionViewCellCustomizing {
        self.register(cellType, forCellWithReuseIdentifier: CellType.reuseIdentifier)
    }
    
    func dequeueReusableCell<CellType>(of cellType: CellType.Type, for indexPath: IndexPath) -> CellType? where CellType: CollectionViewCellCustomizing {
        return self.dequeueReusableCell(withReuseIdentifier: cellType.reuseIdentifier, for: indexPath) as? CellType
    }
}
