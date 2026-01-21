//
//  AETableView.swift
//  Acheron
//
//  Created by Joe Charlier on 3/13/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import UIKit

open class AETableView: UITableView {
    public var minimumContentHeight: CGFloat? = nil
    private var requestedSize: CGSize = CGSize.zero
    
    public init() {
        super.init(frame: CGRect.zero, style: .plain)
        
        separatorStyle = .none
        tableFooterView = nil
        allowsSelection = false
    }
    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) { fatalError() }
    
// UITableView =====================================================================================
    public override var refreshControl: UIRefreshControl? {
        didSet {
            guard let refreshControl = refreshControl else { return }
            refreshControl.layer.zPosition = -1
        }
    }
    public override var contentSize: CGSize {
        set {
            requestedSize = newValue
            let newSize: CGSize
            if let minimumContentHeight = minimumContentHeight {
                newSize = CGSize(width: newValue.width, height: max(newValue.height, minimumContentHeight))
            } else {
                newSize = newValue
            }
            if super.contentSize != newSize { super.contentSize = newSize }
        }
        get { return requestedSize }
    }
}

#endif
