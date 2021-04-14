//
//  BackgroundPond.swift
//  Acheron
//
//  Created by Joe Charlier on 4/14/21.
//  Copyright © 2021 Aepryus Software. All rights reserved.
//

import Foundation

open class BackgroundPond: Pond {
	var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
	let timedOut: ()->()

	public init(timedOut: @escaping ()->()) {
		self.timedOut = timedOut
		super.init()
	}

// Pond ============================================================================================
	override public func start() {
		backgroundTaskID = UIApplication.shared.beginBackgroundTask {
			self.timedOut()
			UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
			self.backgroundTaskID = .invalid
		}
		super.start()
	}
	override func onCompleted() {
		super.onCompleted()
		UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
		self.backgroundTaskID = .invalid
		print(" == [ Pond Background Complete ]\n")
	}
}
