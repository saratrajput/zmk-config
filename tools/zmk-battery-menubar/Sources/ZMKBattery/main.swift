import AppKit

let app = NSApplication.shared
// Menu bar only: no Dock icon, no main window.
app.setActivationPolicy(.accessory)

let controller = StatusItemController()

app.run()
