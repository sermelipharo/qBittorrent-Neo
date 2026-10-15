import SwiftUI

/// The Statistics window (View › Statistics, features.md §3.14).
struct StatisticsWindow: View {
    @Environment(AppModel.self) private var app
    @State private var model = StatisticsModel()

    var body: some View {
        Form {
            Section("User statistics") {
                StatisticRow(title: "All-time upload:", value: model.allTimeUpload)
                StatisticRow(title: "All-time download:", value: model.allTimeDownload)
                StatisticRow(title: "All-time share ratio:", value: model.allTimeShareRatio)
                StatisticRow(title: "Session waste:", value: model.sessionWaste)
                StatisticRow(title: "Connected peers:", value: model.connectedPeers)
            }
            Section("Cache statistics") {
                StatisticRow(title: "Total buffer size:", value: model.totalBufferSize)
            }
            Section("Performance statistics") {
                StatisticRow(title: "Write cache overload:", value: model.writeCacheOverload)
                StatisticRow(title: "Read cache overload:", value: model.readCacheOverload)
                StatisticRow(title: "Queued I/O jobs:", value: model.queuedIOJobs)
                StatisticRow(title: "Average time in queue:", value: model.averageTimeInQueue)
                StatisticRow(title: "Total queued size:", value: model.totalQueuedSize)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: FeatureDesign.Window.statisticsMin.width, minHeight: FeatureDesign.Window.statisticsMin.height)
        .navigationTitle(AppWindowID.statistics.title)
        .task { await model.run(app: app) }
    }
}
