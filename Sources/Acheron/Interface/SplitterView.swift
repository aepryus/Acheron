//
//  SplitterView.swift
//  Acheron
//
//  Created by Joe Charlier on 9/15/21.
//  Copyright © 2021 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import UIKit

public class SplitterView: UIView {
    public enum Split { case horizontal, vertical, both }

    let contentView: UIView
    let split: Split
    let radius: CGFloat

    var imageViews: [UIImageView] = []
    var rendered: Bool = false

    public init(contentView: UIView, split: Split, radius: CGFloat) {
        self.contentView = contentView
        self.split = split
        self.radius = radius
        super.init(frame: .zero)
        for _ in 0...(split == .both ? 8 : 2) {
            let imageView = UIImageView()
            imageViews.append(imageView)
//            addSubview(imageView)
        }
        addSubview(imageViews[0])
        addSubview(imageViews[1])
        addSubview(imageViews[2])
    }
    required init?(coder: NSCoder) { fatalError() }

    private func render() {
        UIGraphicsBeginImageContextWithOptions(contentView.bounds.size, false, 0)
        contentView.draw(contentView.bounds)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        let scale: CGFloat = UIScreen.main.scale

        switch split {
            case .horizontal:
                imageViews[0].image = UIImage(cgImage: (image.cgImage?.cropping(to: CGRect(x: 0, y: 0, width: radius*scale, height: height*scale)))!, scale: scale, orientation: .up)
                imageViews[1].image = UIImage(cgImage: (image.cgImage?.cropping(to: CGRect(x: radius*scale, y: 0, width: (contentView.width-2*radius)*scale, height: height*scale)))!, scale: scale, orientation: .up)
                imageViews[2].image = UIImage(cgImage: (image.cgImage?.cropping(to: CGRect(x: (contentView.width-radius)*scale, y: 0, width: radius*scale, height: height*scale)))!, scale: scale, orientation: .up)
                imageViews[0].left(width: radius, height: height)
                imageViews[1].left(dx: radius, width: width-2*radius, height: height)
                imageViews[2].right(width: radius, height: height)
            case .vertical:
                imageViews[0].top(width: width, height: radius)
                imageViews[1].top(dy: radius, width: width, height: height-2*radius)
                imageViews[2].bottom(width: width, height: radius)
            case .both:
                imageViews[0].topLeft(width: radius, height: radius)
        }
        contentView.removeFromSuperview()
    }

// UIView ==========================================================================================
    override public var frame: CGRect {
        didSet {
            guard width > radius*2 else { return }
            switch split {
                case .horizontal:
                    imageViews[0].left(width: radius, height: height)
                    imageViews[1].center(width: width-radius*2, height: height)
                    imageViews[2].right(width: radius, height: height)
                case .vertical:
                    imageViews[0].top(width: width, height: radius)
                    imageViews[1].top(dy: radius, width: width, height: height-2*radius)
                    imageViews[2].bottom(width: width, height: radius)
                case .both:
                    imageViews[0].topLeft(width: radius, height: radius)
            }
        }
    }
    override public func layoutSubviews() {
        if !rendered {
            contentView.frame = CGRect(x: 0, y: 0, width: 100, height: height)
            render()
            rendered = true
        }
    }
}

#endif
