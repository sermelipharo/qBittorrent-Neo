import Foundation
import os
import QBTNeoCore
import Synchronization

/// Owns the in-process qBittorrent core (`qbtneo.h`) and performs requests.
///
/// Every request is a method name plus JSON arguments and is answered with
/// JSON on the core's own thread. Synchronous requests wait on a semaphore
/// (with a timeout); asynchronous ones resume a continuation, so awaiting
/// callers never block a thread.
final class CoreBridge: Sendable {
    nonisolated(unsafe) private let handle: OpaquePointer
    private let events: EventRelay
    private static let logger = Logger(subsystem: "mk.lex.qbittorrentneo", category: "core")

    /// Longest time a synchronous call waits for the core thread.
    static let syncTimeout: DispatchTimeInterval = .seconds(30)

    /// Starts the core (loads the profile and creates the session). Blocks
    /// for the duration of the start-up; call it off the main actor.
    init(config: AppConfig) throws {
        let relay = EventRelay()
        let configData = try JSONEncoder().encode(config)
        var error: UnsafeMutablePointer<CChar>?
        let context = Unmanaged.passUnretained(relay).toOpaque()
        let handle = configData.withUnsafeBytes { bytes in
            qbtn_core_start(bytes.baseAddress?.assumingMemoryBound(to: CChar.self), bytes.count,
                            coreEventCallback, context, &error)
        }
        guard let handle else {
            let message = error.map { String(cString: $0) } ?? "The core could not be started."
            qbtn_free(error)
            throw QbtError.Other(message: message)
        }
        self.handle = handle
        events = relay
    }

    var listener: (any EventListener)? {
        get { events.listener }
        set { events.listener = newValue }
    }

    /// Saves resume data and stops the core; blocks up to the shutdown timeout.
    func shutdown() {
        qbtn_core_shutdown(handle)
        events.listener = nil
    }

    // MARK: Requests

    /// Waits for the reply on the calling thread.
    func call<R: Decodable>(_ method: String, _ args: [String: any Encodable] = [:], as type: R.Type = R.self) throws -> R {
        try Self.decode(R.self, from: callRaw(method, args))
    }

    func callVoid(_ method: String, _ args: [String: any Encodable] = [:]) throws {
        _ = try callRaw(method, args)
    }

    /// Like `call`, but logs failures and returns `fallback` (non-throwing
    /// facade methods).
    func value<R: Decodable>(_ method: String, _ args: [String: any Encodable] = [:], fallback: R) -> R {
        do {
            return try call(method, args)
        } catch {
            Self.logger.error("\(method, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            return fallback
        }
    }

    /// Suspends until the reply arrives; Swift task cancellation cancels the
    /// request in the core.
    func callAsync<R: Decodable & Sendable>(_ method: String, _ args: [String: any Encodable] = [:],
                                            as type: R.Type = R.self) async throws -> R {
        try Self.decode(R.self, from: await callRawAsync(method, args))
    }

    func callAsyncVoid(_ method: String, _ args: [String: any Encodable] = [:]) async throws {
        _ = try await callRawAsync(method, args)
    }

    private func callRaw(_ method: String, _ args: [String: any Encodable]) throws -> Data {
        let body = try Self.encode(args)
        let box = ReplyBox()
        _ = submit(method, body, box)
        guard box.semaphore.wait(timeout: .now() + Self.syncTimeout) == .success else {
            throw QbtError.Other(message: "The qBittorrent core did not answer \(method) in time.")
        }
        return try box.result()
    }

    private func callRawAsync(_ method: String, _ args: [String: any Encodable]) async throws -> Data {
        let body = try Self.encode(args)
        let box = ReplyBox()
        let requestID = Mutex<UInt64?>(nil)
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, any Error>) in
                box.setContinuation(continuation)
                let id = submit(method, body, box)
                requestID.withLock { $0 = id }
            }
        } onCancel: { [self] in
            if let id = requestID.withLock({ $0 }) {
                qbtn_core_cancel(handle, id)
            }
        }
    }

    private func submit(_ method: String, _ body: Data, _ box: ReplyBox) -> UInt64 {
        let context = Unmanaged.passRetained(box).toOpaque()
        return body.withUnsafeBytes { bytes in
            qbtn_core_call(handle, method, bytes.baseAddress?.assumingMemoryBound(to: CChar.self), bytes.count,
                           coreReplyCallback, context)
        }
    }

    // MARK: JSON

    private static func encode(_ args: [String: any Encodable]) throws -> Data {
        try JSONEncoder().encode(args.mapValues(AnyEncodable.init))
    }

    private static func decode<R: Decodable>(_ type: R.Type, from data: Data) throws -> R {
        if R.self == EmptyReply.self, let empty = EmptyReply() as? R { return empty }
        do {
            return try JSONDecoder().decode(R.self, from: data)
        } catch {
            throw QbtError.Other(message: "Unexpected reply from the core: \(error)")
        }
    }
}

/// Result type of calls without a value.
struct EmptyReply: Decodable, Sendable {}

/// Type-erased `Encodable` for argument dictionaries.
private struct AnyEncodable: Encodable {
    let value: any Encodable

    func encode(to encoder: any Encoder) throws {
        try value.encode(to: encoder)
    }
}

/// One pending request; completed exactly once by the core.
private final class ReplyBox: @unchecked Sendable {
    let semaphore = DispatchSemaphore(value: 0)
    private let state = Mutex<State>(State())

    private struct State {
        var status: Int32 = 0
        var data = Data()
        var completed = false
        var continuation: CheckedContinuation<Data, any Error>?
    }

    func setContinuation(_ continuation: CheckedContinuation<Data, any Error>) {
        let resume: (Int32, Data)? = state.withLock { state in
            if state.completed { return (state.status, state.data) }
            state.continuation = continuation
            return nil
        }
        if let (status, data) = resume {
            continuation.resume(with: Self.outcome(status, data))
        }
    }

    func complete(status: Int32, data: Data) {
        let continuation = state.withLock { state in
            state.status = status
            state.data = data
            state.completed = true
            return state.continuation.take()
        }
        continuation?.resume(with: Self.outcome(status, data))
        semaphore.signal()
    }

    func result() throws -> Data {
        let (status, data) = state.withLock { ($0.status, $0.data) }
        return try Self.outcome(status, data).get()
    }

    private static func outcome(_ status: Int32, _ data: Data) -> Result<Data, any Error> {
        guard status != 0 else { return .success(data) }
        let message = String(bytes: data, encoding: .utf8) ?? ""
        switch status {
        case 1: return .failure(QbtError.NotFound(message: message))
        case 2: return .failure(QbtError.InvalidArgument(message: message))
        case 3: return .failure(QbtError.Conflict(message: message))
        case 4: return .failure(QbtError.Io(message: message))
        case 5: return .failure(QbtError.Network(message: message))
        case 6: return .failure(QbtError.Engine(message: message))
        case 7: return .failure(QbtError.Unsupported(message: message))
        case 9: return .failure(CancellationError())
        default: return .failure(QbtError.Other(message: message))
        }
    }
}

/// Decodes core events and hands them to the app's listener.
private final class EventRelay: Sendable {
    private let current = Mutex<(any EventListener)?>(nil)

    var listener: (any EventListener)? {
        get { current.withLock { $0 } }
        set { current.withLock { $0 = newValue } }
    }

    func deliver(_ data: Data) {
        guard let listener else { return }
        if let event = try? JSONDecoder().decode(CoreEvent.self, from: data) {
            listener.onEvent(event: event)
        }
    }
}

private let coreReplyCallback: qbtn_reply_fn = { context, status, data, length in
    guard let context else { return }
    let box = Unmanaged<ReplyBox>.fromOpaque(context).takeRetainedValue()
    let payload = data.map { Data(bytes: $0, count: length) } ?? Data()
    box.complete(status: status, data: payload)
}

private let coreEventCallback: qbtn_event_fn = { context, json, length in
    guard let context, let json else { return }
    let relay = Unmanaged<EventRelay>.fromOpaque(context).takeUnretainedValue()
    relay.deliver(Data(bytes: json, count: length))
}
