import Foundation
import UIKit

enum WexloMediaKind: String, Codable {
    case image
    case video
}

enum WexloMediaStorage: String, Codable {
    case bundled
    case local
}

struct WexloSeedUser {
    let id: String
    let name: String
    let email: String
    let password: String
    let avatarAssetName: String
    let bio: String
}

struct WexloLayerItem: Codable {
    let name: String
    let detail: String
    let symbol: String
}

struct WexloLocalComment: Codable {
    let authorID: String
    let text: String
    let timeLabel: String
}

struct WexloLocalPost: Codable {
    let id: String
    let authorID: String
    let mediaFileName: String
    let mediaKind: WexloMediaKind
    let mediaStorage: WexloMediaStorage
    let title: String
    let detail: String
    let category: String
    let styleTag: String
    let setting: String
    let layers: [WexloLayerItem]
    let comments: [WexloLocalComment]
    let likes: String
    let publishedAt: Date
    let authorName: String?
    let authorAvatarAssetName: String

    init(
        id: String,
        authorID: String,
        mediaFileName: String,
        mediaKind: WexloMediaKind,
        title: String,
        detail: String,
        category: String,
        styleTag: String,
        setting: String,
        layers: [WexloLayerItem],
        comments: [WexloLocalComment],
        likes: String,
        mediaStorage: WexloMediaStorage = .bundled,
        publishedAt: Date = .distantPast,
        authorName: String? = nil,
        authorAvatarAssetName: String = ""
    ) {
        self.id = id
        self.authorID = authorID
        self.mediaFileName = mediaFileName
        self.mediaKind = mediaKind
        self.mediaStorage = mediaStorage
        self.title = title
        self.detail = detail
        self.category = category
        self.styleTag = styleTag
        self.setting = setting
        self.layers = layers
        self.comments = comments
        self.likes = likes
        self.publishedAt = publishedAt
        self.authorName = authorName
        self.authorAvatarAssetName = authorAvatarAssetName
    }

    var mediaAssetName: String? {
        guard mediaKind == .image, mediaStorage == .bundled else { return nil }
        return (mediaFileName as NSString).deletingPathExtension
    }
}

struct WexloPostLikeState {
    let isLiked: Bool
    let count: Int
}

final class WexloSavedOutfitStore {
    static let shared = WexloSavedOutfitStore()

    private struct StoredState: Codable {
        var postIDsByUser: [String: [String]] = [:]
    }

    private let defaults: UserDefaults
    private let stateKey = "wexlo.saved.outfits"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func savedPostIDs(for userID: String) -> [String] {
        loadState().postIDsByUser[userID] ?? []
    }

    func isSaved(postID: String, userID: String) -> Bool {
        savedPostIDs(for: userID).contains(postID)
    }

    @discardableResult
    func setSaved(_ saved: Bool, postID: String, userID: String) -> Bool {
        var storedState = loadState()
        var postIDs = storedState.postIDsByUser[userID] ?? []

        if saved {
            if !postIDs.contains(postID) {
                postIDs.append(postID)
            }
        } else {
            postIDs.removeAll { $0 == postID }
        }

        if postIDs.isEmpty {
            storedState.postIDsByUser.removeValue(forKey: userID)
        } else {
            storedState.postIDsByUser[userID] = postIDs
        }
        guard saveState(storedState) else { return false }
        NotificationCenter.default.post(
            name: .wexloSavedPostDidChange,
            object: postID,
            userInfo: [
                "userID": userID,
                "isSaved": saved
            ]
        )
        return true
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

final class WexloLikeStore {
    static let shared = WexloLikeStore()

    private struct StoredState: Codable {
        var likedPostKeys: Set<String> = []
        var likeCounts: [String: Int] = [:]
    }

    private let defaults: UserDefaults
    private let stateKey = "wexlo.post.likes"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func state(for post: WexloLocalPost, userID: String) -> WexloPostLikeState {
        let storedState = loadState()
        let key = likeKey(postID: post.id, userID: userID)
        let count = storedState.likeCounts[post.id] ?? Int(post.likes) ?? 0
        return WexloPostLikeState(
            isLiked: storedState.likedPostKeys.contains(key),
            count: count
        )
    }

    func likeCount(for post: WexloLocalPost) -> Int {
        loadState().likeCounts[post.id] ?? Int(post.likes) ?? 0
    }

    @discardableResult
    func toggleLike(for post: WexloLocalPost, userID: String) -> WexloPostLikeState? {
        var storedState = loadState()
        let key = likeKey(postID: post.id, userID: userID)
        let currentlyLiked = storedState.likedPostKeys.contains(key)
        let baseCount = Int(post.likes) ?? 0
        let currentCount = storedState.likeCounts[post.id] ?? baseCount

        if currentlyLiked {
            storedState.likedPostKeys.remove(key)
            storedState.likeCounts[post.id] = max(baseCount, currentCount - 1)
        } else {
            storedState.likedPostKeys.insert(key)
            storedState.likeCounts[post.id] = currentCount + 1
        }

        guard saveState(storedState) else { return nil }
        return WexloPostLikeState(
            isLiked: !currentlyLiked,
            count: storedState.likeCounts[post.id] ?? baseCount
        )
    }

    private func likeKey(postID: String, userID: String) -> String {
        "\(userID)::\(postID)"
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
final class WexloBlockStore {
    static let shared = WexloBlockStore()

    private struct StoredState: Codable {
        var blockedUserIDsByAccount: [String: [String]] = [:]
    }

    private let defaults: UserDefaults
    private let stateKey = "wexlo.blocked.users"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func blockedUserIDs(for accountID: String) -> Set<String> {
        Set(loadState().blockedUserIDsByAccount[accountID] ?? [])
    }

    func isBlocked(_ userID: String, for accountID: String) -> Bool {
        blockedUserIDs(for: accountID).contains(userID)
    }

    @discardableResult
    func blockUser(_ userID: String, for accountID: String) -> Bool {
        guard !userID.isEmpty, !accountID.isEmpty, userID != accountID else {
            return false
        }

        var state = loadState()
        var blockedUserIDs = state.blockedUserIDsByAccount[accountID] ?? []
        guard !blockedUserIDs.contains(userID) else { return true }
        blockedUserIDs.append(userID)
        state.blockedUserIDsByAccount[accountID] = blockedUserIDs

        guard saveState(state) else { return false }
        NotificationCenter.default.post(
            name: .wexloBlockedUserDidChange,
            object: userID,
            userInfo: ["accountID": accountID]
        )
        return true
    }

    @discardableResult
    func unblockUser(_ userID: String, for accountID: String) -> Bool {
        var state = loadState()
        var blockedUserIDs = state.blockedUserIDsByAccount[accountID] ?? []
        blockedUserIDs.removeAll { $0 == userID }

        if blockedUserIDs.isEmpty {
            state.blockedUserIDsByAccount.removeValue(forKey: accountID)
        } else {
            state.blockedUserIDsByAccount[accountID] = blockedUserIDs
        }

        guard saveState(state) else { return false }
        NotificationCenter.default.post(
            name: .wexloBlockedUserDidChange,
            object: userID,
            userInfo: ["accountID": accountID]
        )
        return true
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

enum WexloContentStoreError: Error {
    case invalidMedia
    case storageFailure

    var userMessage: String {
        switch self {
        case .invalidMedia:
            return "The selected media is unavailable."
        case .storageFailure:
            return "The outfit could not be saved. Please try again."
        }
    }
}

final class WexloLocalContentStore {
    static let shared = WexloLocalContentStore()

    private let defaults: UserDefaults
    private let publishedPostsKey = "wexlo.published.posts"
    private let mediaDirectoryName = "WexloMedia"
    private(set) var publishedPosts: [WexloLocalPost]

    let users: [WexloSeedUser] = [
        WexloSeedUser(
            id: "henry",
            name: "Henry",
            email: "test@gmail.com",
            password: "123456",
            avatarAssetName: "3ecb9ea93cd043fde069c650fc98e9d1",
            bio: "Exploring city trails and daily layers. Berlin-based outdoor enthusiast."
        ),
        WexloSeedUser(
            id: "clara",
            name: "Clara",
            email: "clara@gmail.com",
            password: "123456",
            avatarAssetName: "a9d6f577358d6cc2328548b9b5dd8f2f",
            bio: "Coffee, city walks, and functional aesthetic."
        ),
        WexloSeedUser(
            id: "samuel",
            name: "Samuel",
            email: "samuel@gmail.com",
            password: "123456",
            avatarAssetName: "c6b1bcf0a7de2602d641ffd7ed2f279d",
            bio: "Weekend camper & gear tester. Hiking through Scandinavian woods."
        ),
        WexloSeedUser(
            id: "amelia",
            name: "Amelia",
            email: "amelia@gmail.com",
            password: "123456",
            avatarAssetName: "445ae4344fa0422383d2b1042ce9fbee",
            bio: "Minimalist style for maximum journeys. Travel light, stay warm."
        ),
        WexloSeedUser(
            id: "james",
            name: "James",
            email: "james@gmail.com",
            password: "123456",
            avatarAssetName: "6f8c34cdcbf72a5d34b2e5535223b72b",
            bio: "Rain or shine, always outside. Urban hiking & waterproof fit check."
        ),
        WexloSeedUser(
            id: "mia",
            name: "Mia",
            email: "mia@gmail.com",
            password: "123456",
            avatarAssetName: "15d058e5b1d372de38f21d8055f89223",
            bio: "Daily bike commute & outdoor style blending into city life."
        ),
        WexloSeedUser(
            id: "charlie",
            name: "Charlie",
            email: "charlie@gmail.com",
            password: "123456",
            avatarAssetName: "0b3b21ff27f67b9e5821e5ffee7366c5",
            bio: "Tech & travel enthusiast exploring East European landscapes."
        ),
        WexloSeedUser(
            id: "aria",
            name: "Aria",
            email: "aria@gmail.com",
            password: "123456",
            avatarAssetName: "a1cef908ea057f0877b33f490f9520aa",
            bio: "Wilderness minimalism & quiet starry nights in Norway."
        )
    ]

    private let seedPosts: [WexloLocalPost] = [
        WexloLocalPost(
            id: "henry-rainy-day-city-layers",
            authorID: "henry",
            mediaFileName: "download (11).png",
            mediaKind: .image,
            title: "Rainy Day City Layers",
            detail: "Light rain in the city today. Paired a waterproof shell with a lightweight fleece mid-layer. Perfect for bike commuting without overheating.",
            category: "Tops",
            styleTag: "Gorpcore",
            setting: "Commute",
            layers: [
                WexloLayerItem(name: "Shell · Outer layer", detail: "Dark Charcoal Waterproof Hooded Shell", symbol: "wind"),
                WexloLayerItem(name: "Mid-layer", detail: "Lightweight Grid Fleece Jacket", symbol: "cloud"),
                WexloLayerItem(name: "Base layer", detail: "Merino Wool Short Sleeve Tee", symbol: "tshirt"),
                WexloLayerItem(name: "Footwear", detail: "Waterproof Trail Running Shoes", symbol: "shoe"),
                WexloLayerItem(name: "Accessories", detail: "Reflective Cycling Cap", symbol: "figure.outdoor.cycle")
            ],
            comments: [],
            likes: "128"
        ),
        WexloLocalPost(
            id: "clara-urban-windproof-outfit",
            authorID: "clara",
            mediaFileName: "102e2480-1eea-4b67-900c-b93473874396.mp4",
            mediaKind: .video,
            title: "Urban Windproof Outfit",
            detail: "Heading to a corner cafe in a comfortable windbreaker. Simple, structured layering for a cool overcast day.",
            category: "Outerwear",
            styleTag: "City Outdoor",
            setting: "Rainy Day",
            layers: [
                WexloLayerItem(name: "Shell · Outer layer", detail: "Beige Oversized Windproof Parka", symbol: "wind"),
                WexloLayerItem(name: "Mid-layer", detail: "Soft Knit Cardigan Sweater", symbol: "cloud"),
                WexloLayerItem(name: "Base layer", detail: "Organic Cotton White Crewneck Tee", symbol: "tshirt"),
                WexloLayerItem(name: "Footwear", detail: "Casual Leather Low-top Sneakers", symbol: "shoe")
            ],
            comments: [
                WexloLocalComment(authorID: "henry", text: "Super functional and aesthetic!", timeLabel: "Today")
            ],
            likes: "96"
        ),
        WexloLocalPost(
            id: "samuel-weekend-camping-functional-layering",
            authorID: "samuel",
            mediaFileName: "download (2).png",
            mediaKind: .image,
            title: "Weekend Camping Functional Layering",
            detail: "Temperatures drop fast in the woods at night. A thermal base layer plus a multi-pocket functional jacket is essential.",
            category: "Bottoms",
            styleTag: "Techwear",
            setting: "Camping",
            layers: [
                WexloLayerItem(name: "Shell · Outer layer", detail: "Multi-pocket Technical Hooded Jacket", symbol: "wind"),
                WexloLayerItem(name: "Mid-layer", detail: "Padded Insulated Lightweight Vest", symbol: "cloud"),
                WexloLayerItem(name: "Base layer", detail: "Thermal Compression Long Sleeve Tee", symbol: "tshirt"),
                WexloLayerItem(name: "Footwear", detail: "High-cut Outdoor Hiking Boots", symbol: "shoe"),
                WexloLayerItem(name: "Accessories", detail: "Utility Chest Rig & Tactical Belt", symbol: "backpack")
            ],
            comments: [],
            likes: "174"
        ),
        WexloLocalPost(
            id: "amelia-lightweight-minimal-travel-outfit",
            authorID: "amelia",
            mediaFileName: "download (3).png",
            mediaKind: .image,
            title: "Lightweight Minimal Travel Outfit",
            detail: "Heavy luggage is the worst during travel. A breathable base layer and a windproof shell kept me comfortable all day.",
            category: "Footwear",
            styleTag: "Minimal Outdoor",
            setting: "Travel",
            layers: [
                WexloLayerItem(name: "Shell · Outer layer", detail: "Olive Green Lightweight Rain Shell", symbol: "wind"),
                WexloLayerItem(name: "Mid-layer", detail: "Packable Down Inner Jacket", symbol: "cloud"),
                WexloLayerItem(name: "Base layer", detail: "Breathable Quick-dry T-shirt", symbol: "tshirt"),
                WexloLayerItem(name: "Footwear", detail: "Minimalist Lightweight Trail Shoes", symbol: "shoe")
            ],
            comments: [
                WexloLocalComment(authorID: "clara", text: "Pure mountain vibes!", timeLabel: "Today")
            ],
            likes: "84"
        ),
        WexloLocalPost(
            id: "james-rainy-day-layering-logic",
            authorID: "james",
            mediaFileName: "download (5).png",
            mediaKind: .image,
            title: "Rainy Day Layering Logic",
            detail: "Breathable base layer + warm fleece mid-layer + waterproof outer shell. Staying dry even during sudden rain.",
            category: "Outerwear",
            styleTag: "Gorpcore",
            setting: "Rainy Day",
            layers: [
                WexloLayerItem(name: "Shell · Outer layer", detail: "Matte Black 3-Layer Waterproof Jacket", symbol: "wind"),
                WexloLayerItem(name: "Mid-layer", detail: "Polar Fleece Pullover Sweater", symbol: "cloud"),
                WexloLayerItem(name: "Base layer", detail: "Moisture-wicking Seamless Tee", symbol: "tshirt"),
                WexloLayerItem(name: "Footwear", detail: "All-weather Waterproof Hiking Shoes", symbol: "shoe"),
                WexloLayerItem(name: "Accessories", detail: "Knit Beanie & Waterproof Gloves", symbol: "backpack")
            ],
            comments: [],
            likes: "212"
        ),
        WexloLocalPost(
            id: "mia-daily-city-cycling-outfit",
            authorID: "mia",
            mediaFileName: "download (7).png",
            mediaKind: .image,
            title: "Daily City Cycling Outfit",
            detail: "A balance of wind protection and breathability for night cycling, featuring subtle reflective details for safety.",
            category: "Tops",
            styleTag: "City Outdoor",
            setting: "Commute",
            layers: [
                WexloLayerItem(name: "Shell · Outer layer", detail: "Reflective Windbreaker Jacket", symbol: "wind"),
                WexloLayerItem(name: "Mid-layer", detail: "Softshell Windproof Vest", symbol: "cloud"),
                WexloLayerItem(name: "Base layer", detail: "Long Sleeve Casual Jersey", symbol: "tshirt"),
                WexloLayerItem(name: "Footwear", detail: "Urban Cycling Sneakers", symbol: "shoe"),
                WexloLayerItem(name: "Accessories", detail: "UV Protection Sunglasses", symbol: "sunglasses")
            ],
            comments: [],
            likes: "142"
        ),
        WexloLocalPost(
            id: "charlie-techwear-long-distance-travel",
            authorID: "charlie",
            mediaFileName: "download (9).png",
            mediaKind: .image,
            title: "Techwear Long Distance Travel",
            detail: "Modular pockets make passport and tech gear easy to access, while a light shell handles unexpected weather during trips.",
            category: "Equipment",
            styleTag: "Techwear",
            setting: "Travel",
            layers: [
                WexloLayerItem(name: "Shell · Outer layer", detail: "Breathable Windproof Shell Jacket", symbol: "wind"),
                WexloLayerItem(name: "Mid-layer", detail: "Hybrid Softshell Fleece Vest", symbol: "cloud"),
                WexloLayerItem(name: "Base layer", detail: "Bamboo Fiber Anti-odor Crew Tee", symbol: "tshirt"),
                WexloLayerItem(name: "Footwear", detail: "All-terrain Tactical Sneakers", symbol: "shoe"),
                WexloLayerItem(name: "Accessories", detail: "Canvas Travel Bag", symbol: "backpack")
            ],
            comments: [],
            likes: "118"
        ),
        WexloLocalPost(
            id: "aria-minimalist-wilderness-warmth",
            authorID: "aria",
            mediaFileName: "download (10).png",
            mediaKind: .image,
            title: "Minimalist Wilderness Warmth",
            detail: "Ditching complex gear. A thick fleece paired with a lightweight wind shell keeps you warm enough for chilly night campings.",
            category: "Accessories",
            styleTag: "Minimal Outdoor",
            setting: "Camping",
            layers: [
                WexloLayerItem(name: "Shell · Outer layer", detail: "Ultralight Ripstop Rain Jacket", symbol: "wind"),
                WexloLayerItem(name: "Mid-layer", detail: "Thick Thermal Sherpa Fleece", symbol: "cloud"),
                WexloLayerItem(name: "Base layer", detail: "Merino Thermal Long Sleeve", symbol: "tshirt"),
                WexloLayerItem(name: "Footwear", detail: "Insulated Camp Mule Shoes", symbol: "shoe"),
                WexloLayerItem(name: "Accessories", detail: "All-Weather Expedition Pack", symbol: "backpack")
            ],
            comments: [
                WexloLocalComment(authorID: "james", text: "Such a mood!", timeLabel: "Today")
            ],
            likes: "156"
        )
    ]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.publishedPosts = []
        self.publishedPosts = loadPublishedPosts()
    }

    var posts: [WexloLocalPost] {
        let allPosts = seedPosts + publishedPosts
        return allPosts
            .enumerated()
            .sorted { first, second in
                if first.element.publishedAt != second.element.publishedAt {
                    return first.element.publishedAt > second.element.publishedAt
                }
                return first.offset < second.offset
            }
            .map(\.element)
    }

    func user(for id: String) -> WexloSeedUser? {
        users.first { $0.id == id }
    }

    func post(for id: String) -> WexloLocalPost? {
        posts.first { $0.id == id }
    }

    @discardableResult
    func publishPost(
        authorID: String,
        authorName: String?,
        authorAvatarAssetName: String,
        title: String,
        detail: String,
        styleTag: String,
        setting: String,
        layers: [WexloLayerItem],
        image: UIImage?,
        videoURL: URL?
    ) throws -> WexloLocalPost {
        guard image != nil || videoURL != nil else {
            throw WexloContentStoreError.invalidMedia
        }

        let postID = UUID().uuidString
        let mediaKind: WexloMediaKind = videoURL == nil ? .image : .video
        let fileExtension: String
        if let videoURL {
            fileExtension = videoURL.pathExtension.isEmpty ? "mov" : videoURL.pathExtension
        } else {
            fileExtension = "jpg"
        }
        let mediaFileName = "\(postID).\(fileExtension)"
        let mediaURL = try localMediaURL(for: mediaFileName, createDirectory: true)

        do {
            if let videoURL {
                try FileManager.default.copyItem(at: videoURL, to: mediaURL)
            } else if let image,
                      let imageData = image.jpegData(compressionQuality: 0.86) {
                try imageData.write(to: mediaURL, options: .atomic)
            } else {
                throw WexloContentStoreError.invalidMedia
            }

            let post = WexloLocalPost(
                id: postID,
                authorID: authorID,
                mediaFileName: mediaFileName,
                mediaKind: mediaKind,
                title: title,
                detail: detail,
                category: "Outfit",
                styleTag: styleTag,
                setting: setting,
                layers: layers,
                comments: [],
                likes: "0",
                mediaStorage: .local,
                publishedAt: Date(),
                authorName: authorName,
                authorAvatarAssetName: authorAvatarAssetName
            )

            var storedPosts = publishedPosts
            storedPosts.append(post)
            guard let data = try? JSONEncoder().encode(storedPosts) else {
                throw WexloContentStoreError.storageFailure
            }
            defaults.set(data, forKey: publishedPostsKey)
            publishedPosts = storedPosts
            NotificationCenter.default.post(
                name: .wexloPublishedPostDidChange,
                object: post
            )
            return post
        } catch let error as WexloContentStoreError {
            try? FileManager.default.removeItem(at: mediaURL)
            throw error
        } catch {
            try? FileManager.default.removeItem(at: mediaURL)
            throw WexloContentStoreError.storageFailure
        }
    }

    func mediaURL(for fileName: String) -> URL? {
        try? localMediaURL(for: fileName, createDirectory: false)
    }

    func deletePublishedPosts(for authorID: String) throws {
        let remainingPosts = publishedPosts.filter { $0.authorID != authorID }
        let removedPosts = publishedPosts.filter { $0.authorID == authorID }
        guard let data = try? JSONEncoder().encode(remainingPosts) else {
            throw WexloContentStoreError.storageFailure
        }
        defaults.set(data, forKey: publishedPostsKey)
        publishedPosts = remainingPosts
        for post in removedPosts {
            if let url = mediaURL(for: post.mediaFileName) {
                try? FileManager.default.removeItem(at: url)
            }
        }
        WexloCommentStore.shared.removeComments(forPostIDs: Set(removedPosts.map(\.id)))
        NotificationCenter.default.post(name: .wexloPublishedPostDidChange, object: nil)
    }

    func homeFeedItems(
        for tabIndex: Int,
        excludingAuthorIDs: Set<String> = []
    ) -> [HomeFeedItem] {
        let selectedPosts: [WexloLocalPost]
        switch tabIndex {
        case 1:
            selectedPosts = posts.filter { $0.styleTag == "Gorpcore" || $0.styleTag == "Techwear" }
        case 2:
            selectedPosts = posts.filter { $0.authorID == "henry" || $0.authorID == "clara" || $0.authorID == "mia" }
        default:
            selectedPosts = posts
        }

        return selectedPosts
            .filter { !excludingAuthorIDs.contains($0.authorID) }
            .map(homeFeedItem(for:))
    }

    func searchPosts(
        matching query: String,
        excludingAuthorIDs: Set<String> = []
    ) -> [HomeFeedItem] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedQuery.isEmpty else { return [] }

        return posts
            .filter { !excludingAuthorIDs.contains($0.authorID) }
            .filter { post in
                let authorName = post.authorName ?? user(for: post.authorID)?.name ?? ""
                let searchableText = [
                    post.title,
                    post.detail,
                    post.category,
                    post.styleTag,
                    post.setting,
                    authorName,
                    post.layers.map { "\($0.name) \($0.detail)" }.joined(separator: " ")
                ]
                .joined(separator: " ")
                .lowercased()
                return searchableText.contains(normalizedQuery)
            }
            .map(homeFeedItem(for:))
    }

    private func homeFeedItem(for post: WexloLocalPost) -> HomeFeedItem {
        let author = user(for: post.authorID)
        return HomeFeedItem(
            postID: post.id,
            authorID: post.authorID,
            title: post.title,
            author: post.authorName ?? author?.name ?? "Wexlo member",
            ageAndWeather: "Today · \(post.setting)",
            description: post.detail,
            tags: [post.category, post.styleTag, post.setting],
            likes: post.likes,
            mediaAssetName: post.mediaAssetName,
            mediaFileName: post.mediaFileName,
            mediaKind: post.mediaKind,
            mediaStorage: post.mediaStorage,
            mediaColor: WexloTheme.tabBarSurface,
            mediaSymbol: post.mediaKind == .video ? "play.fill" : nil,
            avatarAssetName: post.authorAvatarAssetName.isEmpty
                ? author?.avatarAssetName
                : post.authorAvatarAssetName,
            mediaContainsTitleOverlay: false
        )
    }

    private func loadPublishedPosts() -> [WexloLocalPost] {
        guard let data = defaults.data(forKey: publishedPostsKey),
              let posts = try? JSONDecoder().decode([WexloLocalPost].self, from: data) else {
            return []
        }
        return posts
    }

    private func localMediaURL(
        for fileName: String,
        createDirectory: Bool
    ) throws -> URL {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent(mediaDirectoryName, isDirectory: true)
        if createDirectory {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        }
        return directory.appendingPathComponent(fileName)
    }
}

extension Notification.Name {
    static let wexloPublishedPostDidChange = Notification.Name("wexlo.publishedPost.didChange")
    static let wexloSavedPostDidChange = Notification.Name("wexlo.savedPost.didChange")
}
