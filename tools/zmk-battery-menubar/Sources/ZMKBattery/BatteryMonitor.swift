import CoreBluetooth
import Foundation

/// One battery level exposed by the keyboard.
struct Reading {
    var label: String
    var level: Int?
    var updated: Date?
}

/// Reads every Battery Level characteristic the keyboard exposes.
///
/// A ZMK central with `CONFIG_ZMK_SPLIT_BLE_CENTRAL_BATTERY_LEVEL_PROXY=y` publishes two
/// Battery Service (0x180F) instances: its own, and an auxiliary one holding one Battery
/// Level (0x2A19) characteristic per peripheral, each tagged with a User Description (0x2901)
/// descriptor reading "Peripheral 0", "Peripheral 1", ... macOS's Bluetooth UI only ever
/// surfaces the first one, which is why this exists.
final class BatteryMonitor: NSObject {

    // MARK: - Configuration

    /// Case-insensitive substring used to pick the keyboard out of the connected BLE devices.
    static let deviceNameMatch = "cradio"

    /// The central half. `cradio_left` is the central in the upstream shield.
    static let centralLabel = "Left (central)"

    /// Peripheral halves, indexed the way ZMK's proxy indexes them ("Peripheral 0", ...).
    static let peripheralLabels = ["Right (peripheral)"]

    private static let batteryService = CBUUID(string: "180F")
    private static let batteryLevel = CBUUID(string: "2A19")
    private static let userDescription = CBUUID(string: "2901")

    /// How often to look for the keyboard while it is away (deep sleep, powered off).
    private static let retryInterval: TimeInterval = 10

    // MARK: - State

    var onUpdate: (() -> Void)?

    private(set) var isConnected = false
    private(set) var readings: [Reading] = []
    private(set) var bluetoothUnavailable = false

    private var manager: CBCentralManager?
    private var keyboard: CBPeripheral?
    private var slots: [ObjectIdentifier: Slot] = [:]
    private var retryTimer: Timer?

    /// A single Battery Level characteristic and everything we know about it.
    private final class Slot {
        let characteristic: CBCharacteristic
        /// 0 for the central, 1 + peripheral index otherwise. Sorts the menu.
        var order: Int
        var label: String
        var level: Int?
        var updated: Date?

        init(characteristic: CBCharacteristic, order: Int, label: String) {
            self.characteristic = characteristic
            self.order = order
            self.label = label
        }
    }

    // MARK: - Lifecycle

    func start() {
        manager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionShowPowerAlertKey: false]
        )
    }

    /// Look for the keyboard now, instead of waiting for the retry timer.
    func refresh() {
        connectIfPossible()
    }

    private func connectIfPossible() {
        guard let manager, manager.state == .poweredOn else { return }
        if let keyboard, keyboard.state == .connected || keyboard.state == .connecting { return }

        // The keyboard does not advertise while it is connected to the Mac as a HID device, so
        // scanning would never find it. This returns peripherals the system already has a link
        // to; connecting just attaches us to that existing link rather than opening a new one.
        //
        // Match on the name only: plenty of other things (mice, headphones) expose a battery
        // service, and connecting to the wrong one silently reports the wrong number.
        let candidates = manager.retrieveConnectedPeripherals(withServices: [Self.batteryService])
        let match = candidates.first {
            ($0.name ?? "").lowercased().contains(Self.deviceNameMatch)
        }

        guard let match else { return }
        keyboard = match
        match.delegate = self
        manager.connect(match)
    }

    private func startRetryTimer() {
        guard retryTimer == nil else { return }
        retryTimer = Timer.scheduledTimer(withTimeInterval: Self.retryInterval, repeats: true) {
            [weak self] _ in self?.connectIfPossible()
        }
    }

    private func rebuild() {
        readings = slots.values
            .sorted { ($0.order, $0.label) < ($1.order, $1.label) }
            .map { Reading(label: $0.label, level: $0.level, updated: $0.updated) }
        onUpdate?()
    }

    /// "Peripheral 0" -> 0. Anything else -> nil.
    private func peripheralIndex(fromDescription text: String) -> Int? {
        let digits = text.drop { !$0.isNumber }
        return Int(digits.prefix { $0.isNumber })
    }
}

// MARK: - CBCentralManagerDelegate

extension BatteryMonitor: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothUnavailable = central.state != .poweredOn
        if central.state == .poweredOn {
            startRetryTimer()
            connectIfPossible()
        } else {
            isConnected = false
            slots.removeAll()
        }
        rebuild()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        slots.removeAll()
        peripheral.discoverServices([Self.batteryService])
        rebuild()
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        keyboard = nil
        isConnected = false
        rebuild()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        // Expected whenever the keyboard deep-sleeps. Drop the readings rather than showing
        // numbers that are no longer being updated; the retry timer picks it back up.
        keyboard = nil
        isConnected = false
        slots.removeAll()
        rebuild()
    }
}

// MARK: - CBPeripheralDelegate

extension BatteryMonitor: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services ?? [] where service.uuid == Self.batteryService {
            peripheral.discoverCharacteristics([Self.batteryLevel], for: service)
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        for characteristic in service.characteristics ?? []
        where characteristic.uuid == Self.batteryLevel {
            // Provisional label and ordering: the User Description descriptor, read below,
            // replaces both once it arrives.
            let slot = Slot(
                characteristic: characteristic,
                order: slots.count,
                label: "Battery \(slots.count + 1)"
            )
            slots[ObjectIdentifier(characteristic)] = slot

            peripheral.discoverDescriptors(for: characteristic)
            peripheral.readValue(for: characteristic)
            peripheral.setNotifyValue(true, for: characteristic)
        }
        rebuild()
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverDescriptorsFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard let slot = slots[ObjectIdentifier(characteristic)] else { return }
        let description = (characteristic.descriptors ?? [])
            .first { $0.uuid == Self.userDescription }

        if let description {
            peripheral.readValue(for: description)
        } else {
            // No User Description means this is the central's own Battery Service.
            slot.order = 0
            slot.label = Self.centralLabel
            rebuild()
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor descriptor: CBDescriptor,
        error: Error?
    ) {
        guard
            descriptor.uuid == Self.userDescription,
            let characteristic = descriptor.characteristic,
            let slot = slots[ObjectIdentifier(characteristic)]
        else { return }

        let text: String
        switch descriptor.value {
        case let value as String: text = value
        case let value as Data: text = String(decoding: value, as: UTF8.self)
        default: return
        }

        if let index = peripheralIndex(fromDescription: text) {
            slot.order = index + 1
            slot.label = index < Self.peripheralLabels.count
                ? Self.peripheralLabels[index]
                : text
        } else {
            slot.label = text
        }
        rebuild()
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard
            let slot = slots[ObjectIdentifier(characteristic)],
            let byte = characteristic.value?.first
        else { return }

        slot.level = Int(byte)
        slot.updated = Date()
        rebuild()
    }
}
