//
//  BackgroundPond.swift
//  Acheron
//
//  Created by Joe Charlier on 4/14/21.
//  Copyright © 2021 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import UIKit

open class BackgroundPond: Pond {
    var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    let timedOut: ()->()

    public init(timedOut: @escaping ()->()) {
        self.timedOut = timedOut
        super.init()
    }

// Pond ============================================================================================
    public override func start(_ onComplete: @escaping ()->() = {}) {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            self.timedOut()
            UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
            self.backgroundTaskID = .invalid
        }
        super.start(onComplete)
    }
    override func onCompleted() {
        super.onCompleted()
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
        print(" == [ Pond Background Complete ]\n")
    }
}

#endif
