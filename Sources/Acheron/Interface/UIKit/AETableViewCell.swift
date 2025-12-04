//
//  AETableViewCell.swift
//  Acheron
//
//  Created by Joe Charlier on 12/4/25.
//

#if canImport(UIKit)

import UIKit

open class AETableViewCell: UITableViewCell {
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) { fatalError() }
}

#endif
