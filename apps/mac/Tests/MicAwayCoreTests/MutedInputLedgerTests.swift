import Testing
@testable import MicAwayCore

@Suite("MutedInputLedger")
struct MutedInputLedgerTests {
    @Test func restoreFindsARecreatedDeviceByUID() {
        // AirPods switching Bluetooth profile for a call can recreate the input
        // under a new AudioObjectID; the UID is what stays stable.
        var ledger = MutedInputLedger()
        ledger.recordMuted("airpods-uid")
        #expect(ledger.restorable(presentDeviceUIDs: ["airpods-uid", "builtin"]) == ["airpods-uid"])
    }

    @Test func absentDeviceStaysPendingUntilItReturns() {
        var ledger = MutedInputLedger()
        ledger.recordMuted("airpods-uid")
        #expect(ledger.restorable(presentDeviceUIDs: ["builtin"]).isEmpty)
        #expect(!ledger.isEmpty)
    }

    @Test func restoredDeviceLeavesTheLedger() {
        var ledger = MutedInputLedger()
        ledger.recordMuted("airpods-uid")
        ledger.recordRestored("airpods-uid")
        #expect(ledger.isEmpty)
    }

    @Test func ledgerRestoresOnlyWhatItMuted() {
        var ledger = MutedInputLedger()
        ledger.recordMuted("builtin")
        #expect(ledger.restorable(presentDeviceUIDs: ["builtin", "user-muted-usb"]) == ["builtin"])
    }

    @Test func ledgerSurvivesARelaunch() {
        var ledger = MutedInputLedger()
        ledger.recordMuted("builtin")
        #expect(MutedInputLedger(deviceUIDs: ledger.deviceUIDs) == ledger)
    }
}
