import Foundation
import Observation

/// Settings window state. Controls edit `draft`; changes are applied to the
/// core after a short debounce (text and number fields write the draft only
/// on commit). Values that fail validation (features.md "Options dialog
/// behaviour") are shown inline and kept out of the applied preferences
/// until fixed; everything else applies.
@Observable @MainActor
final class PreferencesModel {
    var draft = Preferences.qbtDefaults {
        didSet { if draft != oldValue { scheduleApply() } }
    }
    private(set) var applied = Preferences.qbtDefaults
    private(set) var isLoaded = false
    /// Error of the last apply (shown in the window's status line).
    private(set) var applyError: String?

    /// "Password:" field of the WebUI page; never stored in `draft`.
    var webUIPassword = ""
    private(set) var passwordMessage: PreferencesNotice?

    /// "Copy .torrent files to:" checkboxes (an empty path means off).
    var exportDirChecked = false
    var finishedExportDirChecked = false

    @ObservationIgnored private(set) var client: (any CoreClient)?
    /// Values kept while a "-1 = disabled" setting is unchecked.
    @ObservationIgnored var remembered: [String: Int64] = [:]
    @ObservationIgnored var rememberedRatio: Double?
    @ObservationIgnored var rememberedPaths: [String: String] = [:]
    @ObservationIgnored private var applyTask: Task<Void, Never>?
    static let debounce = Duration.milliseconds(500)

    var appInfo: (any AppInfoClient)? { client as? any AppInfoClient }

    // MARK: Loading

    func attach(_ client: (any CoreClient)?) async {
        guard let client else { return }
        self.client = client
        let prefs = await CoreCall.run { client.preferences() }
        applied = prefs
        draft = prefs
        syncCheckboxes()
        applyTask?.cancel()
        isLoaded = true
    }

    /// The core's preferences changed (WebAPI, another window, our own
    /// apply). Adopt them unless local edits are still pending.
    func coreDidChange(_ prefs: Preferences) {
        guard isLoaded, applyTask == nil, prefs != applied else { return }
        let hasUnappliedEdits = draft != applied
        applied = prefs
        if !hasUnappliedEdits {
            draft = prefs
            syncCheckboxes()
        }
        applyTask?.cancel()
        applyTask = nil
    }

    private func syncCheckboxes() {
        exportDirChecked = !draft.downloads.exportDir.isEmpty
        finishedExportDirChecked = !draft.downloads.exportDirFin.isEmpty
    }

    // MARK: Applying

    private func scheduleApply() {
        guard isLoaded else { return }
        applyTask?.cancel()
        applyTask = Task { [weak self] in
            try? await Task.sleep(for: Self.debounce)
            guard !Task.isCancelled else { return }
            await self?.applyNow()
        }
    }

    /// Applies the valid part of the draft immediately.
    func applyNow() async {
        defer { applyTask = nil }
        guard let client else { return }
        var prefs = sanitized()
        // Fields only the core changes (fetched tracker list, password hash,
        // interface name) are taken from its current state.
        let current = await CoreCall.run { client.preferences() }
        prefs.bittorrent.addTrackersUrlList = current.bittorrent.addTrackersUrlList
        prefs.webui.webUiPasswordPbkdf2 = current.webui.webUiPasswordPbkdf2
        prefs.advanced.currentInterfaceName = current.advanced.currentInterfaceName
        guard prefs != current else {
            applied = current
            applyError = nil
            return
        }
        let toApply = prefs
        do {
            try await CoreCall.run { try client.setPreferences(prefs: toApply) }
            applied = toApply
            applyError = nil
        } catch {
            applyError = error.userMessage
        }
    }

    /// Applies a change right away (API key buttons, banned IPs, …).
    func applyImmediately(_ change: (inout Preferences) -> Void) async {
        change(&draft)
        applyTask?.cancel()
        await applyNow()
    }

    /// The draft with invalid values replaced by the applied ones.
    func sanitized() -> Preferences {
        var prefs = draft
        if schedulerError != nil {
            prefs.speed.scheduleFromHour = applied.speed.scheduleFromHour
            prefs.speed.scheduleFromMin = applied.speed.scheduleFromMin
            prefs.speed.scheduleToHour = applied.speed.scheduleToHour
            prefs.speed.scheduleToMin = applied.speed.scheduleToMin
        }
        if usernameError != nil {
            prefs.webui.webUiUsername = applied.webui.webUiUsername
        }
        if passwordRequiredError != nil {
            prefs.webui.webUiEnabled = applied.webui.webUiEnabled
        }
        if alternativeWebUIError != nil {
            prefs.webui.alternativeWebuiEnabled = applied.webui.alternativeWebuiEnabled
            prefs.webui.alternativeWebuiPath = applied.webui.alternativeWebuiPath
        }
        return prefs
    }

    // MARK: Validation

    var schedulerError: String? {
        let speed = draft.speed
        guard speed.scheduleFromHour == speed.scheduleToHour, speed.scheduleFromMin == speed.scheduleToMin else { return nil }
        return String(localized: "The start time and the end time can't be the same.")
    }

    var usernameError: String? {
        let name = draft.webui.webUiUsername
        if name.count < 3 { return String(localized: "The WebUI username must be at least 3 characters long.") }
        if name.contains(":") { return String(localized: "The WebUI username must not contain a colon.") }
        return nil
    }

    /// Enabling the WebUI needs a password unless one is already stored.
    var passwordRequiredError: String? {
        guard draft.webui.webUiEnabled, draft.webui.webUiPasswordPbkdf2.isEmpty,
              applied.webui.webUiPasswordPbkdf2.isEmpty else { return nil }
        return String(localized: "The WebUI password must be at least 6 characters long.")
    }

    var alternativeWebUIError: String? {
        guard draft.webui.alternativeWebuiEnabled,
              draft.webui.alternativeWebuiPath.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return String(localized: "The alternative WebUI files location cannot be blank.")
    }

    // MARK: WebUI credentials

    /// Hashes and stores the typed password through the core.
    func commitWebUIPassword() async {
        let password = webUIPassword
        guard !password.isEmpty else { return }
        guard password.count >= 6 else {
            passwordMessage = PreferencesNotice(text: String(localized: "The WebUI password must be at least 6 characters long."), isError: true)
            return
        }
        guard let appInfo, let client else { return }
        do {
            let data = try JSONSerialization.data(withJSONObject: ["web_ui_password": password])
            let json = String(bytes: data, encoding: .utf8) ?? "{}"
            try await CoreCall.run { try appInfo.setPreferencesJson(json: json) }
            let current = await CoreCall.run { client.preferences() }
            applied.webui.webUiPasswordPbkdf2 = current.webui.webUiPasswordPbkdf2
            draft.webui.webUiPasswordPbkdf2 = current.webui.webUiPasswordPbkdf2
            webUIPassword = ""
            passwordMessage = PreferencesNotice(text: String(localized: "Password changed."), isError: false)
        } catch {
            passwordMessage = PreferencesNotice(text: error.userMessage, isError: true)
        }
    }

    /// Generates (or rotates) the WebUI API key: `qbt_` + 28 random characters.
    func rotateAPIKey() async {
        let key = APIKeyGenerator.generate()
        await applyImmediately { $0.webui.webUiApiKey = key }
    }

    func deleteAPIKey() async {
        await applyImmediately { $0.webui.webUiApiKey = "" }
    }
}
