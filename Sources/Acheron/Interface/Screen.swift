//
//  Screen.swift
//  Acheron
//
//  Created by Joe Charlier on 10/15/20.
//  Copyright © 2020 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import UIKit

public class Screen {
    static let current: Screen = Screen()
    
    public enum Model {
        case iPhone, iPad, mac, other
    }
    public enum Dimensions {
        case dim320x480,                                                                                // 0.67 - original
             dim320x568, dim375x667, dim414x736,                                                        // 0.56 - iPhone 5
             dim360x780, dim375x812, dim390x844, dim393x852, dim402x874,dim414x896, dim428x926,
             dim430x932, dim440x956,                                                                    // 0.46 - iPhone X
             dim1024x768, dim1080x810, dim1112x834, dim1366x1024,                                       // 1.33 - original iPad
             dim1180x820, dim1194x834,                                                                  // 1.43 - iPad 11"
             dim1133x744,                                                                               // 1.52 - iPad Mini 6th gen
             dimOther
    }
    public enum Ratio: CaseIterable {
        case rat067, rat056, rat046, rat133, rat143, rat152, other
        
        var ratio: CGFloat {
            switch self {
                case .rat067: return 0.67
                case .rat056: return 0.56
                case .rat046: return 0.46
                case .rat133: return 1.33
                case .rat143: return 1.43
                case .rat152: return 1.52
                case .other:  return 1.00
            }
        }
    }
    
    let model: Model
    let dimensions: Dimensions
    let ratio: Ratio
    let width: CGFloat
    let height: CGFloat
    var s: CGFloat = 1
    let scaler: CGFloat
    
    init() {
        #if targetEnvironment(macCatalyst)
        
        if UIScreen.main.bounds.width <= 1800 {
            scaler = 1
        } else {
            scaler = 0.77
        }
    
        model = .mac
        dimensions = .dim1194x834
        ratio = .rat143
        width = UIApplication.shared.windows.first?.width ?? 1194 / scaler
        height = UIApplication.shared.windows.first?.height ?? 834 / scaler
        s = 790 / 748 / scaler
        
        #else

        scaler = 1
    
        if UIDevice.current.userInterfaceIdiom == .phone {
            model = .iPhone
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            model = .iPad
        } else {
            model = .other
        }
    
        let dw: CGFloat = UIScreen.main.bounds.size.width
        let dh: CGFloat = UIScreen.main.bounds.size.height
    
        let w: CGFloat = model == .iPhone ? min(dw, dh) : max(dw, dh)
        let h: CGFloat = model == .iPhone ? max(dw, dh) : min(dw, dh)
    
        if w == 320 && h == 480 { dimensions = .dim320x480; ratio = .rat067 }
    
        else if w == 320 && h == 568 { dimensions = .dim320x568; ratio = .rat056 }
        else if w == 375 && h == 667 { dimensions = .dim375x667; ratio = .rat056 }
        else if w == 414 && h == 736 { dimensions = .dim414x736; ratio = .rat056 }
    
        else if w == 360 && h == 780 { dimensions = .dim360x780; ratio = .rat046 }
        else if w == 375 && h == 812 { dimensions = .dim375x812; ratio = .rat046 }
        else if w == 390 && h == 844 { dimensions = .dim390x844; ratio = .rat046 }
        else if w == 393 && h == 852 { dimensions = .dim393x852; ratio = .rat046 }
        else if w == 402 && h == 874 { dimensions = .dim402x874; ratio = .rat046 }
        else if w == 414 && h == 896 { dimensions = .dim414x896; ratio = .rat046 }
        else if w == 428 && h == 926 { dimensions = .dim428x926; ratio = .rat046 }
        else if w == 440 && h == 956 { dimensions = .dim440x956; ratio = .rat046 }

        else if w == 1024 && h == 768 { dimensions = .dim1024x768; ratio = .rat133 }
        else if w == 1080 && h == 810 { dimensions = .dim1080x810; ratio = .rat133 }
        else if w == 1112 && h == 834 { dimensions = .dim1112x834; ratio = .rat133 }
        else if w == 1366 && h == 1024 { dimensions = .dim1366x1024; ratio = .rat133 }

        else if w == 1180 && h == 820 { dimensions = .dim1180x820; ratio = .rat143 }
        else if w == 1194 && h == 834 { dimensions = .dim1194x834; ratio = .rat143 }
    
        else if w == 1133 && h == 744 { dimensions = .dim1133x744; ratio = .rat152 }
    
        else {
            dimensions = .dimOther
            let r: CGFloat = w/h
            var minDelta: CGFloat = 9
            var closest: Ratio = .rat067
            Ratio.allCases.forEach {
                let delta: CGFloat = abs(1 - r/$0.ratio)
                if delta < minDelta {
                    minDelta = delta
                    closest = $0
                }
            }
            ratio = closest
        }
    
        width = w
        height = h
        
        setReferenceWidth(iPhone: 375, iPad: 768)

        #endif
    }
    
    func setReferenceWidth(iPhone: CGFloat, iPad: CGFloat) {
        if model == .iPhone { s = width / iPhone }
        else { s = height / iPad }
    }
    
// Static ==========================================================================================
    public static var model: Model { current.model }
    public static var dimensions: Dimensions { current.dimensions }
    public static var ratio: Ratio { current.ratio }
    public static var width: CGFloat { current.width }
    public static var height: CGFloat { current.height }
    public static var size: CGSize { CGSize(width: width, height: height) }
    public static var s: CGFloat { current.s }
    public static func s(_ x: CGFloat) -> CGFloat { round(x*s*scale)/scale }
    public static var scaler: CGFloat { current.scaler }
    
    public static var scale: CGFloat { UIScreen.main.scale}
    
    public static func setReferenceWidth(iPhone: CGFloat, iPad: CGFloat) { current.setReferenceWidth(iPhone: iPhone, iPad: iPad) }

    public static func snapToPixel(_ x: CGFloat) -> CGFloat { ceil(x*scale)/scale }
    
    public static var iPhone: Bool { current.model == .iPhone }
    public static var iPad: Bool { current.model == .iPad }
    public static var mac: Bool { current.model == .mac }
    
    public static var bounds: CGRect { CGRect(x: 0, y: 0, width: width, height: height) }
    public static var safeTop: CGFloat {
        guard let window = Screen.keyWindow else { fatalError() }
        return window.safeAreaInsets.top
    }
    public static var safeBottom: CGFloat {
        guard let window = Screen.keyWindow else { fatalError() }
        return window.safeAreaInsets.bottom
    }
    public static var safeLeft: CGFloat {
        guard let window = Screen.keyWindow else { fatalError() }
        return window.safeAreaInsets.left
    }
    public static var safeRight: CGFloat {
        guard let window = Screen.keyWindow else { fatalError() }
        return window.safeAreaInsets.right
    }
    
    public static var navBottom: CGFloat { Screen.safeTop + 44 }

    public static var keyWindow: UIWindow? {
        if #available(iOS 15.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })
        } else {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        }
    }
    public static var lightOrDark: UIUserInterfaceStyle { UITraitCollection.current.userInterfaceStyle }
}

#endif
