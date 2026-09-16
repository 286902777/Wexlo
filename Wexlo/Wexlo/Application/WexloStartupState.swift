import Foundation

@MainActor
final class WexloStartupState {
    static let shared = WexloStartupState()

    private var hasLoadedInitialHome = false

    func claimInitialHomeLoad() -> Bool {
        guard !hasLoadedInitialHome else { return false }
        hasLoadedInitialHome = true
        return true
    }
}
