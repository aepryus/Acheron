//
//  AEViewController.swift
//  Acheron
//
//  Created by Joe Charlier on 4/28/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import UIKit

open class AEViewController: UIViewController {
    
    public init() { super.init(nibName: nil, bundle: nil) }
    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) { fatalError() }
    
    open func layoutRatio067() { layoutRatio056() }
    open func layoutRatio056() { layout375x667() }
    open func layoutRatio046() { layoutRatio056() }
    open func layoutRatio133() { layout1024x768() }
    open func layoutRatio143() { layoutRatio133() }
    open func layoutRatio152() { layoutRatio143() }
    
    // 0.67
    open func layout320x480() { layoutRatio067() }

    // 0.56
    open func layout320x568() { layoutRatio056() }
    open func layout375x667() {}
    open func layout414x736() { layoutRatio056() }

    // 0.46
    open func layout360x780() { layoutRatio046() }
    open func layout375x812() { layoutRatio046() }
    open func layout390x844() { layoutRatio046() }
    open func layout393x852() { layoutRatio046() }
    open func layout414x896() { layoutRatio046() }
    open func layout428x926() { layoutRatio046() }
    open func layout430x932() { layoutRatio046() }
    
    // 1.33
    open func layout1024x768() {}
    open func layout1080x810() { layoutRatio133() }
    open func layout1112x834() { layoutRatio133() }
    open func layout1366x1024() { layoutRatio133() }
    
    // 1.43
    open func layout1180x820() { layoutRatio143() }
    open func layout1194x834() { layoutRatio143() }
    
    // 1.52
    open func layout1133x744() { layoutRatio152() }
    
    open func layoutRatio() {
        switch Screen.ratio {
            case .rat067:   layoutRatio067()
            case .rat056:   layoutRatio056()
            case .rat046:   layoutRatio046()
            case .rat133:   layoutRatio133()
            case .rat143:   layoutRatio143()
            case .rat152:   layoutRatio152()
            case .other:    layoutRatio152()
        }
    }

    public func layout() {
        switch Screen.dimensions {
            case .dim320x480:   layout320x480()
            case .dim320x568:   layout320x568()
            case .dim375x667:   layout375x667()
            case .dim414x736:   layout414x736()
            case .dim360x780:   layout360x780()
            case .dim375x812:   layout375x812()
            case .dim390x844:   layout390x844()
            case .dim393x852:   layout393x852()
            case .dim414x896:   layout414x896()
            case .dim428x926:   layout428x926()
            case .dim430x932:   layout430x932()
            case .dim1024x768:  layout1024x768()
            case .dim1080x810:  layout1080x810()
            case .dim1112x834:  layout1112x834()
            case .dim1366x1024: layout1366x1024()
            case .dim1180x820:  layout1180x820()
            case .dim1194x834:  layout1194x834()
            case .dim1133x744:  layout1133x744()
            case .dimOther:     layoutRatio()
        }
    }
    
// UIViewController ================================================================================
    override open func viewWillLayoutSubviews() { layout() }
    override open func viewSafeAreaInsetsDidChange() {
        guard #available(iOS 11.0, *) else { return }
        super.viewSafeAreaInsetsDidChange()
        layout()
    }
}

#endif
