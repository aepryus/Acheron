//
//  AESync.swift
//  Aexels
//
//  Created by Joe Charlier on 5/12/19.
//  Copyright © 2019 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import Foundation
import QuartzCore

public class AESync {
    public var onFire: (CADisplayLink,@escaping ()->())->() = {(link: CADisplayLink,complete: ()->()) in}
    
    public lazy var link: CADisplayLink = {
        let link = CADisplayLink(target: self, selector: #selector(fire))
        link.preferredFramesPerSecond = 60
        return link
    }()
    
    public init() {}
    deinit {
        link.invalidate()
    }
    
    public var running: Bool = false
    private var semaphore = DispatchSemaphore(value: 1)
    
    public func start() {
        guard !running else { return }
        running = true
        link.add(to: .main, forMode: Screen.iPad ? .common : .default)
    }
    public func stop() {
        guard running else { return }
        running = false
        semaphore.wait()
        link.remove(from: .main, forMode: Screen.iPad ? .common : .default)
        semaphore.signal()
    }
    
    @objc private func fire(link: CADisplayLink) {
        self.semaphore.wait()
        onFire(link) {
            self.semaphore.signal()
        }
    }
}

#endif
