// UnpluggedDeviceActivityMonitor — Device Activity Monitor Extension
//
// SETUP: In Xcode add this target manually:
//   File → New Target → Device Activity Monitor Extension → Name: UnpluggedDeviceActivityMonitor
//   Add this file to the new target.
//   Add the same App Group "group.com.thilothma.Unplugged" capability to the new target.
//   Add the Shared/ folder (AppGroupConstants.swift) to the new target.
//
// This extension runs as a separate process. It cannot call back into the main app
// directly. It communicates via shared App Group UserDefaults.
//
// Requires com.apple.developer.family-controls entitlement on BOTH the main target
// and this extension target.

import DeviceActivity
import Foundation

// Uncomment the entire class when the DeviceActivity framework is available
// (i.e., when the FamilyControls entitlement has been provisioned).

/*
@objc(DeviceActivityMonitorExtension)
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let defaults = UserDefaults(suiteName: "group.com.thilothma.Unplugged")!

    // Called at the end of each DeviceActivitySchedule interval (every minute by default).
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // Read total screen time from DeviceActivityReport and write to shared defaults.
        // DeviceActivityReport is only available via a DeviceActivityReportExtension target;
        // for simpler setups, increment a counter here each minute to approximate usage.

        let current = defaults.integer(forKey: "currentUsageSeconds")
        defaults.set(current + 60, forKey: "currentUsageSeconds")
        defaults.synchronize()
    }

    // Called when the threshold (daily limit) is reached.
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        let limit = defaults.integer(forKey: "dailyLimitSeconds")
        defaults.set(limit, forKey: "currentUsageSeconds")
        defaults.synchronize()
    }

    // Called at midnight to reset usage counters.
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        defaults.set(0, forKey: "currentUsageSeconds")
        defaults.set(Date(), forKey: "lastResetDate")
        defaults.synchronize()
    }
}
*/
