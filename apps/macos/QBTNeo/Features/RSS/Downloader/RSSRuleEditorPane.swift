import SwiftUI

/// "Rule Definition": filters, episode filter, ignore days, torrent
/// parameters and "Apply Rule to Feeds:". Edits save automatically.
struct RSSRuleEditorPane: View {
    @Bindable var model: RSSDownloaderModel
    let context: TorrentParamsContext

    var body: some View {
        if let rule = Binding($model.draft) {
            Form {
                Section("Rule Definition") {
                    SpinField(title: "Priority:", value: rule.priority, range: Int64(Int32.min)...Int64(Int32.max),
                              width: FeatureDesign.Width.wideSpinField)
                    Toggle("Use Regular Expressions", isOn: rule.useRegex)
                    RuleFilterField(title: "Must Contain:", text: rule.mustContain, error: model.mustContainError,
                                    help: RuleHelp.filter(regex: rule.wrappedValue.useRegex, mustContain: true))
                    RuleFilterField(title: "Must Not Contain:", text: rule.mustNotContain, error: model.mustNotContainError,
                                    help: RuleHelp.filter(regex: rule.wrappedValue.useRegex, mustContain: false))
                    RuleFilterField(title: "Episode Filter:", text: rule.episodeFilter,
                                    error: model.episodeFilterValid ? "" : String(localized: "Invalid episode filter"),
                                    help: RuleHelp.episodeFilter, prompt: "1x2;8-15;5;30-;")
                    Toggle("Use Smart Episode Filter", isOn: rule.smartFilter)
                        .help(RuleHelp.smartFilter)
                    SpinField(title: "Ignore Subsequent Matches for (0 to Disable)", value: rule.ignoreDays, range: 0...365,
                              unit: String(localized: "days"), special: .text(String(localized: "Disabled")))
                    LabeledContent {
                        Text(RuleHelp.lastMatch(rule.wrappedValue.lastMatch))
                            .foregroundStyle(.secondary)
                    } label: {
                        Text(rule.wrappedValue.previouslyMatchedEpisodes.isEmpty
                             ? "" : String(localized: "Downloaded episodes: \(rule.wrappedValue.previouslyMatchedEpisodes.formatted())"))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                TorrentParamsEditor(params: rule.torrentParams, context: context)
                RSSAffectedFeedsSection(model: model)
            }
            .formStyle(.grouped)
        } else {
            VStack {
                if !model.selection.isEmpty {
                    Form { RSSAffectedFeedsSection(model: model) }
                        .formStyle(.grouped)
                } else {
                    ContentUnavailableView("No Rule Selected", systemImage: "list.bullet.rectangle",
                                           description: Text("Select a rule to edit it, or several to change their feeds."))
                }
            }
        }
    }
}
