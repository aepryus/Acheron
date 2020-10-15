//
//  Screen.swift
//  Acheron
//
//  Created by Joe Charlier on 10/15/20.
//  Copyright © 2020 Aepryus Software. All rights reserved.
//

import UIKit

public class Screen {
	static let current: Screen = Screen()
	
	public enum Model {
		case iPhone, iPad, other
	}
	public enum Dimensions {
		case dim320x480,
			 dim320x568, dim375x667, dim414x736,
			 dim360x780, dim375x812, dim390x844, dim414x896, dim428x926,
			 dim1024x768, dim1080x810, dim1112x834, dim1366x1024,
			 dim1194x834,
			 dimOther
	}
	public enum Ratio: CaseIterable {
		case rat067, rat056, rat046, rat133, rat143
		
		var ratio: CGFloat {
			switch self {
				case .rat067: return 0.67
				case .rat056: return 0.56
				case .rat046: return 0.46
				case .rat133: return 1.33
				case .rat143: return 1.43
			}
		}
	}
	
	let model: Model
	let dimensions: Dimensions
	let ratio: Ratio
	let width: CGFloat
	let height: CGFloat
	let s: CGFloat
	
	init() {
		if UIDevice.current.model == "iPhone" || UIDevice.current.model == "iPod touch" {
			model = .iPhone
		} else if UIDevice.current.model == "iPad" {
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
		else if w == 414 && h == 896 { dimensions = .dim414x896; ratio = .rat046 }
		else if w == 428 && h == 926 { dimensions = .dim428x926; ratio = .rat046 }

		else if w == 1024 && h == 768 { dimensions = .dim1024x768; ratio = .rat133 }
		else if w == 1080 && h == 810 { dimensions = .dim1080x810; ratio = .rat133 }
		else if w == 1112 && h == 834 { dimensions = .dim1112x834; ratio = .rat133 }
		else if w == 1366 && h == 1024 { dimensions = .dim1366x1024; ratio = .rat133 }

		else if w == 1194 && h == 834 { dimensions = .dim1194x834; ratio = .rat143 }
		
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
		
		s = model == .iPhone ? width / 375 : height / 768
	}
	
// Static ==========================================================================================
	public static var model: Model { current.model }
	public static var dimensions: Dimensions { current.dimensions }
	public static var ratio: Ratio { current.ratio }
	public static var width: CGFloat { current.width }
	public static var height: CGFloat { current.height }
	public static var s: CGFloat { current.s }
	
	public static var iPhone: Bool {
		return current.model == .iPhone
	}
	public static var iPad: Bool {
		return current.model == .iPad
	}
	
	public static var safeTop: CGFloat {
		guard let window = Screen.keyWindow else { fatalError() }
		return window.safeAreaInsets.top
	}
	public static var safeBottom: CGFloat {
		guard #available(iOS 11.0, *), let window = Screen.keyWindow else { return 0 }
		return window.safeAreaInsets.bottom
	}
	public static var safeLeft: CGFloat {
		guard #available(iOS 11.0, *), let window = Screen.keyWindow else { return 0 }
		return window.safeAreaInsets.left
	}
	public static var safeRight: CGFloat {
		guard #available(iOS 11.0, *), let window = Screen.keyWindow else { return 0 }
		return window.safeAreaInsets.right
	}
	
	public static var navBottom: CGFloat {
		return Screen.safeTop + 44
	}

	public static var keyWindow: UIWindow? {
		if #available(iOS 13.0, *) {
			return UIApplication.shared.windows.first { $0.isKeyWindow }
		} else {
			return UIApplication.shared.keyWindow
		}
	}
}

