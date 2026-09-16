import AVFoundation
import Foundation
import UIKit

struct WexloChatMessage: Codable, Equatable {
    enum Kind: String, Codable {
        case text
        case voice
        case image
    }

    let id: String
    let senderID: String
    let recipientID: String
    let kind: Kind
    let text: String?
    let timestamp: Date
    let audioFileName: String?
    let imageFileName: String?
    let duration: TimeInterval?

    init(
        id: String,
        senderID: String,
        recipientID: String,
        kind: Kind = .text,
        text: String? = nil,
        timestamp: Date = Date(),
        audioFileName: String? = nil,
        imageFileName: String? = nil,
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.senderID = senderID
        self.recipientID = recipientID
        self.kind = kind
        self.text = text
        self.timestamp = timestamp
        self.audioFileName = audioFileName
        self.imageFileName = imageFileName
        self.duration = duration
    }
}

struct WexloConversationPreview {
    let contactID: String
    let latestMessage: WexloChatMessage
    let isUnread: Bool
}

@MainActor
final class WexloRelationshipStore {
    static let shared = WexloRelationshipStore()

    private struct StoredState: Codable {
        var followingByUser: [String: [String]] = [:]
    }

    private let defaults: UserDefaults
    private let stateKey = "wexlo.following.relationships"
    private let seedVersionKey = "wexlo.following.seed.version"
    private let currentSeedVersion = "following-2026-09-15"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func seedInitialRelationshipsIfNeeded() {
        guard defaults.string(forKey: seedVersionKey) != currentSeedVersion else {
            return
        }

        var state = loadState()
        addFollowing(from: "henry", to: "clara", in: &state)
        addFollowing(from: "clara", to: "henry", in: &state)
        addFollowing(from: "henry", to: "samuel", in: &state)
        addFollowing(from: "samuel", to: "henry", in: &state)

        guard saveState(state) else { return }
        defaults.set(currentSeedVersion, forKey: seedVersionKey)
        NotificationCenter.default.post(name: .wexloRelationshipDidChange, object: nil)
    }

    func followingUserIDs(for userID: String) -> Set<String> {
        Set(loadState().followingByUser[userID] ?? [])
    }

    func followerUserIDs(for userID: String) -> Set<String> {
        Set(
            loadState().followingByUser.compactMap { sourceID, targetIDs in
                targetIDs.contains(userID) ? sourceID : nil
            }
        )
    }

    func isFollowing(_ targetUserID: String, from sourceUserID: String) -> Bool {
        followingUserIDs(for: sourceUserID).contains(targetUserID)
    }

    func areMutualFollowers(_ firstUserID: String, _ secondUserID: String) -> Bool {
        guard !firstUserID.isEmpty, !secondUserID.isEmpty, firstUserID != secondUserID else {
            return false
        }
        return isFollowing(secondUserID, from: firstUserID)
            && isFollowing(firstUserID, from: secondUserID)
    }

    @discardableResult
    func setFollowing(
        _ isFollowing: Bool,
        from sourceUserID: String,
        to targetUserID: String
    ) -> Bool {
        guard !sourceUserID.isEmpty,
              !targetUserID.isEmpty,
              sourceUserID != targetUserID else {
            return false
        }

        var state = loadState()
        var following = state.followingByUser[sourceUserID] ?? []
        if isFollowing {
            if !following.contains(targetUserID) {
                following.append(targetUserID)
            }
        } else {
            following.removeAll { $0 == targetUserID }
        }

        if following.isEmpty {
            state.followingByUser.removeValue(forKey: sourceUserID)
        } else {
            state.followingByUser[sourceUserID] = following
        }

        guard saveState(state) else { return false }
        NotificationCenter.default.post(
            name: .wexloRelationshipDidChange,
            object: nil,
            userInfo: [
                "sourceUserID": sourceUserID,
                "targetUserID": targetUserID
            ]
        )
        return true
    }

    func removeUser(_ userID: String) {
        var state = loadState()
        state.followingByUser.removeValue(forKey: userID)
        state.followingByUser = state.followingByUser.mapValues { targetIDs in
            targetIDs.filter { $0 != userID }
        }
        state.followingByUser = state.followingByUser.filter { !$0.value.isEmpty }
        _ = saveState(state)
        NotificationCenter.default.post(name: .wexloRelationshipDidChange, object: nil)
    }

    private func addFollowing(
        from sourceUserID: String,
        to targetUserID: String,
        in state: inout StoredState
    ) {
        var following = state.followingByUser[sourceUserID] ?? []
        if !following.contains(targetUserID) {
            following.append(targetUserID)
        }
        state.followingByUser[sourceUserID] = following
    }

    private func loadState() -> StoredState {
        guard let data = defaults.data(forKey: stateKey),
              let state = try? JSONDecoder().decode(StoredState.self, from: data) else {
            return StoredState()
        }
        return state
    }

    private func saveState(_ state: StoredState) -> Bool {
        guard let data = try? JSONEncoder().encode(state) else { return false }
        defaults.set(data, forKey: stateKey)
        return true
    }
}

@MainActor
final class WexloChatStore {
    static let shared = WexloChatStore()

    private struct StoredState: Codable {
        var messages: [WexloChatMessage] = []
    }

    private let defaults: UserDefaults
    private let relationshipStore: WexloRelationshipStore
    private let stateKey = "wexlo.chat.messages"
    private let audioDirectoryName = "WexloVoiceMessages"
    private let imageDirectoryName = "WexloChatMedia"
    private let readStateKey = "wexlo.chat.read.messages"
    private let seedVersionKey = "wexlo.chat.seed.version"
    private let currentSeedVersion = "chat-voice-2026-09-15"

    init(
        defaults: UserDefaults = .standard,
        relationshipStore: WexloRelationshipStore? = nil
    ) {
        self.defaults = defaults
        self.relationshipStore = relationshipStore ?? WexloRelationshipStore.shared
    }

    func seedInitialChatsIfNeeded() {
        guard defaults.string(forKey: seedVersionKey) != currentSeedVersion else {
            return
        }

        let now = Date()
        let seedMessages = [
            WexloChatMessage(
                id: "henry-clara-1",
                senderID: "clara",
                recipientID: "henry",
                text: "Hey Henry, your latest layering post was so useful.",
                timestamp: now.addingTimeInterval(-900)
            ),
            WexloChatMessage(
                id: "henry-clara-2",
                senderID: "henry",
                recipientID: "clara",
                text: "Glad it helped. I kept the shell light for the commute.",
                timestamp: now.addingTimeInterval(-780)
            ),
            WexloChatMessage(
                id: "henry-clara-3",
                senderID: "clara",
                recipientID: "henry",
                text: "Do you size up for a fleece layer?",
                timestamp: now.addingTimeInterval(-660)
            ),
            WexloChatMessage(
                id: "henry-clara-4",
                senderID: "henry",
                recipientID: "clara",
                text: "Usually one size up. It leaves room without feeling bulky.",
                timestamp: now.addingTimeInterval(-540)
            ),
            WexloChatMessage(
                id: "henry-clara-5",
                senderID: "clara",
                recipientID: "henry",
                kind: .voice,
                timestamp: now.addingTimeInterval(-420),
                duration: 12
            ),
            WexloChatMessage(
                id: "henry-samuel-1",
                senderID: "samuel",
                recipientID: "henry",
                text: "That rainy-day setup looks ready for a long commute.",
                timestamp: now.addingTimeInterval(-10_800)
            ),
            WexloChatMessage(
                id: "henry-samuel-2",
                senderID: "henry",
                recipientID: "samuel",
                text: "Thanks. Your camping layering checklist gave me the idea.",
                timestamp: now.addingTimeInterval(-10_620)
            ),
            WexloChatMessage(
                id: "henry-samuel-3",
                senderID: "samuel",
                recipientID: "henry",
                text: "We should compare our favorite fleece layers sometime.",
                timestamp: now.addingTimeInterval(-10_440)
            )
        ]

        var state = loadState()
        state.messages = state.messages.map { message in
            guard message.audioFileName == nil,
                  isVoiceMessage(message),
                  let audioFileName = createSeedVoiceAudio(
                    fileName: "seed-\(message.id).wav",
                    duration: message.duration ?? 12
                  ) else {
                return message
            }
            return WexloChatMessage(
                id: message.id,
                senderID: message.senderID,
                recipientID: message.recipientID,
                kind: .voice,
                timestamp: message.timestamp,
                audioFileName: audioFileName,
                duration: message.duration ?? 12
            )
        }
        let existingIDs = Set(state.messages.map(\.id))
        state.messages.append(
            contentsOf: seedMessages.map { message in
                guard isVoiceMessage(message),
                      let audioFileName = createSeedVoiceAudio(
                        fileName: "seed-\(message.id).wav",
                        duration: message.duration ?? 12
                      ) else {
                    return message
                }
                return WexloChatMessage(
                    id: message.id,
                    senderID: message.senderID,
                    recipientID: message.recipientID,
                    kind: .voice,
                    timestamp: message.timestamp,
                    audioFileName: audioFileName,
                    duration: message.duration ?? 12
                )
            }.filter { !existingIDs.contains($0.id) }
        )

        guard saveState(state) else { return }
        defaults.set(currentSeedVersion, forKey: seedVersionKey)
        NotificationCenter.default.post(name: .wexloChatDidChange, object: nil)
    }

    func canChat(between firstUserID: String, and secondUserID: String) -> Bool {
        relationshipStore.areMutualFollowers(firstUserID, secondUserID)
    }

    func messages(between firstUserID: String, and secondUserID: String) -> [WexloChatMessage] {
        guard canChat(between: firstUserID, and: secondUserID) else {
            return []
        }
        return loadState().messages
            .filter {
                ($0.senderID == firstUserID && $0.recipientID == secondUserID)
                    || ($0.senderID == secondUserID && $0.recipientID == firstUserID)
            }
            .sorted { $0.timestamp < $1.timestamp }
    }

    func conversationPreviews(for userID: String) -> [WexloConversationPreview] {
        let groupedMessages = Dictionary(grouping: loadState().messages.filter {
            $0.senderID == userID || $0.recipientID == userID
        }) { message in
            message.senderID == userID ? message.recipientID : message.senderID
        }

        return groupedMessages.compactMap { contactID, messages in
            guard relationshipStore.areMutualFollowers(userID, contactID),
                  let latestMessage = messages.max(by: { $0.timestamp < $1.timestamp }) else {
                return nil
            }
            let isUnread = latestMessage.recipientID == userID
                && !readMessageIDs(for: userID, with: contactID).contains(latestMessage.id)
            return WexloConversationPreview(
                contactID: contactID,
                latestMessage: latestMessage,
                isUnread: isUnread
            )
        }
        .sorted { $0.latestMessage.timestamp > $1.latestMessage.timestamp }
    }

    func markConversationRead(for userID: String, with contactID: String) {
        let incomingMessageIDs: [String] = loadState().messages.compactMap { message in
            guard message.senderID == contactID,
                  message.recipientID == userID else {
                return nil
            }
            return message.id
        }
        guard !incomingMessageIDs.isEmpty else { return }

        var readState = loadReadState()
        let key = readStateKey(for: userID, with: contactID)
        readState[key] = Array(Set(readState[key, default: []]).union(incomingMessageIDs))
        guard saveReadState(readState) else { return }

        NotificationCenter.default.post(
            name: .wexloChatDidChange,
            object: nil,
            userInfo: [
                "readerID": userID,
                "contactID": contactID
            ]
        )
    }

    @discardableResult
    func appendTextMessage(
        _ text: String,
        from senderID: String,
        to recipientID: String
    ) -> WexloChatMessage? {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              canChat(between: senderID, and: recipientID) else {
            return nil
        }

        let message = WexloChatMessage(
            id: UUID().uuidString,
            senderID: senderID,
            recipientID: recipientID,
            text: text,
            timestamp: Date()
        )
        var state = loadState()
        state.messages.append(message)
        guard saveState(state) else { return nil }

        NotificationCenter.default.post(
            name: .wexloChatDidChange,
            object: nil,
            userInfo: [
                "senderID": senderID,
                "recipientID": recipientID
            ]
        )
        return message
    }

    @discardableResult
    func appendImageMessage(
        _ image: UIImage,
        senderID: String,
        to recipientID: String
    ) -> WexloChatMessage? {
        guard canChat(between: senderID, and: recipientID),
              let imageData = image.jpegData(compressionQuality: 0.88),
              let imageDirectoryURL = imageDirectoryURL() else {
            return nil
        }

        let imageFileName = "\(UUID().uuidString).jpg"
        let destinationURL = imageDirectoryURL.appendingPathComponent(imageFileName)
        do {
            try imageData.write(to: destinationURL, options: Data.WritingOptions.atomic)
        } catch {
            return nil
        }

        let message = WexloChatMessage(
            id: UUID().uuidString,
            senderID: senderID,
            recipientID: recipientID,
            kind: .image,
            timestamp: Date(),
            imageFileName: imageFileName
        )
        var state = loadState()
        state.messages.append(message)
        guard saveState(state) else {
            try? FileManager.default.removeItem(at: destinationURL)
            return nil
        }

        NotificationCenter.default.post(
            name: .wexloChatDidChange,
            object: nil,
            userInfo: [
                "senderID": senderID,
                "recipientID": recipientID
            ]
        )
        return message
    }

    @discardableResult
    func appendVoiceMessage(
        from sourceURL: URL,
        duration: TimeInterval,
        senderID: String,
        to recipientID: String
    ) -> WexloChatMessage? {
        guard duration > 0,
              canChat(between: senderID, and: recipientID),
              let audioDirectoryURL = voiceAudioDirectoryURL() else {
            return nil
        }

        let audioFileName = "\(UUID().uuidString).m4a"
        let destinationURL = audioDirectoryURL.appendingPathComponent(audioFileName)
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            _ = try AVAudioFile(forReading: destinationURL)
        } catch {
            try? FileManager.default.removeItem(at: destinationURL)
            return nil
        }

        let message = WexloChatMessage(
            id: UUID().uuidString,
            senderID: senderID,
            recipientID: recipientID,
            kind: .voice,
            timestamp: Date(),
            audioFileName: audioFileName,
            duration: duration
        )
        var state = loadState()
        state.messages.append(message)
        guard saveState(state) else {
            try? FileManager.default.removeItem(at: destinationURL)
            return nil
        }

        NotificationCenter.default.post(
            name: .wexloChatDidChange,
            object: nil,
            userInfo: [
                "senderID": senderID,
                "recipientID": recipientID
            ]
        )
        return message
    }

    func audioURL(for message: WexloChatMessage) -> URL? {
        guard let audioFileName = message.audioFileName,
              let directoryURL = voiceAudioDirectoryURL() else {
            return nil
        }
        let url = directoryURL.appendingPathComponent(audioFileName)
        guard FileManager.default.fileExists(atPath: url.path),
              let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? NSNumber,
              fileSize.int64Value > 0,
              (try? AVAudioFile(forReading: url)) != nil else {
            return nil
        }
        return url
    }

    func imageURL(for message: WexloChatMessage) -> URL? {
        guard let imageFileName = message.imageFileName,
              let directoryURL = imageDirectoryURL() else {
            return nil
        }
        let url = directoryURL.appendingPathComponent(imageFileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func removeMessages(for userID: String) {
        var state = loadState()
        let removedMessages = state.messages.filter {
            $0.senderID == userID || $0.recipientID == userID
        }
        state.messages.removeAll { $0.senderID == userID || $0.recipientID == userID }
        _ = saveState(state)
        removeMediaFiles(for: removedMessages)
        var readState = loadReadState()
        readState = readState.filter { key, _ in
            !key.hasPrefix("\(userID)::") && !key.hasSuffix("::\(userID)")
        }
        _ = saveReadState(readState)
        NotificationCenter.default.post(name: .wexloChatDidChange, object: nil)
    }

    func previewText(for message: WexloChatMessage) -> String {
        switch message.kind {
        case .text:
            return message.text ?? ""
        case .voice:
            return "Voice message"
        case .image:
            return "Photo"
        }
    }

    func timestampLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    func relativeTimestamp(for date: Date) -> String {
        let elapsed = max(0, Date().timeIntervalSince(date))
        if elapsed < 60 {
            return "now"
        }
        if elapsed < 3_600 {
            return "\(Int(elapsed / 60))m"
        }
        if elapsed < 86_400 {
            return "\(Int(elapsed / 3_600))h"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func loadState() -> StoredState {
        guard let data = defaults.data(forKey: stateKey),
              let state = try? JSONDecoder().decode(StoredState.self, from: data) else {
            return StoredState()
        }
        return state
    }

    private func saveState(_ state: StoredState) -> Bool {
        guard let data = try? JSONEncoder().encode(state) else { return false }
        defaults.set(data, forKey: stateKey)
        return true
    }

    private func loadReadState() -> [String: [String]] {
        guard let data = defaults.data(forKey: readStateKey),
              let state = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            return [:]
        }
        return state
    }

    private func saveReadState(_ state: [String: [String]]) -> Bool {
        guard let data = try? JSONEncoder().encode(state) else { return false }
        defaults.set(data, forKey: readStateKey)
        return true
    }

    private func readMessageIDs(for userID: String, with contactID: String) -> Set<String> {
        Set(loadReadState()[readStateKey(for: userID, with: contactID)] ?? [])
    }

    private func readStateKey(for userID: String, with contactID: String) -> String {
        "\(userID)::\(contactID)"
    }

    private func isVoiceMessage(_ message: WexloChatMessage) -> Bool {
        if case .voice = message.kind {
            return true
        }
        return false
    }

    private func createSeedVoiceAudio(
        fileName: String,
        duration: TimeInterval
    ) -> String? {
        guard let directoryURL = voiceAudioDirectoryURL() else {
            return nil
        }
        let destinationURL = directoryURL.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            return fileName
        }

        let sampleRate = 44_100.0
        let frameCount = AVAudioFrameCount(max(1, Int(sampleRate * duration)))
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 1
        ),
        let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameCount
        ),
        let channelData = buffer.floatChannelData?[0],
        let audioFile = try? AVAudioFile(
            forWriting: destinationURL,
            settings: format.settings
        ) else {
            return nil
        }

        buffer.frameLength = frameCount
        for index in 0..<Int(frameCount) {
            let time = Double(index) / sampleRate
            let envelope = min(1, time * 18) * min(1, (duration - time) * 18)
            channelData[index] = Float(sin(2 * .pi * 440 * time) * 0.08 * envelope)
        }

        do {
            try audioFile.write(from: buffer)
            return fileName
        } catch {
            try? FileManager.default.removeItem(at: destinationURL)
            return nil
        }
    }

    private func voiceAudioDirectoryURL() -> URL? {
        mediaDirectoryURL(named: audioDirectoryName)
    }

    private func imageDirectoryURL() -> URL? {
        mediaDirectoryURL(named: imageDirectoryName)
    }

    private func mediaDirectoryURL(named name: String) -> URL? {
        guard let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }
        let directoryURL = applicationSupportURL.appendingPathComponent(name)
        do {
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
            return directoryURL
        } catch {
            return nil
        }
    }

    private func removeMediaFiles(for messages: [WexloChatMessage]) {
        guard let audioDirectoryURL = voiceAudioDirectoryURL(),
              let imageDirectoryURL = imageDirectoryURL() else {
            return
        }
        for message in messages {
            if let audioFileName = message.audioFileName {
                try? FileManager.default.removeItem(
                    at: audioDirectoryURL.appendingPathComponent(audioFileName)
                )
            }
            if let imageFileName = message.imageFileName {
                try? FileManager.default.removeItem(
                    at: imageDirectoryURL.appendingPathComponent(imageFileName)
                )
            }
        }
    }
}

extension Notification.Name {
    static let wexloRelationshipDidChange = Notification.Name("wexlo.relationship.didChange")
    static let wexloChatDidChange = Notification.Name("wexlo.chat.didChange")
}
