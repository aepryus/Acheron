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
    required public init?(coder aDecoder: NSCoder) { fatalError() }
    
// UITableView =====================================================================================
    override public var refreshControl: UIRefreshControl? {
        didSet {
            guard let refreshControl = refreshControl else { return }
            refreshControl.layer.zPosition = -1
        }
    }
    override public var contentSize: CGSize {
        set {
            requestedSize = newValue
            if let minimumContentHeight = minimumContentHeight {
                super.contentSize = CGSize(width: newValue.width, height: max(newValue.height, minimumContentHeight))
            } else {
                super.contentSize = newValue
            }
        }
        get { return requestedSize }
    }
}

#endif
