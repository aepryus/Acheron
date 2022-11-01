//
//  ExpandableCell.swift
//  Acheron
//
//  Created by Joe Charlier on 3/13/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import UIKit

open class ExpandableCell: UITableViewCell {
    weak var expandableTableView: ExpandableTableView!
    private let baseView: UIView = UIView()
    
    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        clipsToBounds = true
        contentView.isUserInteractionEnabled = false
        
        superAddSubview(baseView)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        baseView.addGestureRecognizer(gesture)
    }
    public required init?(coder aDecoder: NSCoder) { fatalError() }
    
    var indexPath: IndexPath? {
        return expandableTableView.indexPathForRow(at: CGPoint(x: self.frame.origin.x, y: self.frame.origin.y))
    }
    public var expanded: Bool {
        return expandableTableView.expandedPath == indexPath
    }
    public var baseHeight: CGFloat {
        return baseView.height
    }
    
    func superAddSubview(_ view: UIView) {
        super.addSubview(view)
    }
    
// Events ==========================================================================================
    open func onWillExpand() {}
    open func onWillCollapse() {}
    @objc open func onTap() {
        expandableTableView.toggle(cell: self)
    }
    
// UIView ==========================================================================================
    override open func layoutSubviews() {
        var baseHeight: CGFloat = 0
        if let indexPath = indexPath {
            baseHeight = expandableTableView.expandableTableViewDelegate.expandableTableView(expandableTableView, baseHeightForRowAt: indexPath)
        } else {
            baseHeight = expandableTableView.baseHeight
        }
        baseView.frame = CGRect(x: 0, y: 0, width: width, height: baseHeight)
    }
    override open func addSubview(_ view: UIView) {
        baseView.addSubview(view)
    }
    override open func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        baseView.addGestureRecognizer(gestureRecognizer)
    }
    override open func sendSubviewToBack(_ view: UIView) {
        baseView.sendSubviewToBack(view)
    }
    override open var backgroundColor: UIColor? {
        set {
            baseView.backgroundColor = newValue
            // Apple is doing something weird under the covers here.
            // This is necessary to prevent them switching the color back to white.
            // jjc:3/13/19
            super.backgroundColor = newValue
        }
        get {return baseView.backgroundColor}
    }
}

#endif
