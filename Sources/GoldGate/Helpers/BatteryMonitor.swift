import Foundation
import IOKit
import IOKit.ps

// MARK: - Battery Monitor

@MainActor
public final class BatteryMonitor: ObservableObject {
    public static let shared = BatteryMonitor()

    @Published public var batteryPct: Int? = nil
    @Published public var isCharging: Bool = false
    @Published public var isPluggedIn: Bool = false
    @Published public var isCharged: Bool = false

    public var thermalStateString: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return "Nominal (Cool)"
        case .fair: return "Fair (Warm)"
        case .serious: return "Serious (Throttling)"
        case .critical: return "Critical (High Heat)"
        @unknown default: return "Nominal"
        }
    }

    public var powerSourceDescription: String {
        if isPluggedIn {
            return isCharging ? "Power Adapter (Charging)" : (isCharged ? "Power Adapter (Fully Charged)" : "Power Adapter")
        } else {
            return "Battery"
        }
    }

    private var timer: Timer?
    private var runLoopSource: CFRunLoopSource?

    public init() {
        refresh()
        startMonitoring()
    }

    deinit {
        timer?.invalidate()
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
    }

    func refresh() {
        // 1. Direct hardware query via AppleSmartBattery for 100% accurate percentage
        var hardwarePct: Int? = nil
        var hardwareCharging: Bool? = nil
        var hardwarePluggedIn: Bool? = nil
        var hardwareCharged: Bool? = nil

        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        if service != 0 {
            var props: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let dict = props?.takeRetainedValue() as? [String: Any] {
                
                var remainingCap: Double?
                var fullCap: Double?

                if let bData = dict["BatteryData"] as? [String: Any] {
                    if let rem = (bData["RemainingCapacity"] as? NSNumber)?.doubleValue {
                        remainingCap = rem
                    }
                    if let fcc = (bData["FullChargeCapacity"] as? NSNumber)?.doubleValue {
                        fullCap = fcc
                    }
                }

                if remainingCap == nil, let rem = (dict["RemainingCapacity"] as? NSNumber)?.doubleValue {
                    remainingCap = rem
                }
                if fullCap == nil, let fcc = (dict["FullChargeCapacity"] as? NSNumber)?.doubleValue {
                    fullCap = fcc
                }

                if let cur = (dict["CurrentCapacity"] as? NSNumber)?.intValue,
                   let maxCapVal = (dict["MaxCapacity"] as? NSNumber)?.intValue, maxCapVal > 0 {
                    if maxCapVal == 100 {
                        hardwarePct = cur
                    } else {
                        hardwarePct = Swift.max(0, Swift.min(100, Int(round((Double(cur) / Double(maxCapVal)) * 100.0))))
                    }
                } else if let rem = remainingCap, let fcc = fullCap, fcc > 0 {
                    hardwarePct = Swift.max(0, Swift.min(100, Int(round((rem / fcc) * 100.0))))
                }

                hardwareCharging = (dict["IsCharging"] as? Bool) ?? (((dict["IsCharging"] as? NSNumber)?.intValue ?? 0) == 1)
                hardwarePluggedIn = (dict["ExternalConnected"] as? Bool) ?? (((dict["ExternalConnected"] as? NSNumber)?.intValue ?? 0) == 1)
                hardwareCharged = (dict["FullyCharged"] as? Bool) ?? (((dict["FullyCharged"] as? NSNumber)?.intValue ?? 0) == 1)
            }
            IOObjectRelease(service)
        }

        // 2. IOPS power sources inspection (fallback or supplement)
        let snap = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let powerSourceType = IOPSGetProvidingPowerSourceType(snap)?.takeRetainedValue() as String? ?? ""
        let isOnBattery = (powerSourceType == kIOPSBatteryPowerValue)

        let list = IOPSCopyPowerSourcesList(snap).takeRetainedValue() as [CFTypeRef]
        var foundBattery = false

        for src in list {
            if let info = IOPSGetPowerSourceDescription(snap, src)?.takeUnretainedValue() as? [String: Any] {
                let type = info[kIOPSTypeKey] as? String ?? ""
                if list.count > 1 && !type.isEmpty && type != kIOPSInternalBatteryType {
                    continue
                }

                if let hw = hardwarePct {
                    self.batteryPct = hw
                } else {
                    let curCap = (info[kIOPSCurrentCapacityKey] as? NSNumber)?.intValue ?? (info[kIOPSCurrentCapacityKey] as? Int)
                    let maxCap = (info[kIOPSMaxCapacityKey] as? NSNumber)?.intValue ?? (info[kIOPSMaxCapacityKey] as? Int) ?? 100
                    if let cur = curCap {
                        if maxCap > 0 && maxCap != 100 {
                            self.batteryPct = max(0, min(100, Int(round((Double(cur) / Double(maxCap)) * 100.0))))
                        } else {
                            self.batteryPct = cur
                        }
                    }
                }

                let isChBool = hardwareCharging ?? ((info[kIOPSIsChargingKey] as? Bool) ?? (((info[kIOPSIsChargingKey] as? NSNumber)?.intValue ?? 0) == 1))
                let isChargedBool = hardwareCharged ?? ((info[kIOPSIsChargedKey] as? Bool) ?? (((info[kIOPSIsChargedKey] as? NSNumber)?.intValue ?? 0) == 1))
                let psState = info[kIOPSPowerSourceStateKey] as? String ?? ""
                let isExtPlugged = hardwarePluggedIn ?? (!isOnBattery && psState != kIOPSBatteryPowerValue)

                if isOnBattery || psState == kIOPSBatteryPowerValue || !isExtPlugged {
                    self.isCharging = false
                    self.isPluggedIn = false
                    self.isCharged = false
                } else {
                    self.isPluggedIn = true
                    self.isCharged = isChargedBool
                    let cap = self.batteryPct ?? 0
                    self.isCharging = isChBool && !isChargedBool && (cap < 100)
                }

                foundBattery = true
                break
            }
        }

        if !foundBattery {
            if let hw = hardwarePct {
                self.batteryPct = hw
            }
            if let plugged = hardwarePluggedIn {
                self.isPluggedIn = plugged
                self.isCharging = (hardwareCharging ?? false) && !(hardwareCharged ?? false) && ((self.batteryPct ?? 0) < 100)
                self.isCharged = hardwareCharged ?? false
            } else if isOnBattery {
                self.isCharging = false
                self.isPluggedIn = false
            }
        }

        NotificationCenter.default.post(name: NSNotification.Name("NexusBatteryStateChanged"), object: nil)
    }

    func startMonitoring() {
        // 1. Instant IOKit hardware notification for unplug / plug-in events
        if let source = IOPSNotificationCreateRunLoopSource({ _ in
            Task { @MainActor in
                BatteryMonitor.shared.refresh()
            }
        }, nil)?.takeRetainedValue() {
            self.runLoopSource = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }

        // 2. High-frequency 2-second heartbeat backup timer in commonModes
        timer?.invalidate()
        let t = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }
}
