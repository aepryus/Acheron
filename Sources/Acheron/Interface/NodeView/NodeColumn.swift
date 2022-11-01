//
//  NodeColumn.swift
//  Acheron
//
//  Created by Joe Charlier on 6/10/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import UIKit

public class NodeColumn {
    let title: String?
    let token: String
    public var pen: Pen?
    public var format: (Any?)->(String)
    public var width: CGFloat = 80
    public var alignment: NSTextAlignment = .left
    
    static let defaultFormat: (Any?)->(String) = { (input: Any?)->(String) in
        return "\(input ?? "")"
    }
    
    public var createView: (NodeColumn)->(UIView) = { (column: NodeColumn) in
        let label = UILabel()
        if let pen = column.pen {label.pen = pen}
        label.textAlignment = column.alignment
        return label
    }
    public var loadView: (NodeColumn,UIView,Any?)->() = { (column: NodeColumn, view: UIView, value: Any?) in
        let label = view as! UILabel
        label.text = column.format(value)
    }
    
    public init(title: String? = nil, token: String, pen: Pen? = nil, format: ((Any?)->(String))? = nil) {
        self.title = title
        self.token = token
        self.pen = pen
        self.format = format != nil ? format! : NodeColumn.defaultFormat
    }
}

#endif
