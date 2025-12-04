//
//  UITextField+Acheron.swift
//  Acheron
//
//  Created by Joe Charlier on 11/11/25.
//

import UIKit

public extension UITextField {
    var pen: Pen {
        set {
            font = newValue.font
            textColor = newValue.color
            textAlignment = newValue.alignment
        }
        get { Pen(font: font, color: textColor, alignment: textAlignment) }
    }
}
