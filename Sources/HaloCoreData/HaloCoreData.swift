import os

private let subsystem = "com.halocommunications.HaloCoreData"

struct Log {
    static let utilities = OSLog(subsystem: subsystem, category: "HaloCoreData")
}

struct HaloCoreData {
    var text = "Hello, World!"
}
