import AppKit

/// Menu bar item: both levels inline, details in the menu.
final class StatusItemController: NSObject {

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let monitor = BatteryMonitor()
    private var tickTimer: Timer?

    private static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    override init() {
        super.init()

        statusItem.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        monitor.onUpdate = { [weak self] in self?.render() }
        monitor.start()
        render()

        // Keeps the "Updated ..." line honest without any Bluetooth traffic.
        tickTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.render()
        }
    }

    private func render() {
        let readings = monitor.readings

        let levels = readings.isEmpty
            ? "--"
            : readings.map { $0.level.map(String.init) ?? "--" }.joined(separator: "/")
        statusItem.button?.title = "⌨ \(levels)"

        let menu = NSMenu()

        if monitor.bluetoothUnavailable {
            menu.addItem(disabledItem("Bluetooth is off"))
        } else if !monitor.isConnected {
            menu.addItem(disabledItem("\(BatteryMonitor.deviceNameMatch.capitalized) not connected"))
        } else if readings.isEmpty {
            menu.addItem(disabledItem("Reading battery levels…"))
        } else {
            for reading in readings {
                let level = reading.level.map { "\($0)%" } ?? "--"
                menu.addItem(disabledItem("\(reading.label)   \(level)"))
            }
            if let latest = readings.compactMap({ $0.updated }).max() {
                menu.addItem(.separator())
                let ago = Self.relative.localizedString(for: latest, relativeTo: Date())
                menu.addItem(disabledItem("Updated \(ago)"))
            }
        }

        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Check Now",
            action: #selector(refresh),
            keyEquivalent: "r"
        ).target = self
        menu.addItem(
            withTitle: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        statusItem.menu = menu
    }

    private func disabledItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    @objc private func refresh() {
        monitor.refresh()
    }
}
