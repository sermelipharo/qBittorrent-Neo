# Settings window: information architecture proposal

Status: implemented in both apps (October 2026); §12 records what the
prototype showed and where the implementation differs. It applies to both qBit NeoRS
(`qbt_neo`, Rust core) and qBittorrent Neo (`qbittorrent_neo`, C++ core), which
share the Settings code in `apps/macos/QBTNeo/Features/Preferences/`.

Inputs: the current Settings pages, `docs/spec/preferences.md` (223 WebAPI
keys plus GUI-only keys), IINA's preferences up to 1.4.4, Transmission's
macOS Preferences window, Safari Settings, the `sindresorhus/Settings`
package and Apple's macOS Human Interface Guidelines.

---

## 1. Summary

* **Classic macOS settings window.** The pane switcher is a toolbar at the
  top, with an icon and a label for each pane, as in Safari and Transmission.
  It replaces the sidebar list. It is built with
  `Settings { TabView { … .tabItem { Label(…) } } }`. The window resizes to
  fit each pane, and the window title follows the selected pane.
* **Nine panes, ordered by task.** qBittorrent groups its settings by
  subsystem. These panes follow what users want to do:

  | # | Pane | SF Symbol (toolbar, outline) | What it answers |
  |---|---|---|---|
  | 1 | General | `gearshape` | How the app starts, quits, notifies and integrates with macOS |
  | 2 | Interface | `macwindow` | What the torrent list, sidebar, details and status bar look like |
  | 3 | Transfers | `arrow.up.arrow.down` | Where downloads go, how torrents are added, when seeding stops |
  | 4 | Speed | `speedometer` | How fast, and when to slow down |
  | 5 | Network | `network` | Whether peers can reach me, and how I find them |
  | 6 | Privacy | `hand.raised` | Encryption, VPN, proxy, IP blocking, app lock |
  | 7 | Remote | `globe` | Controlling the app from a browser (Web UI) |
  | 8 | Search & RSS | `text.magnifyingglass` | The two optional modules |
  | 9 | Advanced | `gearshape.2` | The "Show advanced settings" switch and the libtorrent tuning tables |

* **Three visibility tiers instead of one flat Advanced table.**
  *Basic* settings are always visible. *Advanced* settings appear on their own
  pane, in a clearly titled section, once **Show advanced settings** is on.
  This follows Safari's "Show features for web developers" and IINA's "Enable
  advanced settings". *Expert* settings (libtorrent internals) stay on the
  Advanced pane, with qBittorrent's labels and documentation links unchanged.
  Hiding a setting never changes or resets its value.
* **Plain-language labels and one-line explanations** for every basic
  setting. Where a qBittorrent label is already clear, it is kept so the
  imported translations still apply. New wording is listed in §9 in English
  and Russian.
* **Live status where it helps.** This proposal adds a connection-status
  indicator with the port, a Privacy summary row, a speed sparkline with the
  limit drawn in, the Web UI address with copy and open buttons, and a check
  mark when the app is the default for `.torrent` and magnet files.
* **Search stays.** It moves into the window toolbar, in the trailing search
  field of the classic System Preferences. Section 4.5 explains why.
* **Every preference stays reachable.** The table in §8 maps all 223 GET keys
  plus `web_ui_password`, and every GUI-only key shown in Settings today, to
  their new pane, section and tier. The script that builds the table checks
  that no key is missing or listed twice.
* **No third-party package.** The layout primitives are built natively in
  SwiftUI (§7).

---

## 2. Why change

What the current window (a faithful port of qBittorrent's Options dialog) gets
wrong for a typical Mac user:

1. **Pages follow libtorrent's subsystems, not user goals.** Privacy-related
   options are split across four pages:
   * encryption and anonymous mode on *BitTorrent*;
   * proxy, I2P and IP filter on *Connection*;
   * network-interface binding (the "VPN kill switch") as row 51 of
     *Advanced*;
   * quarantine and SSL options on *Advanced* as well.
2. **Advanced is a flat table of about 80 rows.** It mixes everyday choices
   with libtorrent socket tuning. Everyday choices there include notifications,
   "Move files to Trash", "Recheck on completion" and peer country flags.
3. **Behavior is a grab bag.** One page holds language, list colors, the
   Dock, power, log rotation, the status bar and file associations.
4. **Labels use engineering terms.** Examples are "Inhibit system sleep",
   "Default Torrent Management Mode", "Display torrent content and some
   options", "Bdecode token limit" and "[0: disabled]" suffixes. Labels can
   also be negative ("Do not start the download automatically").
5. **Nothing explains consequences.** For example, nothing says that
   anonymous mode only helps behind a proxy or VPN, or that "Ignore SSL errors"
   is dangerous. Status is also invisible: the user can't see whether the
   port is reachable.
6. **The sidebar layout is not what Mac users expect** in a utility's settings
   window. Safari, Transmission, Mail, Xcode, Finder and IINA up to 1.4 all
   use toolbar panes. The HIG describes that layout too (§3.4).

The goal is to make the common path obvious (save location, speed limits,
seeding, VPN and proxy, notifications) and keep every qBittorrent option one
switch away.

---

## 3. What we studied

### 3.1 IINA up to 1.4.4

Source: `iina/iina` at tag `v1.4.4` (`PreferenceWindowController.swift`,
`Pref*ViewController.swift`, `Base.lproj/Pref*.xib`, `CollapseView.swift`).

* **Pane set and order.** General (`gear`), UI (`macwindow`), Subtitles,
  Network, Control (`computermouse`), Key Bindings, Video/Audio, [Plugins],
  Advanced (`flask`), Utilities (`wrench.and.screwdriver`). The most common
  panes come first. Advanced and Utilities come last.
* **Sections inside a pane.** Each pane has three to six titled sections:
  Behavior, Playlist, Screenshots, History, and so on. The section title is a
  bold label in a left column. Controls sit in a right column, and labels end
  in a colon.
* **Plain, task-shaped labels.** Examples: "Resume last playback position",
  "Pause when machine goes to sleep", "Prevent screen saver from starting
  while playing", "Keep window open after playback finishes".
* **Inline secondary text** under the control it qualifies. Examples: "Exact
  seek is more precise but can cause lag and higher CPU usage.", "Still
  prevents system from sleeping.", "Requires restarting IINA to take
  effect.", "Default: 36000".
* **Illustrations that preview a choice.** The on-screen-controller layout
  pop-up swaps a picture (`osc_float`, top, bottom). The Control pane shows
  trackpad and toolbar drawings next to the gesture pop-ups.
* **Progressive disclosure.** `CollapseView` ties a checkbox or an
  "Advanced" disclosure button to a box of dependent options. "Initial window
  size", "Initial window position" and subtitle styling stay folded until
  needed. Dependent checkboxes are indented under their parent.
* **Advanced pane with a master switch.** The pane opens with "Enable
  advanced settings" and a warning. Every control below it is bound
  `enabled = enableAdvancedSettings`.
* **Actions live on their own pane.** Utilities collects one-off buttons:
  set as default app, clear caches, restore suppressed alerts. Each button
  has an explanation and inline "Cleared." feedback, so actions don't mix
  with settings.
* **Search.** A search field indexes every label and section title in every
  pane by walking the nibs at launch. Results appear in a popover as
  "Tab › Section › Label". Choosing a result opens the pane, unfolds the
  enclosing `CollapseView` and flashes a highlight mask over the control.
* **Defaults and window conventions.** Defaults are good, so most people
  never open the window. The window title tracks the current pane, as the
  HIG asks.

What made it good: few options per screen, the pane order matches how often
people need each pane, explanations sit beside controls instead of in
tooltips, and an expert never loses access.

### 3.2 Transmission (macOS)

Source: `transmission/transmission`, `macosx/PrefsController.mm` and
`macosx/Base.lproj/PrefsWindow.xib`.

* **Seven toolbar panes**, each with one SF Symbol and a one-word label:
  General `gearshape`, Transfers `arrow.up.arrow.down`, Groups `pin`,
  Bandwidth `speedometer`, Peers `person.2`, Network `network`, Remote
  `antenna.radiowaves.left.and.right`. The window frame is resized to each
  pane's height when switching (`setFrame:display:animate:`).
* **Column layout.** Right-aligned row labels ("Default location:",
  "Badge Dock icon with:", "Prompt user for:", "System sleep:") sit to the
  left of a column of checkboxes. The xib has 27 right-aligned labels. This is
  the classic Mac preferences grid.
* **Inner tabs for a large pane.** Transfers is split into
  **Adding** and **Management** tab-view items. That keeps the window short
  without adding toolbar items.
* **Concise wording with a one-line footnote.** Examples: "Ratio is amount
  uploaded to amount downloaded", "High connection limits might
  significantly impact system performance", "NAT traversal uses either
  NAT-PMP or UPnP", "When enabled Speed Limit overrides the global bandwidth
  limits".
* **Live status.** The Network pane shows "Port is open" or "Port is closed"
  with a status image and a progress spinner (`PortChecker`). The blocklist
  shows how many rules are loaded and when it was last updated. The Speed
  Limit mode is illustrated with the tortoise template image.
* **No hidden tier and no search.** Transmission avoids both by exposing far
  fewer options than qBittorrent (about 70 controls).

### 3.3 Safari Settings (current macOS)

* **Toolbar panes:** General, Tabs, AutoFill, Passwords, Search, Security,
  Privacy, Websites, Profiles, Extensions, Advanced. Outline SF Symbols
  appear above short labels.
* **Each pane is a centered column form.** Right-aligned labels end in a
  colon, controls are left-aligned, and there is generous vertical spacing.
  Groups are separated by space, not boxes. The window height animates to the
  selected pane, and its width stays constant.
* **Advanced handling.** Advanced is the last pane. Its checkbox **"Show
  features for web developers"** adds Developer and Feature Flags panes.
  Feature Flags is a long scrolling list. Expert options exist, but they
  can't confuse anyone who hasn't opted in.
* **No search field.** Safari has roughly 60 options, which fit into well-named
  panes.

### 3.4 Apple HIG (macOS)

From *Settings* (developer.apple.com/design/human-interface-guidelines/settings):

* "Aim to provide default settings that give the best experience to the
  largest number of people."
* "Minimize the number of settings you offer… too many settings can make the
  experience feel less approachable, while also making it hard to find a
  particular setting."
* "Respect people's systemwide settings and avoid including redundant
  versions of them." This affects language, appearance and notifications
  (§5.1).
* "When possible, prefer letting people modify task-specific options without
  going to your settings area." Toolbar style, column visibility, filters and
  "On downloads done" therefore stay in menus and views. They are not added
  to Settings.
* macOS specifically:
  * "a custom settings window contains a toolbar that includes buttons for
    switching between views — called panes";
  * "use a noncustomizable toolbar that remains visible and always indicates
    the active toolbar button";
  * "Dim a settings window's minimize and maximize buttons", because the
    window "accommodates the size of the current pane";
  * "Update the window's title to reflect the currently visible pane";
  * "Restore the most recently viewed pane".

From *Toggles*:

* Switches go only on settings that control a group. Checkboxes are for
  hierarchies, with indentation showing dependency.
* Radio buttons are for 2–5 exclusive choices. Use a pop-up button for more.

From *Disclosure controls*: "Place controls that people are most likely to
use at the top of the disclosure hierarchy… with more advanced functionality
hidden by default", and give the triangle a descriptive label such as
"Advanced Options".

From *Searching*: "Aim to make your app's content searchable through a single
location".

### 3.5 `sindresorhus/Settings` package

Package: `github.com/sindresorhus/Settings`, MIT, last commit November 2025.
About 1,160 lines of Swift in 11 files. Swift tools version 5.8,
`.macOS(.v10_13)`.

* **Window.** An AppKit `SettingsWindowController` with an
  `NSTabViewController` provides the toolbar or segmented-control pane
  switcher and animated window resizing.
* **Layout primitives.** In SwiftUI, `Settings.Container(contentWidth:)` and
  `Settings.Section(label:content:)` produce the classic layout:
  * a right-aligned label column whose width is the widest label (a
    `PreferenceKey` plus a custom `HorizontalAlignment`);
  * a left-aligned content column;
  * optional dividers between sections.

Our recommendation is in §7.

---

## 4. Window design

### 4.1 Pane switcher

* SwiftUI `Settings` scene containing a `TabView`. Each pane gets
  `.tabItem { Label(pane.title, systemImage: pane.symbol) }`. On macOS this
  renders as the standard non-customizable toolbar of pane buttons. The
  selected pane is highlighted, which meets the HIG requirement.
* Symbols are the **outline (default) variants** shown in the §1 table,
  monochrome, with no colored tiles. This matches Safari and Transmission.
* Selection is stored with `@AppStorage("Settings/LastPane")`, so the last
  pane is restored (HIG). The window title is the pane name, which the
  `Settings` scene does automatically.
* Nine panes fit in the toolbar at the 640 pt content width:
  * English labels are about 50–90 pt wide each.
  * Russian is the longest common locale. Its labels are "Основные",
    "Интерфейс", "Торренты", "Скорость", "Сеть", "Конфиденциальность",
    "Удаленный доступ", "Поиск и RSS" and "Дополнения". "Конфиденциальность"
    is about 120 pt. The total stays under 900 pt, and the toolbar grows the
    window width only if needed.

### 4.2 Pane layout

* Every pane except Advanced uses a centered **column form**:
  * right-aligned labels ending in a colon, with the controls column aligned
    across the whole pane;
  * section titles as bold labels in the label column, as in IINA;
  * sections separated by spacing and a thin divider.

  `Form { … }.formStyle(.columns)` gives the label alignment natively. Where
  a row needs a custom label or a control next to it, a small `SettingsGrid`
  helper (§7) supplies the shared label column.
* The window is at least 720 pt wide. Each pane's column (header, form,
  footer) is as wide as its content wants, up to the window minus two 20 pt
  margins, and is centered, so the margins left and right of it are equal
  (`SettingsColumn`). Checkbox titles wrap instead of being cut off. The
  height is the pane's ideal height, so
  the window resizes on every pane switch, as in Safari and Transmission.
  Panes are designed so the **basic tier fits without scrolling** on a
  13-inch display (≤ 640 pt tall).
* Turning on advanced settings may make a pane taller than the screen. In
  that case the pane scrolls, and the toolbar stays fixed.
* **Transfers** has an inner segmented control (`Picker(.segmented)`):
  **Adding · Files · Seeding & Queue**. This follows Transmission's
  Adding/Management tabs and keeps each segment short.
* **Advanced** is a scrolling grouped list (`Form.grouped`). It holds about
  60 rows, like Safari's Feature Flags pane.
* Dependent controls are indented under their parent checkbox and disabled
  while the parent is off. A long dependent group is hidden instead of
  disabled (for example proxy credentials or email server fields). Examples:
  * the scheduler times appear only when the schedule is on;
  * the proxy fields appear only when a proxy type other than None is
    chosen.
* Explanations are one line of `.secondary` footnote text under the control,
  never only a tooltip. Tooltips may repeat them for accessibility.
* Changes apply immediately, the standard Mac behavior. qBittorrent's OK /
  Cancel / Apply buttons are not used.

  Validation that qBittorrent runs on Apply happens inline when a field
  commits, with a red footnote under the field:
  * scheduler start equal to end;
  * Web UI user name of at least 3 characters, without `:`;
  * Web UI password of at least 6 characters;
  * an alternative Web UI enabled with an empty path.

### 4.3 Visibility tiers

| Tier | Meaning | Where it shows |
|---|---|---|
| **B** Basic | Most people may want to change it | Always visible |
| **R** Revealed | Depends on a basic parent | Shown, indented, when the parent is on or chosen |
| **D** Disclosure | Rare but related to a basic setting | Inside a collapsed `DisclosureGroup` titled with what it holds ("More confirmations", "Bind to address", "Tunnel settings") |
| **A** Advanced | For power users; plain wording still applies | In a section named "Advanced" or with a specific title at the bottom of its pane. Visible only while **Show advanced settings** is on |
| **X** Expert | libtorrent and internal tuning | Advanced pane only, also behind the switch. qBittorrent wording and `(?)` documentation links kept |
| **H** | API-only or derived key | Covered by another control; no widget of its own |
| **P** | Platform- or build-specific | Not shown on macOS or libtorrent 2 (unchanged from today) |

Rules:

* **Show advanced settings** is a new GUI-only key, `Settings/ShowAdvanced`,
  default `false`. It is a switch at the top of the Advanced pane with this
  footnote: "Adds advanced sections to every pane and shows libtorrent tuning
  below. Hidden settings keep working."
* Hiding never resets a value.
* When any hidden A or X value differs from its default, the bottom of that
  pane shows: "2 advanced settings on this pane are changed. Show". This
  stops a hidden custom value from becoming a mystery.
* Search always covers all tiers. Picking an A or X result reveals that
  section for the session without flipping the stored switch, scrolls to it
  and highlights it, the way IINA unfolds a `CollapseView`.

### 4.4 Illustrations and live status

These are small, native and cheap. Each one reads data the app already has.
None of them uses a per-pane timer while the window is closed.

| Where | What |
|---|---|
| General › Default App | A green `checkmark.circle.fill` with "qBit NeoRS opens .torrent files" when the app is the handler. Otherwise a "Make Default" button. |
| General › Notifications | A button "Notification Settings…" that opens System Settings › Notifications for the app (HIG: respect system settings). |
| Speed (top) | A 60-second download/upload sparkline from the existing speed history, with the current limit as a dashed line. The tortoise symbol marks the alternative limits section and its "Active now" state. |
| Transfers › Seeding Limits | A footnote: "Ratio = uploaded ÷ downloaded. 1.0 means you shared as much as you took." |
| Network › Status | A colored dot with text: green "Connected — peers can reach you", yellow "Firewalled — only outgoing connections work", red "Offline". The current listening port and external IP come from session status. An optional "Test Port" button is described in §11. |
| Privacy (top) | A one-line summary: "Encryption: preferred · VPN binding: off · Proxy: none · IP filter: off". Each item links to its section. |
| Privacy › IP Filtering | "12,345 rules loaded" after a reload. The result exists already. |
| Remote (top) | The live URL (`http://192.168.1.5:8080`) with Copy and Open in Browser buttons, plus the server state (running / failed with reason). `WebUIStatusRow` exists already. |
| Remote › HTTPS | A validity symbol next to the certificate and key paths (qBittorrent has one). |

### 4.5 Search: keep it, in the toolbar

Safari has no search because it has about 60 options. We have about 260
settings, and the advanced tier hides two thirds of them, so search is what
keeps expert options findable without the tier being in the way. That is the
argument IINA made, and classic System Preferences (macOS ≤ 12) worked the
same way, with toolbar panes and a search field at the trailing edge.

* **Placement.** A search field at the trailing end of the Settings toolbar,
  focused with ⌘F. It must be checked in a prototype (§10, step 2) that a
  SwiftUI `TabView` settings toolbar accepts a trailing search item. If it
  doesn't, the field becomes a `.searchable` toolbar item through a thin
  `NSToolbar` delegate wrapper. The search field must not become a pane.
* **Results.** A popover lists matches as "Pane › Section › Setting". Choosing
  one switches pane and inner segment, reveals the tier, scrolls to the row
  and highlights it for one second. `SettingAnchor` already does this.
* **Matching.** Each catalog entry (§10) carries search keywords, so a user
  can find a setting without knowing qBittorrent's name for it:
  * "VPN", "kill switch" and "interface" find the network interface setting;
  * "turtle" and "slow mode" find the alternative limits;
  * "ratio" finds the seeding limits;
  * "port forwarding" finds the UPnP options.

  Power users can also type the WebAPI key (`max_connec`, `anonymous_mode`)
  or the ini key.

---

## 5. Pane-by-pane tree

Notation: **Section** (priority order, top to bottom). Each row gives the
label, `[tier]`, the key, and the explanation (↳, shown under the control).
Labels in *italics* are new wording (§9). All other labels keep qBittorrent's
text.

### 5.1 General — `gearshape`

1. **Language**
   * Language: `[B]` `locale`. The first item is "System Default", which
     stores `""`.
     ↳ *Changes take effect after relaunch.*
2. **Startup**
   * Open qBit NeoRS at login `[B]` (SMAppService)
   * *At startup, show window:* Normal / Minimized `[B]` (`GUI/StartUpWindowState`)
   * *Start with all transfers paused* `[A]` (`BitTorrent/Session/StartPaused`)
     ↳ *Nothing downloads or uploads until you resume.*
3. **Default App**. Two rows, each a checkmark status or a "Make Default"
   button:
   * *.torrent files* `[B]`
   * *Magnet links* `[B]`

   ↳ "Once set, the default application can be changed back in Finder's Get
   Info window." This footnote exists already.
4. **Dock & Menu Bar**
   * Show speed in Dock `[B]`
   * Show qBit NeoRS in menu bar `[B]`
5. **Notifications**
   * Display notifications `[B]` (`GUI/Notifications/Enabled`)
     ↳ *When a download finishes or a file can't be written.*
     * *Also when a torrent is added* `[R]`
   * Button *Notification Settings…* (opens System Settings)
   * *Send an email when a download finishes* `[B]` (`mail_notification_enabled`)
     * From:, To:, SMTP server:, This server requires a secure connection
       (SSL), Authentication, Username:, Password: `[R]`
     * Button "Send test email" `[R]`
6. **Power Management**
   * *Keep Mac awake while downloading* `[B]`
   * *Keep Mac awake while seeding* `[B]`
     ↳ *The display can still sleep.*
7. **Confirmations**
   * *Ask before deleting torrents* `[B]` (`confirm_torrent_deletion`)
   * *Ask before quitting while torrents are active* `[B]`
   * *Show a countdown before quitting when downloads finish* `[B]`
   * Disclosure *More confirmations* `[D]`:
     * *Ask before rechecking torrents* (`confirm_torrent_recheck`)
     * *Ask before removing all tags*
     * *Ask before removing a tracker from all torrents*
     * *Delete files by default when removing torrents*
       (`delete_torrent_content_files`). This key gets a widget for the first
       time; until now only the Remove dialog's "Remember choice" set it.
8. **Updates**
   * *Check for updates automatically* `[B]`

The color scheme is not on this pane. It is on Interface (§5.2), where people
look for appearance.

### 5.2 Interface — `macwindow`

1. **Appearance**
   * Color scheme: System / Light / Dark `[B]`
     ↳ *System follows your Mac's appearance.*
2. **Torrent List**
   * Use alternating row colors `[B]`
   * *Color by state:* None / Whole row / Name only / Progress bar only / Status only `[B]`
     (one exclusive choice replacing qBittorrent's two dependent checkboxes; the old values
     migrate once: colored text → Whole row, otherwise None)
   * Hide zero and infinity values `[B]`
     * scope: Always / Stopped torrents only `[R]`
3. **Action on double-click**
   * Downloading torrents: `[B]`
   * Completed torrents: `[B]`
4. **Sidebar**
   * *Hide empty status filters* `[B]`
   * Use separate "Tracker status" filter `[B]`
   * *Show tracker icons* `[B]`
     ↳ *Downloads each tracker website's icon.*
5. **Torrent Details**
   * *Show speed graphs* `[B]`
   * *Drag files from the Content tab to Finder* `[B]`
6. **Status Bar**
   * *Show free disk space* `[B]`
   * *Show external IP address* `[B]`
7. **Peers List** `[A]`
   * *Show peer countries* (`resolve_peer_countries`)
     ↳ *Uses a free IP-to-country database downloaded monthly.*
   * *Show peer host names* (`resolve_peer_host_names`)
     ↳ *Looks up every peer's name; adds network traffic.*
8. **Window** `[A]`
   * *Update interval:* (`refresh_interval`)
     ↳ *How often lists and speeds refresh. Lower values use more CPU.*
   * *Window title suffix:* (`app_instance_name`)
     ↳ *Helps tell several copies of the app apart.*

### 5.3 Transfers — `arrow.up.arrow.down`

Inner segments: **Adding · Files · Seeding & Queue**.

**Adding**

1. **Save Location**
   * *Save downloads to:* `[B]` (`save_path`)
   * *Keep incomplete downloads in:* `[B]` (`temp_path_enabled` + `temp_path`)
     ↳ *Finished downloads move to the save location.*
2. **When adding a torrent**
   * *Show options when adding a torrent* `[B]` (`AddNewTorrentDialog/Enabled`)
     * Bring torrent dialog to the front `[R]`
   * *Start downloads automatically* `[B]` (inverse of `add_stopped_enabled`)
     * Torrent stop condition: `[A]`
   * Torrent content layout: `[A]`. Options are reworded: *Keep original*,
     *Always create subfolder*, *Never create subfolder*.
   * Add to top of queue `[A]`
   * *Remember recent save locations:* `[A]`
     (`AddNewTorrentDialog/SavePathHistoryLength`)
3. **Watched Folders** `[B]`. The list with Add…, Options… and Remove
   (`watched_folders.json`, `scan_dirs`).
   ↳ *.torrent files saved into these folders are added automatically.*
4. **When adding a duplicate torrent** `[A]`
   * Merge trackers to existing torrent
   * Ask to merge trackers for manually added torrent
5. **.torrent Files** `[A]`
   * Delete .torrent files afterwards, with "Also when addition is
     cancelled" (`auto_delete_mode`). The data-loss warning is kept.
   * Copy .torrent files to:
   * Copy .torrent files for finished downloads to:
6. **Extra Trackers** `[A]`
   * Automatically append these trackers to new downloads: (text)
   * Automatically append trackers from URL to new downloads: URL and
     fetched list

**Files**

1. **Removing Torrents**
   * *When removing a torrent with its files:* Move files to trash (if
     possible) / Delete files permanently `[B]`
     (`torrent_content_remove_option`)
2. **Files on Disk** `[A]`
   * Pre-allocate disk space for all files
   * Append .!qB extension to incomplete files
   * Keep unselected files in ".unwanted" folder
   * *Verify files again when a download finishes* (`recheck_completed_torrents`)
   * *Offer to add .torrent files found inside downloads*
     (`DisableRecursiveDownload`, inverted)
   * Excluded file names, with the editor in a disclosure and qBittorrent's
     wildcard help text as the footnote
3. **Categories & Automatic Mode** `[A]`
   * Default Torrent Management Mode:
     ↳ *Automatic: the category decides the save location.*
   * When Torrent Category changed:
   * When Default Save/Incomplete Path changed:
   * When Category Save Path changed:
   * Use Category paths in Manual Mode
4. **Run a Program** `[A]`
   * Run on torrent added: (command)
   * Run on torrent finished: (command)
   * Disclosure with the `%N %L %G …` parameter help

**Seeding & Queue**

1. **Seeding Limits** `[B]`
   * When ratio reaches (value)
   * When total seeding time reaches (min)
   * When inactive seeding time reaches (min)
   * then: Stop / Remove / Remove with files / Super seeding
     (`max_ratio_act`)
   * ↳ *Ratio = uploaded ÷ downloaded. 1.0 means you shared as much as you
     took.*
2. **Queue**
   * *Limit the number of active torrents* `[B]` (`queueing_enabled`)
     * Maximum active downloads:, uploads:, torrents: `[R]`
     * Do not count slow torrents in these limits `[A]`, with thresholds and
       timer `[A]`
3. **Checking** `[A]`
   * Maximum active checking torrents:

### 5.4 Speed — `speedometer`

1. *(Header)* sparkline, current mode and the alternative-limits toggle. This
   is runtime state, not a preference.
2. **Global Rate Limits** `[B]`
   * Download:, Upload: (∞ when 0)
3. **Alternative Rate Limits** `[B]` (tortoise symbol)
   * Download:, Upload:
   ↳ *Turn on with the tortoise button in the toolbar or status bar, or on a
   schedule.*
4. **Schedule**
   * *Use alternative limits on a schedule* `[B]` (`scheduler_enabled`)
     * From:, To:, When: `[R]`
5. **Rate Limits Settings** `[A]`
   * Apply rate limit to µTP protocol
   * Apply rate limit to transport overhead
   * Apply rate limit to peers on LAN

### 5.5 Network — `network`

1. **Status** (live): connection dot, listening port, external IP and an
   optional Test Port button.
2. **Listening Port** `[B]`
   * Port used for incoming connections: with a "Random" button
   * Use UPnP / NAT-PMP port forwarding from my router
     ↳ *Lets peers reach you through your router.*
3. **Finding Peers** `[B]`
   * Enable DHT (decentralized network) to find more peers
   * Enable Peer Exchange (PeX) to find more peers
   * Enable Local Peer Discovery to find more peers
   * ↳ *Private torrents never use these.*
4. **Protocol & Limits** `[A]`
   * Peer connection protocol:
   * Global maximum number of connections:, per torrent:, upload slots,
     upload slots per torrent
   * Reannounce to all trackers when IP or port changed
   * *Accept SSL torrents on port:* (`ssl_enabled`, `ssl_listen_port`). This
     is new; the keys were API-only until now.

### 5.6 Privacy — `hand.raised`

1. *(Summary row)*, §4.4.
2. **Encryption & Anonymity** `[B]`
   * Encryption mode: Allow / Require / Disable
     ↳ *Require: connect only to peers that encrypt traffic. Fewer peers.*
   * Enable anonymous mode
     ↳ *Hides client details from peers and trackers. Use with a proxy or VPN.*
     The "(More information)" link is kept.
3. **VPN Protection** `[B]`
   * *Use only this network interface:* Any / list of interfaces
     (`current_network_interface`)
     ↳ *Pick your VPN's interface so transfers stop if the VPN disconnects.*
   * Disclosure *Bind to address* `[D]`
     * Optional IP address to bind to (`current_interface_address`)
4. **Proxy Server** `[B]`
   * Type: (None) / SOCKS4 / SOCKS5 / HTTP
     * Host:, Port: `[R]`
     * Authentication, Username:, Password: with "The password is saved
       unencrypted" `[R]`
     * Perform hostname lookup via proxy `[R]`
     * Use proxy for BitTorrent purposes, Use proxy for peer connections, for
       RSS, for general purposes `[R]`
     * ↳ SOCKS4 warning kept: "Some functions are unavailable with the chosen
       proxy type!"
5. **IP Filtering** `[B]`
   * Filter path (.dat, .p2p, .p2b): with reload and rule count
   * Apply to trackers
   * Manually banned IP addresses…
6. **App Lock** `[B]`
   * *Lock password:* Set Password… / Change… / Clear…
     ↳ *View › Lock hides the window until the password is entered.*
7. **Downloaded Files** `[B]`
   * *Quarantine downloaded files* (`mark_of_the_web`)
     ↳ *macOS checks apps from torrents before they first open.*
8. **I2P (experimental)** `[A]`
   * Host:, Port:, Mixed mode
   * Disclosure *Tunnel settings* `[D]`: I2P inbound/outbound quantity,
     inbound/outbound length
9. **Protection** `[A]`
   * Validate HTTPS tracker certificates
   * Server-side request forgery (SSRF) mitigation
   * Disallow connection to peers on privileged ports
   * Support internationalized domain name (IDN)
   * Ignore SSL errors
     ↳ *Unsafe: accepts forged certificates for RSS, updates and downloads.*
     Shown in red when on.

### 5.7 Remote — `globe`

1. **Header switch:** *Allow control from a web browser* `[B]`
   (`Preferences/WebUI/Enabled`), with live URL, Copy and Open (§4.4). All
   rows below are `[R]` on this switch.
2. **Address** `[R]`
   * IP address:, Port:, Use UPnP / NAT-PMP to forward the port from my router
3. **Sign-In** `[R]`
   * Username:, Password:, API key (copy, generate, rotate, delete)
     ↳ *Without a password, a temporary one is generated at each launch and
     written to the log.*
4. **HTTPS** `[R]`
   * Use HTTPS instead of HTTP, with Certificate: and Key: and validity
     icons
5. **Access Rules** `[A]`
   * Bypass authentication for clients on localhost
   * Bypass authentication for clients in whitelisted IP subnets, with IP
     subnet whitelist…
     ↳ *Anyone on these networks gets full control without a password.*
   * Ban client after consecutive failures:, ban for:, Session timeout:
6. **Alternative Web UI** `[A]`
   * Use alternative WebUI, with Files location: and the list link
7. **Security** `[A]`
   * Enable clickjacking protection
   * Enable Cross-Site Request Forgery (CSRF) protection
   * Enable cookie Secure flag (requires HTTPS or localhost connection)
   * Enable Host header validation, with Server domains:
   * Add custom HTTP headers
   * Enable reverse proxy support, with Trusted proxies list:
8. **Dynamic DNS** `[A]`
   * Update my dynamic domain name: Service, Register, Domain name:,
     Username:, Password:

Every bypass, CSRF, Host-validation and cookie toggle keeps its current
default and warning footnote. Moving them is a layout change only, so the
web-feature security review rules still apply unchanged.

### 5.8 Search & RSS — `text.magnifyingglass`

1. **Search**
   * *Show search engine* `[B]` (`Preferences/Search/SearchEnabled`, the same
     key as View › Search Engine)
   * Button "Search plugins…"
   * *Reopen search tabs at launch* `[B]` (Store opened tabs)
     * Also store search results `[R]`
   * History length `[A]`
   * *Python executable:* `[A]` (`python_executable_path`)
     ↳ *Leave empty to detect automatically.*
2. **RSS**
   * *Show RSS reader* `[B]` (`GUI/RSSWidget/Enabled`, the same key as
     View › RSS Reader)
   * Enable fetching RSS feeds `[B]`
     * Feeds refresh interval: `[B]`
     * Same host request delay:, Maximum number of articles per feed: `[A]`
   * Enable auto downloading of RSS torrents `[B]`, with "Edit auto
     downloading rules…"
3. **RSS Smart Episode Filter** `[A]`
   * Download REPACK/PROPER episodes
   * Filters:

### 5.9 Advanced — `gearshape.2`

1. *Show advanced settings* (switch) `[B]`, with the footnote from §4.3.
   Everything below is visible only while it is on.
2. **Logs & Diagnostics** `[X]`
   * Log Files group (enabled, Save path:, Backup the log file after:,
     Delete backup logs older than:)
   * Log performance warnings
3. **Data & Recovery** `[X]`
   * Resume data storage type (requires restart)
   * Save resume data interval [0: disabled]
   * Save statistics interval [0: disabled]
   * BitTorrent session shutdown timeout [-1: unlimited]
4. **Disk & Memory** `[X]`
   * Asynchronous I/O threads
   * Hashing threads
   * File pool size
   * Outstanding memory when checking torrents
   * Disk queue size
   * Disk IO type (requires restart)
   * Disk IO read mode
   * Disk IO write mode
   * Use piece extent affinity
5. **Network Tuning** `[X]`
   * Outgoing connections per second
   * Socket send buffer size, Socket receive buffer size
   * Socket backlog size
   * Outgoing ports (Min/Max)
   * UPnP lease duration
   * DSCP
   * μTP-TCP mixed mode algorithm
   * Internal hostname resolver cache expiry interval
   * Allow multiple connections from the same IP address
   * Send upload piece suggestions
   * Send buffer watermark, low watermark and factor
6. **Peers & Uploading** `[X]`
   * Upload slots behavior
   * Upload choking algorithm
   * Peer turnover disconnect percentage, threshold and interval
   * Maximum outstanding requests to a single peer
7. **Trackers & Announcing** `[X]`
   * Always announce to all trackers in a tier
   * Always announce to all tiers
   * IP address reported to trackers
   * Port reported to trackers
   * Max concurrent HTTP announces
   * Stop tracker timeout
8. **DHT** `[X]`
   * DHT bootstrap nodes
9. **Safety Limits** `[X]`
   * .torrent file size limit
   * Bdecode depth limit
   * Bdecode token limit
10. **Embedded Tracker** `[X]`
    * Enable embedded tracker
    * Embedded tracker port
    * Enable port forwarding for embedded tracker

Rows on this pane keep qBittorrent's exact labels, including the bracketed
`[0: disabled]` hints. They also keep their `(?)` links to the libtorrent or
qBittorrent wiki. Two documentation links head the pane: "qBittorrent
options" and "libtorrent settings".

### 5.10 What deliberately stays out of Settings

The HIG says task-specific options belong in context. These stay in menus and
views, unchanged:

* toolbar and status-bar visibility, filters sidebar, speed in title bar;
* log view and message types;
* "On Downloads Done" (Tools menu);
* regex filter;
* column layout;
* speed graph period and series;
* the Add dialog's "Remember last save path";
* the Torrent Creator fields;
* disabled search engines (Search plugins window);
* cookies (Tools › Manage Cookies).

Search and RSS visibility appear in both the View menu and §5.8 because they
also gate whole sections of Settings.

---

## 6. Ordering rationale

* **Order of the panes in the toolbar.**
  * General comes first, Advanced last (HIG, IINA, Safari, Transmission).
  * Panes in between run from local to network to optional modules:
    Interface → Transfers → Speed → Network → Privacy → Remote → Search & RSS.
  * Transfers sits next to Speed because together they answer "what does the
    app do with my disk and bandwidth".
* **Order of sections within a pane.** Sections run from most to least often
  changed. The advanced sections always come last, so turning the switch on
  only appends content and never moves anything a user has already learned.
* **Grouping.**
  * Speed limits and the scheduler share one pane, since the schedule only
    switches between the two sets of limits.
  * Encryption, anonymity, VPN binding, proxy, I2P and IP filter share
    Privacy.
  * Notifications, email and the Dock live together on General.
  * Run-a-program lives with Files on Transfers, because it acts on finished
    downloads.

---

## 7. Layout primitives: native SwiftUI, not the package

**Recommendation: replicate the layout natively and don't add
`sindresorhus/Settings`.**

| Criterion | Package | Native |
|---|---|---|
| License | MIT, fine | n/a |
| Size | ~1,160 lines plus resources (localized window titles) | ~80–120 lines (a `SettingsGrid` row helper and a pane height reader) |
| Window integration | Own `SettingsWindowController` (AppKit) replaces the SwiftUI `Settings` scene. We would lose `openSettings`, the automatic ⌘, menu item and SwiftUI scene restoration, and have to bridge the existing `@Observable` models into `NSHostingController` panes | SwiftUI `Settings { TabView }` gives the toolbar, selection, title tracking and ⌘, for free |
| Swift 6 / strict concurrency | Package is Swift 5.8 tools. `static var defaultValue` in a `PreferenceKey` and non-isolated AppKit controllers would warn or fail if it moved to Swift 6 mode. It compiles today only in its own language mode | Written under our Swift 6 settings and SwiftLint rules |
| Layout | `Container`/`Section` uses `AnyView` (TODO in its source) and a `GeometryReader` per label | `Form.formStyle(.columns)` aligns labels natively. A custom alignment guide plus one `onGeometryChange` is needed only for custom rows |
| Maintenance | Single maintainer, low activity (last commit November 2025) | Ours |
| Memory | Small, but adds a module and an AppKit tab controller that keeps every pane's view controller alive | Panes are built lazily by `TabView`; nothing extra is retained |

What we take from it is the pattern:

* one fixed content width;
* a shared right-aligned label column per pane, with
  `minimumLabelWidth` for visual consistency across panes;
* optional dividers between sections;
* animated height change on pane switch.

If the stock `TabView` resizing is too abrupt on macOS 27, the native fallback
is a `.frame(height:)` driven by the measured ideal height with
`.animation(.smooth)`, still inside the `Settings` scene.

---

## 8. Full key mapping

Tier codes are defined in §4.3. "Label" says whether qBittorrent's label is
kept or which new wording replaces it (§9). The table is generated from the
key list in `preferences.md` Appendix A. The generator fails if a key is
missing or mapped twice.

Counts:

* **WebAPI keys:** 224 (223 GET plus `web_ui_password`).
  * By tier: B 42, R 32, A 83, A+D 4, D 3, X 54, H 2, P 4.
  * By pane: Advanced 56, Transfers 55, Privacy 35, Remote 32, General 28,
    Interface 19, Network 14, Speed 13, Search & RSS 13, platform-hidden 4.
    These pane counts include the GUI-only keys.
* **GUI-only and system keys:** 45. Three of them are newly surfaced:
  `Settings/ShowAdvanced` (new), and the Search/RSS visibility keys mirrored
  from the View menu.

### 8.1 WebAPI keys (GET order)

| # | JSON key | Now (page › section) | Proposed (page › section) | Tier | Label |
|---|---|---|---|---|---|
| 1 | `locale` | Behavior › Interface | General › Language | B | kept |
| 2 | `performance_warning` | Behavior › (status bar group) | Advanced › Logs & Diagnostics | X | kept |
| 3 | `status_bar_external_ip` | Behavior › (status bar group) | Interface › Status Bar | B | new: "Show external IP address" |
| 4 | `confirm_torrent_deletion` | Behavior › Transfer List | General › Confirmations | B | new: "Ask before deleting torrents" |
| 5 | `file_log_enabled` | Behavior › Log Files | Advanced › Logs & Diagnostics | X | kept |
| 6 | `file_log_path` | Behavior › Log Files | Advanced › Logs & Diagnostics | X | kept |
| 7 | `file_log_backup_enabled` | Behavior › Log Files | Advanced › Logs & Diagnostics | X | kept |
| 8 | `file_log_max_size` | Behavior › Log Files | Advanced › Logs & Diagnostics | X | kept |
| 9 | `file_log_delete_old` | Behavior › Log Files | Advanced › Logs & Diagnostics | X | kept |
| 10 | `file_log_age` | Behavior › Log Files | Advanced › Logs & Diagnostics | X | kept |
| 11 | `file_log_age_type` | Behavior › Log Files | Advanced › Logs & Diagnostics | X | kept |
| 12 | `delete_torrent_content_files` | API only (Remove dialog "Remember choice") | General › Confirmations | D | new row (optional): "Also delete files by default when removing torrents" |
| 13 | `torrent_content_layout` | Downloads › When adding a torrent | Transfers › Adding › Adding Torrents | A | kept, options reworded |
| 14 | `add_to_top_of_queue` | Downloads › When adding a torrent | Transfers › Adding › Adding Torrents | A | kept |
| 15 | `add_stopped_enabled` | Downloads › When adding a torrent | Transfers › Adding › Adding Torrents | B | new, inverted: "Start downloads automatically" |
| 16 | `torrent_stop_condition` | Downloads › When adding a torrent | Transfers › Adding › Adding Torrents | A | kept |
| 17 | `merge_trackers` | Downloads › When adding a duplicate torrent | Transfers › Adding › When adding a duplicate torrent | A | kept |
| 18 | `auto_delete_mode` | Downloads › Delete .torrent files afterwards | Transfers › Adding › .torrent Files | A | kept |
| 19 | `preallocate_all` | Downloads › (files group) | Transfers › Files › Files on Disk | A | kept |
| 20 | `incomplete_files_ext` | Downloads › (files group) | Transfers › Files › Files on Disk | A | kept |
| 21 | `use_unwanted_folder` | Downloads › (files group) | Transfers › Files › Files on Disk | A | kept |
| 22 | `auto_tmm_enabled` | Downloads › Saving Management | Transfers › Files › Categories & Automatic Mode | A | kept |
| 23 | `torrent_changed_tmm_enabled` | Downloads › Saving Management | Transfers › Files › Categories & Automatic Mode | A | kept |
| 24 | `save_path_changed_tmm_enabled` | Downloads › Saving Management | Transfers › Files › Categories & Automatic Mode | A | kept |
| 25 | `category_changed_tmm_enabled` | Downloads › Saving Management | Transfers › Files › Categories & Automatic Mode | A | kept |
| 26 | `save_path` | Downloads › Saving Management | Transfers › Adding › Save Location | B | new: "Save downloads to:" |
| 27 | `temp_path_enabled` | Downloads › Saving Management | Transfers › Adding › Save Location | B | new: "Keep incomplete downloads in:" |
| 28 | `temp_path` | Downloads › Saving Management | Transfers › Adding › Save Location | B | new: "Keep incomplete downloads in:" |
| 29 | `use_category_paths_in_manual_mode` | Downloads › Saving Management | Transfers › Files › Categories & Automatic Mode | A | kept |
| 30 | `export_dir` | Downloads › Saving Management | Transfers › Adding › .torrent Files | A | kept |
| 31 | `export_dir_fin` | Downloads › Saving Management | Transfers › Adding › .torrent Files | A | kept |
| 32 | `scan_dirs` | Downloads › Automatically add torrents from (legacy API view) | Transfers › Adding › Watched Folders | B | kept (edited through the folder list) |
| 33 | `excluded_file_names_enabled` | Downloads › Excluded file names | Transfers › Files › Files on Disk | A | kept; editor in a disclosure |
| 34 | `excluded_file_names` | Downloads › Excluded file names | Transfers › Files › Files on Disk | A | kept; editor in a disclosure |
| 35 | `mail_notification_enabled` | Downloads › Email notification | General › Notifications › Email | B | new: "Send an email when a download finishes" |
| 36 | `mail_notification_sender` | Downloads › Email notification | General › Notifications › Email | R | kept |
| 37 | `mail_notification_email` | Downloads › Email notification | General › Notifications › Email | R | kept |
| 38 | `mail_notification_smtp` | Downloads › Email notification | General › Notifications › Email | R | kept |
| 39 | `mail_notification_ssl_enabled` | Downloads › Email notification | General › Notifications › Email | R | kept |
| 40 | `mail_notification_auth_enabled` | Downloads › Email notification | General › Notifications › Email | R | kept |
| 41 | `mail_notification_username` | Downloads › Email notification | General › Notifications › Email | R | kept |
| 42 | `mail_notification_password` | Downloads › Email notification | General › Notifications › Email | R | kept |
| 43 | `autorun_on_torrent_added_enabled` | Downloads › Run external program | Transfers › Files › Run a Program | A | kept |
| 44 | `autorun_on_torrent_added_program` | Downloads › Run external program | Transfers › Files › Run a Program | A | kept |
| 45 | `autorun_enabled` | Downloads › Run external program | Transfers › Files › Run a Program | A | kept |
| 46 | `autorun_program` | Downloads › Run external program | Transfers › Files › Run a Program | A | kept |
| 47 | `listen_port` | Connection › Listening Port | Network › Listening Port | B | kept |
| 48 | `ssl_enabled` | API only | Network › Protocol & Limits | A | new row (optional): "Accept SSL torrents on port:" |
| 49 | `ssl_listen_port` | API only | Network › Protocol & Limits | A | new row (optional): "Accept SSL torrents on port:" |
| 50 | `random_port` | API only (deprecated alias) | Network › Listening Port | H | covered by the "Random" button |
| 51 | `upnp` | Connection › Listening Port | Network › Listening Port | B | kept |
| 52 | `max_connec` | Connection › Connections Limits | Network › Protocol & Limits | A | kept |
| 53 | `max_connec_per_torrent` | Connection › Connections Limits | Network › Protocol & Limits | A | kept |
| 54 | `max_uploads` | Connection › Connections Limits | Network › Protocol & Limits | A | kept |
| 55 | `max_uploads_per_torrent` | Connection › Connections Limits | Network › Protocol & Limits | A | kept |
| 56 | `i2p_enabled` | Connection › I2P (experimental) | Privacy › I2P (experimental) | A | kept |
| 57 | `i2p_address` | Connection › I2P (experimental) | Privacy › I2P (experimental) | A | kept |
| 58 | `i2p_port` | Connection › I2P (experimental) | Privacy › I2P (experimental) | A | kept |
| 59 | `i2p_mixed_mode` | Connection › I2P (experimental) | Privacy › I2P (experimental) | A | kept |
| 60 | `i2p_inbound_quantity` | Advanced › libtorrent Section | Privacy › I2P (experimental) › Tunnel settings | A+D | kept |
| 61 | `i2p_outbound_quantity` | Advanced › libtorrent Section | Privacy › I2P (experimental) › Tunnel settings | A+D | kept |
| 62 | `i2p_inbound_length` | Advanced › libtorrent Section | Privacy › I2P (experimental) › Tunnel settings | A+D | kept |
| 63 | `i2p_outbound_length` | Advanced › libtorrent Section | Privacy › I2P (experimental) › Tunnel settings | A+D | kept |
| 64 | `proxy_type` | Connection › Proxy Server | Privacy › Proxy Server | B | kept |
| 65 | `proxy_ip` | Connection › Proxy Server | Privacy › Proxy Server | B | kept |
| 66 | `proxy_port` | Connection › Proxy Server | Privacy › Proxy Server | B | kept |
| 67 | `proxy_auth_enabled` | Connection › Proxy Server | Privacy › Proxy Server | R | kept |
| 68 | `proxy_username` | Connection › Proxy Server | Privacy › Proxy Server | R | kept |
| 69 | `proxy_password` | Connection › Proxy Server | Privacy › Proxy Server | R | kept |
| 70 | `proxy_hostname_lookup` | Connection › Proxy Server | Privacy › Proxy Server | R | kept |
| 71 | `proxy_bittorrent` | Connection › Proxy Server | Privacy › Proxy Server | R | kept |
| 72 | `proxy_peer_connections` | Connection › Proxy Server | Privacy › Proxy Server | R | kept |
| 73 | `proxy_rss` | Connection › Proxy Server | Privacy › Proxy Server | R | kept |
| 74 | `proxy_misc` | Connection › Proxy Server | Privacy › Proxy Server | R | kept |
| 75 | `ip_filter_enabled` | Connection › IP Filtering | Privacy › IP Filtering | B | kept |
| 76 | `ip_filter_path` | Connection › IP Filtering | Privacy › IP Filtering | B | kept |
| 77 | `ip_filter_trackers` | Connection › IP Filtering | Privacy › IP Filtering | B | kept |
| 78 | `banned_IPs` | Connection › IP Filtering | Privacy › IP Filtering | B | kept |
| 79 | `dl_limit` | Speed › Global Rate Limits | Speed › Speed Limits | B | kept |
| 80 | `up_limit` | Speed › Global Rate Limits | Speed › Speed Limits | B | kept |
| 81 | `alt_dl_limit` | Speed › Alternative Rate Limits | Speed › Alternative Rate Limits | B | kept + explanation |
| 82 | `alt_up_limit` | Speed › Alternative Rate Limits | Speed › Alternative Rate Limits | B | kept + explanation |
| 83 | `bittorrent_protocol` | Connection › (top) | Network › Protocol & Limits | A | kept |
| 84 | `limit_utp_rate` | Speed › Rate Limits Settings | Speed › Rate Limits Settings | A | kept |
| 85 | `limit_tcp_overhead` | Speed › Rate Limits Settings | Speed › Rate Limits Settings | A | kept |
| 86 | `limit_lan_peers` | Speed › Rate Limits Settings | Speed › Rate Limits Settings | A | kept |
| 87 | `scheduler_enabled` | Speed › Schedule | Speed › Schedule | B | new: "Use alternative limits on a schedule" |
| 88 | `schedule_from_hour` | Speed › Schedule | Speed › Schedule | R | kept |
| 89 | `schedule_from_min` | Speed › Schedule | Speed › Schedule | R | kept |
| 90 | `schedule_to_hour` | Speed › Schedule | Speed › Schedule | R | kept |
| 91 | `schedule_to_min` | Speed › Schedule | Speed › Schedule | R | kept |
| 92 | `scheduler_days` | Speed › Schedule | Speed › Schedule | R | kept |
| 93 | `dht` | BitTorrent › Privacy | Network › Finding Peers | B | kept |
| 94 | `pex` | BitTorrent › Privacy | Network › Finding Peers | B | kept |
| 95 | `lsd` | BitTorrent › Privacy | Network › Finding Peers | B | kept |
| 96 | `encryption` | BitTorrent › Privacy | Privacy › Encryption & Anonymity | B | kept + explanation |
| 97 | `anonymous_mode` | BitTorrent › Privacy | Privacy › Encryption & Anonymity | B | kept + explanation |
| 98 | `max_active_checking_torrents` | BitTorrent › (checking) | Transfers › Seeding & Queue › Checking | A | kept |
| 99 | `queueing_enabled` | BitTorrent › Torrent Queueing | Transfers › Seeding & Queue › Queue | B | new: "Limit the number of active torrents" |
| 100 | `max_active_downloads` | BitTorrent › Torrent Queueing | Transfers › Seeding & Queue › Queue | R | kept |
| 101 | `max_active_torrents` | BitTorrent › Torrent Queueing | Transfers › Seeding & Queue › Queue | R | kept |
| 102 | `max_active_uploads` | BitTorrent › Torrent Queueing | Transfers › Seeding & Queue › Queue | R | kept |
| 103 | `dont_count_slow_torrents` | BitTorrent › Torrent Queueing | Transfers › Seeding & Queue › Queue › Slow torrents | A | kept |
| 104 | `slow_torrent_dl_rate_threshold` | BitTorrent › Torrent Queueing | Transfers › Seeding & Queue › Queue › Slow torrents | A | kept |
| 105 | `slow_torrent_ul_rate_threshold` | BitTorrent › Torrent Queueing | Transfers › Seeding & Queue › Queue › Slow torrents | A | kept |
| 106 | `slow_torrent_inactive_timer` | BitTorrent › Torrent Queueing | Transfers › Seeding & Queue › Queue › Slow torrents | A | kept |
| 107 | `max_ratio_enabled` | BitTorrent › Seeding Limits | Transfers › Seeding & Queue › Seeding Limits | B | kept + explanation |
| 108 | `max_ratio` | BitTorrent › Seeding Limits | Transfers › Seeding & Queue › Seeding Limits | B | kept + explanation |
| 109 | `max_seeding_time_enabled` | BitTorrent › Seeding Limits | Transfers › Seeding & Queue › Seeding Limits | B | kept + explanation |
| 110 | `max_seeding_time` | BitTorrent › Seeding Limits | Transfers › Seeding & Queue › Seeding Limits | B | kept + explanation |
| 111 | `max_inactive_seeding_time_enabled` | BitTorrent › Seeding Limits | Transfers › Seeding & Queue › Seeding Limits | B | kept + explanation |
| 112 | `max_inactive_seeding_time` | BitTorrent › Seeding Limits | Transfers › Seeding & Queue › Seeding Limits | B | kept + explanation |
| 113 | `max_ratio_act` | BitTorrent › Seeding Limits | Transfers › Seeding & Queue › Seeding Limits | B | kept + explanation |
| 114 | `add_trackers_enabled` | BitTorrent › Automatically append trackers | Transfers › Adding › Extra Trackers | A | kept |
| 115 | `add_trackers` | BitTorrent › Automatically append trackers | Transfers › Adding › Extra Trackers | A | kept |
| 116 | `add_trackers_from_url_enabled` | BitTorrent › Automatically append trackers | Transfers › Adding › Extra Trackers | A | kept |
| 117 | `add_trackers_url` | BitTorrent › Automatically append trackers | Transfers › Adding › Extra Trackers | A | kept |
| 118 | `add_trackers_url_list` | BitTorrent › Automatically append trackers | Transfers › Adding › Extra Trackers | A | kept |
| 119 | `web_ui_domain_list` | WebUI › Enable Host header validation | Remote › Security | A | kept |
| 120 | `web_ui_address` | WebUI › Web User Interface | Remote › Address | R | kept |
| 121 | `web_ui_port` | WebUI › Web User Interface | Remote › Address | R | kept |
| 122 | `web_ui_upnp` | WebUI › Web User Interface | Remote › Address | R | kept |
| 123 | `use_https` | WebUI › Use HTTPS instead of HTTP | Remote › HTTPS | R | kept |
| 124 | `web_ui_https_cert_path` | WebUI › Use HTTPS instead of HTTP | Remote › HTTPS | R | kept |
| 125 | `web_ui_https_key_path` | WebUI › Use HTTPS instead of HTTP | Remote › HTTPS | R | kept |
| 126 | `web_ui_username` | WebUI › Authentication | Remote › Sign-In | R | kept |
| SET | `web_ui_password` | WebUI › Authentication | Remote › Sign-In | R | kept |
| 127 | `bypass_local_auth` | WebUI › Authentication | Remote › Access Rules | A | kept |
| 128 | `bypass_auth_subnet_whitelist_enabled` | WebUI › Authentication | Remote › Access Rules | A | kept |
| 129 | `bypass_auth_subnet_whitelist` | WebUI › Authentication | Remote › Access Rules | A | kept |
| 130 | `web_ui_max_auth_fail_count` | WebUI › Authentication | Remote › Access Rules | A | kept |
| 131 | `web_ui_ban_duration` | WebUI › Authentication | Remote › Access Rules | A | kept |
| 132 | `web_ui_session_timeout` | WebUI › Authentication | Remote › Access Rules | A | kept |
| 133 | `web_ui_api_key` | WebUI › Authentication | Remote › Sign-In | R | kept |
| 134 | `alternative_webui_enabled` | WebUI › Use alternative WebUI | Remote › Alternative Web UI | A | kept |
| 135 | `alternative_webui_path` | WebUI › Use alternative WebUI | Remote › Alternative Web UI | A | kept |
| 136 | `web_ui_clickjacking_protection_enabled` | WebUI › Security | Remote › Security | A | kept |
| 137 | `web_ui_csrf_protection_enabled` | WebUI › Security | Remote › Security | A | kept |
| 138 | `web_ui_secure_cookie_enabled` | WebUI › Security | Remote › Security | A | kept |
| 139 | `web_ui_host_header_validation_enabled` | WebUI › Security | Remote › Security | A | kept |
| 140 | `web_ui_use_custom_http_headers_enabled` | WebUI › Security | Remote › Security | A | kept |
| 141 | `web_ui_custom_http_headers` | WebUI › Security | Remote › Security | A | kept |
| 142 | `web_ui_reverse_proxy_enabled` | WebUI › Security | Remote › Security | A | kept |
| 143 | `web_ui_reverse_proxies_list` | WebUI › Security | Remote › Security | A | kept |
| 144 | `dyndns_enabled` | WebUI › Update my dynamic domain name | Remote › Dynamic DNS | A | kept |
| 145 | `dyndns_service` | WebUI › Update my dynamic domain name | Remote › Dynamic DNS | A | kept |
| 146 | `dyndns_username` | WebUI › Update my dynamic domain name | Remote › Dynamic DNS | A | kept |
| 147 | `dyndns_password` | WebUI › Update my dynamic domain name | Remote › Dynamic DNS | A | kept |
| 148 | `dyndns_domain` | WebUI › Update my dynamic domain name | Remote › Dynamic DNS | A | kept |
| 149 | `rss_refresh_interval` | RSS › RSS Reader | Search & RSS › RSS › Feeds | B | kept |
| 150 | `rss_fetch_delay` | RSS › RSS Reader | Search & RSS › RSS › Feeds | A | kept |
| 151 | `rss_max_articles_per_feed` | RSS › RSS Reader | Search & RSS › RSS › Feeds | A | kept |
| 152 | `rss_processing_enabled` | RSS › RSS Reader | Search & RSS › RSS › Feeds | B | kept |
| 153 | `rss_auto_downloading_enabled` | RSS › RSS Torrent Auto Downloader | Search & RSS › RSS › Automatic Downloads | B | kept |
| 154 | `rss_download_repack_proper_episodes` | RSS › RSS Smart Episode Filter | Search & RSS › RSS Smart Episode Filter | A | kept |
| 155 | `rss_smart_episode_filters` | RSS › RSS Smart Episode Filter | Search & RSS › RSS Smart Episode Filter | A | kept |
| 156 | `resume_data_storage_type` | Advanced › qBittorrent Section | Advanced › Data & Recovery | X | kept |
| 157 | `torrent_content_remove_option` | Advanced › qBittorrent Section | Transfers › Files › Removing Torrents | B | new: "When removing a torrent with its files:" |
| 158 | `memory_working_set_limit` | Advanced (Windows only) | — | P | not shown on macOS (unchanged) |
| 159 | `current_network_interface` | Advanced › qBittorrent Section | Privacy › VPN Protection | B | new: "Use only this network interface:" |
| 160 | `current_interface_name` | API only (read-only) | Privacy › VPN Protection | H | shown as the interface name |
| 161 | `current_interface_address` | Advanced › qBittorrent Section | Privacy › VPN Protection | D | kept |
| 162 | `save_resume_data_interval` | Advanced › qBittorrent Section | Advanced › Data & Recovery | X | kept |
| 163 | `save_statistics_interval` | Advanced › qBittorrent Section | Advanced › Data & Recovery | X | kept |
| 164 | `torrent_file_size_limit` | Advanced › qBittorrent Section | Advanced › Safety Limits | X | kept |
| 165 | `confirm_torrent_recheck` | Advanced › qBittorrent Section | General › Confirmations | D | new: "Ask before rechecking torrents" |
| 166 | `recheck_completed_torrents` | Advanced › qBittorrent Section | Transfers › Files › Files on Disk | A | new: "Verify files again when a download finishes" |
| 167 | `app_instance_name` | Advanced › qBittorrent Section | Interface › Window | A | new: "Window title suffix:" |
| 168 | `refresh_interval` | Advanced › qBittorrent Section | Interface › Window | A | new: "Update interval:" |
| 169 | `resolve_peer_host_names` | Advanced › qBittorrent Section | Interface › Peers List | A | new: "Show peer host names", "Show peer countries" |
| 170 | `resolve_peer_countries` | Advanced › qBittorrent Section | Interface › Peers List | A | new: "Show peer host names", "Show peer countries" |
| 171 | `reannounce_when_address_changed` | Advanced › qBittorrent Section | Network › Protocol & Limits | A | kept |
| 172 | `enable_embedded_tracker` | Advanced › qBittorrent Section | Advanced › Embedded Tracker | X | kept |
| 173 | `embedded_tracker_port` | Advanced › qBittorrent Section | Advanced › Embedded Tracker | X | kept |
| 174 | `embedded_tracker_port_forwarding` | Advanced › qBittorrent Section | Advanced › Embedded Tracker | X | kept |
| 175 | `mark_of_the_web` | Advanced › qBittorrent Section | Privacy › Downloaded Files | B | new: "Quarantine downloaded files" |
| 176 | `ignore_ssl_errors` | Advanced › qBittorrent Section | Privacy › Protection | A | kept + warning |
| 177 | `python_executable_path` | Advanced › qBittorrent Section | Search & RSS › Search Engine | A | new: "Python executable:" |
| 178 | `bdecode_depth_limit` | Advanced › libtorrent Section | Advanced › Safety Limits | X | kept |
| 179 | `bdecode_token_limit` | Advanced › libtorrent Section | Advanced › Safety Limits | X | kept |
| 180 | `async_io_threads` | Advanced › libtorrent Section | Advanced › Disk & Memory | X | kept |
| 181 | `hashing_threads` | Advanced › libtorrent Section | Advanced › Disk & Memory | X | kept |
| 182 | `file_pool_size` | Advanced › libtorrent Section | Advanced › Disk & Memory | X | kept |
| 183 | `checking_memory_use` | Advanced › libtorrent Section | Advanced › Disk & Memory | X | kept |
| 184 | `disk_cache` | Advanced (libtorrent 1.2 only) | — | P | not shown with libtorrent 2 (unchanged) |
| 185 | `disk_cache_ttl` | Advanced (libtorrent 1.2 only) | — | P | not shown with libtorrent 2 (unchanged) |
| 186 | `disk_queue_size` | Advanced › libtorrent Section | Advanced › Disk & Memory | X | kept |
| 187 | `disk_io_type` | Advanced › libtorrent Section | Advanced › Disk & Memory | X | kept |
| 188 | `disk_io_read_mode` | Advanced › libtorrent Section | Advanced › Disk & Memory | X | kept |
| 189 | `disk_io_write_mode` | Advanced › libtorrent Section | Advanced › Disk & Memory | X | kept |
| 190 | `enable_coalesce_read_write` | Advanced (libtorrent 1.2 only) | — | P | not shown with libtorrent 2 (unchanged) |
| 191 | `enable_piece_extent_affinity` | Advanced › libtorrent Section | Advanced › Disk & Memory | X | kept |
| 192 | `enable_upload_suggestions` | Advanced › libtorrent Section | Advanced › Network Tuning | X | kept |
| 193 | `send_buffer_watermark` | Advanced › libtorrent Section | Advanced › Network Tuning | X | kept |
| 194 | `send_buffer_low_watermark` | Advanced › libtorrent Section | Advanced › Network Tuning | X | kept |
| 195 | `send_buffer_watermark_factor` | Advanced › libtorrent Section | Advanced › Network Tuning | X | kept |
| 196 | `connection_speed` | Advanced › libtorrent Section | Advanced › Network Tuning | X | kept |
| 197 | `socket_send_buffer_size` | Advanced › libtorrent Section | Advanced › Network Tuning | X | kept |
| 198 | `socket_receive_buffer_size` | Advanced › libtorrent Section | Advanced › Network Tuning | X | kept |
| 199 | `socket_backlog_size` | Advanced › libtorrent Section | Advanced › Network Tuning | X | kept |
| 200 | `outgoing_ports_min` | Advanced › libtorrent Section | Advanced › Network Tuning | X | kept |
| 201 | `outgoing_ports_max` | Advanced › libtorrent Section | Advanced › Network Tuning | X | kept |
| 202 | `upnp_lease_duration` | Advanced › libtorrent Section | Advanced › Network Tuning | X | kept |
| 203 | `peer_tos` | Advanced › libtorrent Section | Advanced › Network Tuning | X | kept |
| 204 | `utp_tcp_mixed_mode` | Advanced › libtorrent Section | Advanced › Network Tuning | X | kept |
| 205 | `hostname_cache_ttl` | Advanced › libtorrent Section | Advanced › Network Tuning | X | kept |
| 206 | `idn_support_enabled` | Advanced › libtorrent Section | Privacy › Protection | A | kept |
| 207 | `enable_multi_connections_from_same_ip` | Advanced › libtorrent Section | Advanced › Network Tuning | X | kept |
| 208 | `validate_https_tracker_certificate` | Advanced › libtorrent Section | Privacy › Protection | A | kept |
| 209 | `ssrf_mitigation` | Advanced › libtorrent Section | Privacy › Protection | A | kept |
| 210 | `block_peers_on_privileged_ports` | Advanced › libtorrent Section | Privacy › Protection | A | kept |
| 211 | `upload_slots_behavior` | Advanced › libtorrent Section | Advanced › Peers & Uploading | X | kept |
| 212 | `upload_choking_algorithm` | Advanced › libtorrent Section | Advanced › Peers & Uploading | X | kept |
| 213 | `announce_to_all_trackers` | Advanced › libtorrent Section | Advanced › Trackers & Announcing | X | kept |
| 214 | `announce_to_all_tiers` | Advanced › libtorrent Section | Advanced › Trackers & Announcing | X | kept |
| 215 | `announce_ip` | Advanced › libtorrent Section | Advanced › Trackers & Announcing | X | kept |
| 216 | `announce_port` | Advanced › libtorrent Section | Advanced › Trackers & Announcing | X | kept |
| 217 | `max_concurrent_http_announces` | Advanced › libtorrent Section | Advanced › Trackers & Announcing | X | kept |
| 218 | `stop_tracker_timeout` | Advanced › libtorrent Section | Advanced › Trackers & Announcing | X | kept |
| 219 | `peer_turnover` | Advanced › libtorrent Section | Advanced › Peers & Uploading | X | kept |
| 220 | `peer_turnover_cutoff` | Advanced › libtorrent Section | Advanced › Peers & Uploading | X | kept |
| 221 | `peer_turnover_interval` | Advanced › libtorrent Section | Advanced › Peers & Uploading | X | kept |
| 222 | `request_queue_size` | Advanced › libtorrent Section | Advanced › Peers & Uploading | X | kept |
| 223 | `dht_bootstrap_nodes` | Advanced › libtorrent Section | Advanced › DHT | X | kept |

### 8.2 GUI-only and system keys shown in Settings

Keys qBittorrent keeps outside the WebAPI that have a Settings control, plus the keys newly surfaced here. Window and dialog state from preferences.md §11 is not a setting and stays where it is (§5.10).

| Key (ini / system) | Current label | Now (page › section) | Proposed (page › section) | Tier | Label |
|---|---|---|---|---|---|
| `Appearance/ColorScheme` | Color scheme: | Behavior › Interface | Interface › Appearance | B | kept |
| `Preferences/General/AlternatingRowColors` | Use alternating row colors | Behavior › Transfer List | Interface › Torrent List | B | kept |
| `GUI/TransferList/StateColorScope` | Use different text colors by torrent states + Make progress bars follow text colors | Behavior › Transfer List | Interface › Torrent List | B | new: "Color by state:" picker; migrated from `UseTorrentStatesColors` / `ProgressBarFollowsTextColor` |
| `Preferences/General/HideZeroValues` | Hide zero and infinity values | Behavior › Transfer List | Interface › Torrent List | B | kept |
| `Preferences/General/HideZeroComboValues` | (scope combo) | Behavior › Transfer List | Interface › Torrent List | R | kept |
| `Preferences/Downloads/DblClOnTorDl` | Downloading torrents: | Behavior › Action on double-click | Interface › Action on double-click | B | kept |
| `Preferences/Downloads/DblClOnTorFn` | Completed torrents: | Behavior › Action on double-click | Interface › Action on double-click | B | kept |
| `TransferListFilters/HideZeroStatusFilters` | Auto hide zero status filters | Behavior › Transfer List | Interface › Sidebar | B | new: "Hide empty status filters" |
| `TransferListFilters/SeparateTrackerStatusFilter` | Use separate "Tracker status" filter | Behavior › Transfer List | Interface › Sidebar | B | kept |
| `Preferences/General/TorrentContentDragEnabled` | Drag content from qBit NeoRS | Behavior › Torrent Content View | Interface › Torrent Details | B | new: "Drag files from the Content tab to Finder" |
| `SMAppService (Open at Login)` | Open qBit NeoRS at login | Behavior › Desktop | General › Startup | B | kept |
| `GUI/StartUpWindowState` | Window state on start up: | Behavior › Desktop | General › Startup | B | new: "At startup, show window:" |
| `Preferences/General/ExitConfirm` | Confirmation on exit when torrents are active | Behavior › Desktop | General › Confirmations | B | new: "Ask before quitting while torrents are active" |
| `ShutdownConfirmDlg/DontConfirmAutoExit` | Confirmation on auto-exit when downloads finish | Behavior › Desktop | General › Confirmations | B | new: "Show a countdown before quitting when downloads finish" |
| `Preferences/Desktop/ShowSpeedInDock` | Show speed in Dock | Behavior › Desktop | General › Dock & Menu Bar | B | kept |
| `Preferences/Desktop/ShowMacOSMenuBarIcon` | Show qBit NeoRS in menu bar | Behavior › Desktop | General › Dock & Menu Bar | B | kept |
| `Preferences/Advanced/updateCheck` | Check for program updates | Behavior › Desktop | General › Updates | B | new: "Check for updates automatically" |
| `Locking/password_PBKDF2` | UI lock password: | Behavior › Desktop | Privacy › App Lock | B | new: "Lock password:" |
| `LaunchServices (.torrent)` | Use qBit NeoRS for .torrent files | Behavior › File association | General › Default App | B | new: ".torrent files" |
| `LaunchServices (magnet:)` | Use qBit NeoRS for magnet links | Behavior › File association | General › Default App | B | new: "Magnet links" |
| `Preferences/General/PreventFromSuspendWhenDownloading` | Inhibit system sleep when torrents are downloading | Behavior › Power Management | General › Power Management | B | new: "Keep Mac awake while downloading" |
| `Preferences/General/PreventFromSuspendWhenSeeding` | Inhibit system sleep when torrents are seeding | Behavior › Power Management | General › Power Management | B | new: "Keep Mac awake while seeding" |
| `Preferences/General/StatusbarFreeDiskSpaceDisplayed` | Show free disk space in status bar | Behavior › (status bar group) | Interface › Status Bar | B | new: "Show free disk space" |
| `AddNewTorrentDialog/Enabled` | Display torrent content and some options | Downloads › When adding a torrent | Transfers › Adding › Adding Torrents | B | new: "Show options when adding a torrent" |
| `AddNewTorrentDialog/TopLevel` | Bring torrent dialog to the front | Downloads › When adding a torrent | Transfers › Adding › Adding Torrents | R | kept |
| `GUI/ConfirmActions/MergeTrackers` | Ask to merge trackers for manually added torrent | Downloads › When adding a duplicate torrent | Transfers › Adding › When adding a duplicate torrent | A | kept |
| `Preferences/Advanced/DisableRecursiveDownload` | Enable recursive download dialog | Downloads › (files group) | Transfers › Files › Files on Disk | A | new: "Offer to add .torrent files found inside downloads" |
| `watched_folders.json` | Automatically add torrents from: | Downloads › Watched folders | Transfers › Adding › Watched Folders | B | kept |
| `GUI/Notifications/Enabled` | Display notifications | Advanced › qBittorrent Section | General › Notifications | B | kept |
| `Application/GUI/Notifications/TorrentAdded` | Display notifications for added torrents | Advanced › qBittorrent Section | General › Notifications | R | new: "Also when a torrent is added" |
| `Preferences/Advanced/confirmRemoveAllTags` | Confirm removal of all tags | Advanced › qBittorrent Section | General › Confirmations | D | new: "Ask before removing all tags" |
| `GUI/ConfirmActions/RemoveTrackerFromAllTorrents` | Confirm removal of tracker from all torrents | Advanced › qBittorrent Section | General › Confirmations | D | new: "Ask before removing a tracker from all torrents" |
| `GUI/DownloadTrackerFavicon` | Download tracker's favicon | Advanced › qBittorrent Section | Interface › Sidebar | B | new: "Show tracker icons" |
| `AddNewTorrentDialog/SavePathHistoryLength` | Save path history length | Advanced › qBittorrent Section | Transfers › Adding › Adding Torrents | A | new: "Remember recent save locations:" |
| `SpeedWidget/Enabled` | Enable speed graphs | Advanced › qBittorrent Section | Interface › Torrent Details | B | new: "Show speed graphs" |
| `BitTorrent/Session/StartPaused` | Start BitTorrent session in paused state | Advanced › qBittorrent Section | General › Startup | A | new: "Start with all transfers paused" |
| `BitTorrent/Session/ShutdownTimeout` | BitTorrent session shutdown timeout [-1: unlimited] | Advanced › qBittorrent Section | Advanced › Data & Recovery | X | kept |
| `Search/StoreOpenedSearchTabs` | Store opened tabs | Search › Search UI | Search & RSS › Search Tabs | B | new: "Reopen search tabs at launch" |
| `Search/StoreOpenedSearchTabResults` | Also store search results | Search › Search UI | Search & RSS › Search Tabs | R | kept |
| `Search/HistoryLength` | History length | Search › Search UI | Search & RSS › Search Tabs | A | kept |
| `Preferences/WebUI/Enabled` | Web User Interface (Remote control) | WebUI › (group) | Remote › (page switch) | B | new: "Allow control from a web browser" |
| `Settings/ShowAdvanced (new)` | — | — | Advanced › (page switch) | B | new key: "Show advanced settings" |
| `Preferences/Search/SearchEnabled` | View › Search Engine (menu) | menu only | Search & RSS › Search | B | also in View menu; new: "Show search engine" |
| `GUI/RSSWidget/Enabled` | View › RSS Reader (menu) | menu only | Search & RSS › RSS | B | also in View menu; new: "Show RSS reader" |

---

## 9. New and changed wording

Everything not listed here keeps qBittorrent's English source string, so the
imported translations (`scripts/i18n/import_qbt_translations.py`) keep
working. Russian is given for every new string. Other locales need fresh
translation, and their qBittorrent strings stay as a fallback until then.

### 9.1 Pane titles

| English | Russian | Note |
|---|---|---|
| General | Основные | qBittorrent's translation is "Главный". macOS convention is "Основные", so this string needs a context-specific override |
| Interface | Интерфейс | reused |
| Transfers | Торренты | reused (qBittorrent translates "Transfers" this way) |
| Speed | Скорость | reused |
| Network | Сеть | new |
| Privacy | Конфиденциальность | reused ("Privacy") |
| Remote | Удаленный доступ | new |
| Search & RSS | Поиск и RSS | new |
| Advanced | Дополнения | qBittorrent has "Расширенные"; Safari's Advanced pane is "Дополнения" in Russian. Use the context-specific override |

### 9.2 Section titles

| English | Russian | Replaces |
|---|---|---|
| Language | Язык | "Interface" group |
| Startup | Запуск | part of "Desktop" |
| Default App | Приложение по умолчанию | "File association" |
| Dock & Menu Bar | Dock и строка меню | part of "Desktop" |
| Notifications | Уведомления | Advanced rows and the Email group |
| Confirmations | Подтверждения | scattered checkboxes |
| More confirmations | Другие подтверждения | (disclosure) |
| Updates | Обновления | part of "Desktop" |
| Appearance | Оформление | "Interface" group |
| Torrent List | Список торрентов | "Transfer List" (qBittorrent RU is already "Список торрентов", so either source string works) |
| Sidebar | Боковая панель | part of "Transfer List" |
| Torrent Details | Сведения о торренте | "Torrent Content View" |
| Status Bar | Строка состояния | status-bar checkboxes |
| Peers List | Список пиров | Advanced rows |
| Window | Окно | Advanced rows |
| Adding | Добавление | (Transfers segment) |
| Files | Файлы | reused (Transfers segment) |
| Seeding & Queue | Раздача и очередь | (Transfers segment) |
| Save Location | Место сохранения | "Saving Management" (part) |
| Watched Folders | Папки наблюдения | "Automatically add torrents from:" |
| .torrent Files | Файлы .torrent | "Delete .torrent files afterwards" plus the export paths |
| Extra Trackers | Дополнительные трекеры | "Automatically append these trackers…" |
| Removing Torrents | Удаление торрентов | Advanced row |
| Files on Disk | Файлы на диске | unnamed Downloads group |
| Categories & Automatic Mode | Категории и автоматический режим | "Saving Management" (part) |
| Run a Program | Запуск программы | "Run external program" |
| Queue | Очередь | "Torrent Queueing" |
| Checking | Проверка | unnamed BitTorrent row |
| Schedule | Расписание | "Schedule the use of alternative rate limits" (group) |
| Status | Состояние | reused |
| Finding Peers | Поиск пиров | "Privacy" group (part) |
| Protocol & Limits | Протокол и ограничения | "Connections Limits" plus the protocol row |
| Encryption & Anonymity | Шифрование и анонимность | "Privacy" group (part) |
| VPN Protection | Защита VPN | Advanced rows |
| Bind to address | Привязка к адресу | (disclosure) |
| App Lock | Блокировка приложения | lock row on Behavior |
| Downloaded Files | Загруженные файлы | Advanced row |
| Tunnel settings | Параметры туннелей | (disclosure) |
| Protection | Защита | libtorrent rows |
| Address | Адрес | "Web User Interface" group |
| Sign-In | Вход | "Authentication" |
| Access Rules | Правила доступа | "Authentication" (part) |
| Alternative Web UI | Альтернативный веб-интерфейс | "Use alternative WebUI" |
| Dynamic DNS | Динамический DNS | "Update my dynamic domain name" |
| Search | Поиск | reused |
| RSS | RSS | reused |
| Logs & Diagnostics | Журнал и диагностика | "Log Files" plus a row |
| Data & Recovery | Данные и восстановление | Advanced rows |
| Disk & Memory | Диск и память | libtorrent rows |
| Network Tuning | Тонкая настройка сети | libtorrent rows |
| Peers & Uploading | Пиры и отдача | libtorrent rows |
| Trackers & Announcing | Трекеры и анонсы | libtorrent rows |
| Safety Limits | Защитные ограничения | Advanced rows |
| Embedded Tracker | Встроенный трекер | Advanced rows |

### 9.3 Setting labels

| Key | Current label | New English | New Russian |
|---|---|---|---|
| `Settings/ShowAdvanced` | — | Show advanced settings | Показывать дополнительные настройки |
| `GUI/StartUpWindowState` | Window state on start up: | At startup, show window: | Окно при запуске: |
| `BitTorrent/Session/StartPaused` | Start BitTorrent session in paused state | Start with all transfers paused | Запускать с приостановленными передачами |
| LaunchServices | Use qBit NeoRS for .torrent files | .torrent files | Файлы .torrent |
| LaunchServices | Use qBit NeoRS for magnet links | Magnet links | Magnet-ссылки |
| — | (button) | Make Default | Сделать основным |
| `Application/GUI/Notifications/TorrentAdded` | Display notifications for added torrents | Also when a torrent is added | Также при добавлении торрента |
| — | (button) | Notification Settings… | Настройки уведомлений… |
| `mail_notification_enabled` | Email notification upon download completion | Send an email when a download finishes | Отправлять письмо по завершении загрузки |
| `PreventFromSuspendWhenDownloading` | Inhibit system sleep when torrents are downloading | Keep Mac awake while downloading | Не давать Mac уснуть во время загрузки |
| `PreventFromSuspendWhenSeeding` | Inhibit system sleep when torrents are seeding | Keep Mac awake while seeding | Не давать Mac уснуть во время раздачи |
| `confirm_torrent_deletion` | Confirm when deleting torrents | Ask before deleting torrents | Спрашивать перед удалением торрентов |
| `ExitConfirm` | Confirmation on exit when torrents are active | Ask before quitting while torrents are active | Спрашивать перед выходом, если есть активные торренты |
| `DontConfirmAutoExit` (inverted) | Confirmation on auto-exit when downloads finish | Show a countdown before quitting when downloads finish | Показывать обратный отсчет перед выходом по завершении загрузок |
| `confirm_torrent_recheck` | Confirm torrent recheck | Ask before rechecking torrents | Спрашивать перед повторной проверкой торрентов |
| `confirmRemoveAllTags` | Confirm removal of all tags | Ask before removing all tags | Спрашивать перед удалением всех меток |
| `RemoveTrackerFromAllTorrents` | Confirm removal of tracker from all torrents | Ask before removing a tracker from all torrents | Спрашивать перед удалением трекера из всех торрентов |
| `delete_torrent_content_files` | (none) | Delete files by default when removing torrents | По умолчанию удалять файлы вместе с торрентом |
| `updateCheck` | Check for program updates | Check for updates automatically | Автоматически проверять обновления |
| `StateColorScope` | Use different text colors by torrent states | Color by state: | Цвет по состоянию: |
| `HideZeroStatusFilters` | Auto hide zero status filters | Hide empty status filters | Скрывать пустые фильтры состояния |
| `DownloadTrackerFavicon` | Download tracker's favicon | Show tracker icons | Показывать значки трекеров |
| `SpeedWidget/Enabled` | Enable speed graphs | Show speed graphs | Показывать графики скорости |
| `TorrentContentDragEnabled` | Drag content from qBit NeoRS | Drag files from the Content tab to Finder | Перетаскивать файлы из вкладки «Содержимое» в Finder |
| `StatusbarFreeDiskSpaceDisplayed` | Show free disk space in status bar | Show free disk space | Показывать свободное место на диске |
| `status_bar_external_ip` | Show external IP in status bar | Show external IP address | Показывать внешний IP-адрес |
| `resolve_peer_countries` | Resolve peer countries | Show peer countries | Показывать страны пиров |
| `resolve_peer_host_names` | Resolve peer host names | Show peer host names | Показывать имена узлов пиров |
| `refresh_interval` | Refresh interval | Update interval: | Интервал обновления: |
| `app_instance_name` | Customize application instance name | Window title suffix: | Дополнение к заголовку окна: |
| `save_path` | Default Save Path: | Save downloads to: | Сохранять загрузки в: |
| `temp_path_enabled` | Use another path for incomplete torrents: | Keep incomplete downloads in: | Хранить незавершенные загрузки в: |
| `AddNewTorrentDialog/Enabled` | Display torrent content and some options | Show options when adding a torrent | Показывать параметры при добавлении торрента |
| `add_stopped_enabled` (inverted) | Do not start the download automatically | Start downloads automatically | Начинать загрузку автоматически |
| `torrent_content_layout` options | Original / Create subfolder / Don't create subfolder | Keep original / Always create subfolder / Never create subfolder | Как в торренте / Всегда создавать подпапку / Не создавать подпапку |
| `SavePathHistoryLength` | Save path history length | Remember recent save locations: | Запоминать недавние места сохранения: |
| `torrent_content_remove_option` | Torrent content removing mode | When removing a torrent with its files: | При удалении торрента с файлами: |
| `recheck_completed_torrents` | Recheck torrents on completion | Verify files again when a download finishes | Перепроверять файлы по завершении загрузки |
| `DisableRecursiveDownload` (inverted) | Enable recursive download dialog | Offer to add .torrent files found inside downloads | Предлагать добавить файлы .torrent, найденные в загрузках |
| `queueing_enabled` | Torrent Queueing | Limit the number of active torrents | Ограничивать число активных торрентов |
| `scheduler_enabled` | Schedule the use of alternative rate limits | Use alternative limits on a schedule | Включать особые ограничения по расписанию |
| `ssl_enabled` + `ssl_listen_port` | (none) | Accept SSL torrents on port: | Принимать SSL-торренты на порту: |
| `current_network_interface` | Network interface | Use only this network interface: | Использовать только сетевой интерфейс: |
| `mark_of_the_web` | Enable quarantine for downloaded files | Quarantine downloaded files | Помещать загруженные файлы в карантин |
| `Locking/password_PBKDF2` | UI lock password: | Lock password: | Пароль блокировки: |
| `Preferences/WebUI/Enabled` | Web User Interface (Remote control) | Allow control from a web browser | Разрешить управление через веб-браузер |
| `SearchEnabled` | (View menu) Search Engine | Show search engine | Показывать поисковик |
| `GUI/RSSWidget/Enabled` | (View menu) RSS Reader | Show RSS reader | Показывать RSS-ленты |
| `Search/StoreOpenedSearchTabs` | Store opened tabs | Reopen search tabs at launch | Восстанавливать вкладки поиска при запуске |
| `python_executable_path` | Python executable path (may require restart) | Python executable: | Исполняемый файл Python: |
| — | — | Test Port | Проверить порт |
| — | — | Connected — peers can reach you | Подключено — пиры могут подключиться к вам |
| — | — | Firewalled — only outgoing connections work | За брандмауэром — работают только исходящие соединения |
| — | — | Offline | Не в сети |
| — | — | %lld advanced settings on this pane are changed. Show | Изменено дополнительных настроек на этой панели: %lld. Показать |

### 9.4 Explanations (footnotes)

| English | Russian |
|---|---|
| Adds advanced sections to every pane and shows libtorrent tuning below. Hidden settings keep working. | Добавляет дополнительные разделы на все панели и показывает ниже настройки libtorrent. Скрытые настройки продолжают действовать. |
| Changes take effect after relaunch. | Изменения вступят в силу после перезапуска. |
| Nothing downloads or uploads until you resume. | Ничего не загружается и не раздается, пока вы не возобновите работу. |
| When a download finishes or a file can't be written. | Когда загрузка завершена или файл не удается записать. |
| The display can still sleep. | Дисплей по-прежнему может засыпать. |
| System follows your Mac's appearance. | «Системная» следует оформлению Mac. |
| Downloads each tracker website's icon. | Загружает значок с сайта каждого трекера. |
| Uses a free IP-to-country database downloaded monthly. | Использует бесплатную базу IP-адресов по странам, загружаемую ежемесячно. |
| Looks up every peer's name; adds network traffic. | Определяет имя каждого пира; увеличивает сетевой трафик. |
| How often lists and speeds refresh. Lower values use more CPU. | Как часто обновляются списки и скорости. Меньшие значения сильнее нагружают процессор. |
| Helps tell several copies of the app apart. | Помогает различать несколько копий приложения. |
| Finished downloads move to the save location. | Завершенные загрузки перемещаются в место сохранения. |
| .torrent files saved into these folders are added automatically. | Файлы .torrent, сохраненные в эти папки, добавляются автоматически. |
| Automatic: the category decides the save location. | Автоматический: место сохранения определяет категория. |
| Ratio = uploaded ÷ downloaded. 1.0 means you shared as much as you took. | Рейтинг = отдано ÷ загружено. 1,0 означает, что вы отдали столько же, сколько получили. |
| Turn on with the tortoise button in the toolbar or status bar, or on a schedule. | Включаются кнопкой с черепахой на панели инструментов или в строке состояния либо по расписанию. |
| Lets peers reach you through your router. | Позволяет пирам подключаться к вам через роутер. |
| Private torrents never use these. | Приватные торренты никогда их не используют. |
| Require: connect only to peers that encrypt traffic. Fewer peers. | «Требовать»: подключаться только к пирам с шифрованием. Пиров будет меньше. |
| Hides client details from peers and trackers. Use with a proxy or VPN. | Скрывает сведения о клиенте от пиров и трекеров. Используйте с прокси или VPN. |
| Pick your VPN's interface so transfers stop if the VPN disconnects. | Выберите интерфейс VPN, чтобы передачи останавливались при отключении VPN. |
| View › Lock hides the window until the password is entered. | «Вид › Заблокировать» скрывает окно до ввода пароля. |
| macOS checks apps from torrents before they first open. | macOS проверяет приложения из торрентов перед первым запуском. |
| Unsafe: accepts forged certificates for RSS, updates and downloads. | Небезопасно: принимает поддельные сертификаты для RSS, обновлений и загрузок. |
| Without a password, a temporary one is generated at each launch and written to the log. | Без пароля при каждом запуске создается временный пароль, который записывается в журнал. |
| Anyone on these networks gets full control without a password. | Любой в этих сетях получает полный доступ без пароля. |
| Leave empty to detect automatically. | Оставьте пустым для автоматического определения. |

Russian follows the project glossary: «пир», «раздача», «рейтинг»,
«особые ограничения скорости» as in qBittorrent's Russian file. It uses «е»
where qBittorrent's file uses «ё», and should be checked against the
glossary in `scripts/i18n`.

---

## 10. Implementation plan

The goal is one data-driven catalog that drives the pane layout metadata, the
search index, tier visibility, the "changed hidden settings" counter and a
coverage test. The catalog must be identical in both repositories.

1. **Settings catalog (data, no views).**
   * Add `Features/Preferences/Catalog/SettingsCatalog.swift`, with
     `enum SettingsPane` (9 cases, title, symbol) and
     `struct SettingSpec: Sendable`.
   * `SettingSpec` holds:
     * `id`: a stable anchor, which is the WebAPI key or the ini key;
     * `pane` and `segment`;
     * `section`: a `LocalizedStringResource`;
     * `title` and `help`: `LocalizedStringResource`;
     * `tier`: `.basic`, `.revealed`, `.disclosure`, `.advanced` or
       `.expert`;
     * `keywords`: `[String]`, including the API key;
     * `isDefault`: a closure over the draft or GUI preferences, used by the
       hidden-changes counter.
   * Section and pane order is the array order. This replaces the generated
     `PreferencesIndex+Entries.swift` and its generator script; the index
     becomes `SettingsCatalog.all`.
   * Views keep their hand-written controls but wrap each row in
     `SettingRow(spec)`. `SettingRow` applies the anchor, the footnote, tier
     visibility and highlight, so labels and search can't drift.
2. **Prototype the window** (half a day). `Settings { TabView }` with the
   9 tab items, `.formStyle(.columns)` and the 640 pt width. Check three
   things on macOS 27:
   * the toolbar search item (§4.5);
   * animated height on pane switch (§7);
   * a fixed label column.

   Record the outcome in this document.
3. **Coverage test** (`QBTNeoTests/SettingsCatalogTests`).
   * Every `PreferencesDraft` stored property and every Settings-relevant
     `GUIPreferenceKey` case appears exactly once in the catalog.
   * Every catalog `id` resolves to a `.settingAnchor` in the view tree. A
     static list is maintained by the `SettingRow` initializer and checked
     against the catalog.
   * This is the executable form of §8, so nothing can silently become
     unreachable.
4. **Move sections pane by pane.** Rebuild the panes in this order: General,
   Interface, Transfers (with segments), Speed, Network, Privacy, Remote,
   Search & RSS, Advanced. This is pure layout. Model code
   (`PreferencesModel`, `GUIPreferences`) is untouched except for:
   * `Settings/ShowAdvanced`;
   * the inverted bindings for "Start downloads automatically" and "Offer to
     add .torrent files".
5. **Tiers and the advanced switch.**
   * Add `@AppStorage("Settings/ShowAdvanced")`.
   * Advanced sections show under `if showsAdvanced || revealed.contains(section)`.
   * The hidden-changes footer counts `!spec.isDefault` over hidden specs.
6. **Strings.** Add the §9 strings to `Localizable.xcstrings` with Russian.
   * "General" and "Advanced" need pane-specific keys or comments, so their
     Russian differs from qBittorrent's.
   * Run `import_qbt_translations.py` so kept labels still pick up all
     locales.
7. **Live illustrations.** Add these last, each behind the model that already
   owns the data:
   * connection status (from the session status the status bar already
     reads);
   * the speed sparkline (from the existing speed history, without a new
     timer);
   * the Privacy summary;
   * the default-app check;
   * the Web UI URL.
8. **Sibling repository.**
   * Copy `Features/Preferences/` to `qbittorrent_neo`. Product differences
     are the app name in strings (use `AppIdentity.displayName`) and the
     `Symbol` constants versus string literals.
   * Add `scripts/check-settings-sync.sh`. It diffs the two folders,
     ignoring those known substitutions, so the panes stay identical.
   * The catalog and the coverage test move together.
9. **Docs.** Update `docs/spec/features.md` (Settings section) and the
   ARCHITECTURE pointer. Keep `preferences.md` as the qBittorrent parity
   reference; it describes keys, not layout.

The repository rules apply throughout: one type per file, `@Observable
@MainActor` models, no core calls from `body`, and SwiftLint clean. The
catalog is static data (about 300 small structs, built once), so it has no
measurable memory cost.

---

## 11. Open questions

1. **Port test.** Transmission checks reachability against
   `portcheck.transmissionbt.com`. A Test Port button would send the user's
   IP and port to a third party, so it needs an explicit tap (never
   automatic), a disclosure line saying which service is used, and a
   security review per the web-feature rules. Until then, the Status row
   shows only what the session knows: connectable/firewalled from incoming
   connections.
2. **Language picker.** The HIG prefers the per-app language in System
   Settings › General › Language & Region. It is kept because `locale` is a
   WebAPI key and qBittorrent's language list is larger than the bundle's
   declared localizations. It could later become "System Default" plus a
   button opening System Settings.
3. **Inverted labels.** "Start downloads automatically" and "Offer to add
   .torrent files…" invert stored booleans for positive wording. The WebAPI
   and the ini file keep their original meaning; only the binding inverts.
4. **Pane count.** Nine panes are at the upper end of the 7–9 target. If the
   prototype shows the Russian toolbar overflowing, the first merge to
   consider is Search & RSS into Transfers as a fourth segment.

---

## 12. Implementation notes

What the prototype (§10, step 2) showed on macOS 27, and the resulting
differences from the proposal above. The owner approved the proposal with
these decisions: "Test Port" on explicit click only, the in-app language
picker in the advanced tier with "System default" first, direct wording for
the two inverted settings, and the merge in §11.4 if Russian overflows.

* **Eight panes, not nine.** With nine panes the Russian toolbar overflowed
  into a chevron menu even at 900 pt, so Search & RSS became the fourth
  Transfers segment (§11.4): **Adding · Files · Seeding & Queue · Search &
  RSS**. Its sections keep their tiers and catalog entries.
* **Window width follows the toolbar.** The window is at least 720 pt wide
  (room for the longest English row), and as wide as the localized pane labels
  plus the search field need
  (`SettingsLayout.windowWidth`, measured once at launch: 720 pt in
  English, about 910 pt in Russian), so the toolbar never hides the active pane.
* **Search field.** On a `Settings` scene's `TabView`, `.searchable(placement:
  .toolbar)` blanks the pane while the field is idle and expanded, and any
  `.toolbar` item turns the pane buttons into a plain item group. The field is
  therefore an `NSSearchToolbarItem` added by a thin wrapper around SwiftUI's
  toolbar delegate (`SettingsToolbarSearch`), which re-adds it when SwiftUI
  rebuilds the pane items. ⌘F focuses it, Return opens the first result,
  Escape clears it.
* **Results replace the pane** while the field has text, as a list of
  "Setting" over "Pane › Section" rows (advanced rows are marked), instead of
  a popover: a popover would take keyboard focus from the field. Choosing a
  result clears the field, opens the pane and segment, reveals the tier or
  disclosure group for the session, scrolls to the row and highlights it.
  Matching covers labels, section and pane titles, keywords, WebAPI and ini
  keys and explanations, ranked in that order.
* **Section titles** sit in the label column, on the first control's line
  when that control has no label of its own (checkboxes, buttons), otherwise
  on their own line. `Form(.columns)` draws `Section` headers above the
  controls column, so `SettingsGroup` draws the title itself. Sections are
  separated by space only.
* **Advanced pane** is a grouped form (switch at the top, documentation links
  in its footer); the long libtorrent labels don't fit a label column.
* **Language** is an advanced section on General ("System default" first,
  "Changes take effect after relaunch.").
* **Live status** shipped as proposed: connection status with port and
  external IP, the opt-in Test Port (core `check_port`, see SECURITY.md), the
  Privacy summary with links to its sections, the speed sparkline from the
  existing speed history (refreshed when the session status changes, no
  timer of its own), the default-app check marks and the Web UI URL with
  Copy and Open in Browser.
* **Rows that changed layout:** the connection limits and "Accept SSL
  torrents on port:" show their checkbox and value in the controls column (a
  label column wide enough for them squeezed the rest of the pane); the
  seeding limits keep their label column so the values line up.
* **New wording beyond §9:** "Enable I2P" (the I2P section's switch),
  "Connection status", "Test Port" footnote, "Port %@ is open/closed",
  "Listening port: %@ · External IP: %@", the Privacy summary items,
  "Alternative limits" (Speed header), "Edit excluded file names",
  "Supported parameters". All have Russian.
* **Catalog check.** `SettingsCatalogCheck` (debug builds, when the Settings
  window opens) asserts that every WebAPI key (Appendix A plus
  `web_ui_password`) and every Settings-relevant GUI key is covered by exactly
  one catalog entry, and that ids are unique. The app has no unit-test
  target, so this is the executable form of §8.
* **Snapshots.** `--snapshot <dir>` opens the real Settings scene
  (transparent, never activated) and captures every pane, the Transfers
  segments, the advanced tier on General, Network and Privacy, the Advanced
  pane with the switch on, and a search (`QBT_SETTINGS_QUERY`, default
  "vpn"), in light and dark.

