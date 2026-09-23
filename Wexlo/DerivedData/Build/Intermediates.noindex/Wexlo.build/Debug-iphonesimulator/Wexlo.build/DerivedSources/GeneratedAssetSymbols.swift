import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
extension ColorResource {

}

// MARK: - Image Symbols -

@available(iOS 11.0, macOS 10.7, tvOS 11.0, *)
extension ImageResource {

    /// The "0b3b21ff27f67b9e5821e5ffee7366c5" asset catalog image resource.
    static let _0B3B21Ff27F67B9E5821E5Ffee7366C5 = ImageResource(name: "0b3b21ff27f67b9e5821e5ffee7366c5", bundle: resourceBundle)

    /// The "15d058e5b1d372de38f21d8055f89223" asset catalog image resource.
    static let _15D058E5B1D372De38F21D8055F89223 = ImageResource(name: "15d058e5b1d372de38f21d8055f89223", bundle: resourceBundle)

    /// The "3ecb9ea93cd043fde069c650fc98e9d1" asset catalog image resource.
    static let _3Ecb9Ea93Cd043Fde069C650Fc98E9D1 = ImageResource(name: "3ecb9ea93cd043fde069c650fc98e9d1", bundle: resourceBundle)

    /// The "445ae4344fa0422383d2b1042ce9fbee" asset catalog image resource.
    static let _445Ae4344Fa0422383D2B1042Ce9Fbee = ImageResource(name: "445ae4344fa0422383d2b1042ce9fbee", bundle: resourceBundle)

    /// The "6f8c34cdcbf72a5d34b2e5535223b72b" asset catalog image resource.
    static let _6F8C34Cdcbf72A5D34B2E5535223B72B = ImageResource(name: "6f8c34cdcbf72a5d34b2e5535223b72b", bundle: resourceBundle)

    /// The "a1cef908ea057f0877b33f490f9520aa" asset catalog image resource.
    static let a1Cef908Ea057F0877B33F490F9520Aa = ImageResource(name: "a1cef908ea057f0877b33f490f9520aa", bundle: resourceBundle)

    /// The "a9d6f577358d6cc2328548b9b5dd8f2f" asset catalog image resource.
    static let a9D6F577358D6Cc2328548B9B5Dd8F2F = ImageResource(name: "a9d6f577358d6cc2328548b9b5dd8f2f", bundle: resourceBundle)

    /// The "c6b1bcf0a7de2602d641ffd7ed2f279d" asset catalog image resource.
    static let c6B1Bcf0A7De2602D641Ffd7Ed2F279D = ImageResource(name: "c6b1bcf0a7de2602d641ffd7ed2f279d", bundle: resourceBundle)

    /// The "cs" asset catalog image resource.
    static let cs = ImageResource(name: "cs", bundle: resourceBundle)

    /// The "download (10)" asset catalog image resource.
    static let download10 = ImageResource(name: "download (10)", bundle: resourceBundle)

    /// The "download (11)" asset catalog image resource.
    static let download11 = ImageResource(name: "download (11)", bundle: resourceBundle)

    /// The "download (2)" asset catalog image resource.
    static let download2 = ImageResource(name: "download (2)", bundle: resourceBundle)

    /// The "download (3)" asset catalog image resource.
    static let download3 = ImageResource(name: "download (3)", bundle: resourceBundle)

    /// The "download (5)" asset catalog image resource.
    static let download5 = ImageResource(name: "download (5)", bundle: resourceBundle)

    /// The "download (7)" asset catalog image resource.
    static let download7 = ImageResource(name: "download (7)", bundle: resourceBundle)

    /// The "download (9)" asset catalog image resource.
    static let download9 = ImageResource(name: "download (9)", bundle: resourceBundle)

    /// The "sb" asset catalog image resource.
    static let sb = ImageResource(name: "sb", bundle: resourceBundle)

    /// The "textIcon" asset catalog image resource.
    static let textIcon = ImageResource(name: "textIcon", bundle: resourceBundle)

    /// The "wexlo_ai_stylist_avatar" asset catalog image resource.
    static let wexloAiStylistAvatar = ImageResource(name: "wexlo_ai_stylist_avatar", bundle: resourceBundle)

    /// The "wexlo_auth_logo" asset catalog image resource.
    static let wexloAuthLogo = ImageResource(name: "wexlo_auth_logo", bundle: resourceBundle)

    /// The "wexlo_authorization_consent_selected" asset catalog image resource.
    static let wexloAuthorizationConsentSelected = ImageResource(name: "wexlo_authorization_consent_selected", bundle: resourceBundle)

    /// The "wexlo_authorization_consent_unselected" asset catalog image resource.
    static let wexloAuthorizationConsentUnselected = ImageResource(name: "wexlo_authorization_consent_unselected", bundle: resourceBundle)

    /// The "wexlo_authorization_logo" asset catalog image resource.
    static let wexloAuthorizationLogo = ImageResource(name: "wexlo_authorization_logo", bundle: resourceBundle)

    /// The "wexlo_button_back" asset catalog image resource.
    static let wexloButtonBack = ImageResource(name: "wexlo_button_back", bundle: resourceBundle)

    /// The "wexlo_chat_more" asset catalog image resource.
    static let wexloChatMore = ImageResource(name: "wexlo_chat_more", bundle: resourceBundle)

    /// The "wexlo_chat_send_image" asset catalog image resource.
    static let wexloChatSend = ImageResource(name: "wexlo_chat_send_image", bundle: resourceBundle)

    /// The "wexlo_chat_send_message" asset catalog image resource.
    static let wexloChatSendMessage = ImageResource(name: "wexlo_chat_send_message", bundle: resourceBundle)

    /// The "wexlo_chat_send_voice" asset catalog image resource.
    static let wexloChatSendVoice = ImageResource(name: "wexlo_chat_send_voice", bundle: resourceBundle)

    /// The "wexlo_chat_voice_play" asset catalog image resource.
    static let wexloChatVoicePlay = ImageResource(name: "wexlo_chat_voice_play", bundle: resourceBundle)

    /// The "wexlo_coin" asset catalog image resource.
    static let wexloCoin = ImageResource(name: "wexlo_coin", bundle: resourceBundle)

    /// The "wexlo_explore_accessories" asset catalog image resource.
    static let wexloExploreAccessories = ImageResource(name: "wexlo_explore_accessories", bundle: resourceBundle)

    /// The "wexlo_explore_bags" asset catalog image resource.
    static let wexloExploreBags = ImageResource(name: "wexlo_explore_bags", bundle: resourceBundle)

    /// The "wexlo_explore_fleece" asset catalog image resource.
    static let wexloExploreFleece = ImageResource(name: "wexlo_explore_fleece", bundle: resourceBundle)

    /// The "wexlo_explore_jackets" asset catalog image resource.
    static let wexloExploreJackets = ImageResource(name: "wexlo_explore_jackets", bundle: resourceBundle)

    /// The "wexlo_explore_pants" asset catalog image resource.
    static let wexloExplorePants = ImageResource(name: "wexlo_explore_pants", bundle: resourceBundle)

    /// The "wexlo_explore_rainy_day" asset catalog image resource.
    static let wexloExploreRainyDay = ImageResource(name: "wexlo_explore_rainy_day", bundle: resourceBundle)

    /// The "wexlo_explore_search" asset catalog image resource.
    static let wexloExploreSearch = ImageResource(name: "wexlo_explore_search", bundle: resourceBundle)

    /// The "wexlo_explore_shoes" asset catalog image resource.
    static let wexloExploreShoes = ImageResource(name: "wexlo_explore_shoes", bundle: resourceBundle)

    /// The "wexlo_explore_weekend_camp" asset catalog image resource.
    static let wexloExploreWeekendCamp = ImageResource(name: "wexlo_explore_weekend_camp", bundle: resourceBundle)

    /// The "wexlo_home_ai_stylist" asset catalog image resource.
    static let wexloHomeAiStylist = ImageResource(name: "wexlo_home_ai_stylist", bundle: resourceBundle)

    /// The "wexlo_home_avatar_alex" asset catalog image resource.
    static let wexloHomeAvatarAlex = ImageResource(name: "wexlo_home_avatar_alex", bundle: resourceBundle)

    /// The "wexlo_home_feed_commute" asset catalog image resource.
    static let wexloHomeFeedCommute = ImageResource(name: "wexlo_home_feed_commute", bundle: resourceBundle)

    /// The "wexlo_home_scene_camping" asset catalog image resource.
    static let wexloHomeSceneCamping = ImageResource(name: "wexlo_home_scene_camping", bundle: resourceBundle)

    /// The "wexlo_home_scene_commute" asset catalog image resource.
    static let wexloHomeSceneCommute = ImageResource(name: "wexlo_home_scene_commute", bundle: resourceBundle)

    /// The "wexlo_home_scene_rain" asset catalog image resource.
    static let wexloHomeSceneRain = ImageResource(name: "wexlo_home_scene_rain", bundle: resourceBundle)

    /// The "wexlo_outfit_like_selected" asset catalog image resource.
    static let wexloOutfitLikeSelected = ImageResource(name: "wexlo_outfit_like_selected", bundle: resourceBundle)

    /// The "wexlo_outfit_more" asset catalog image resource.
    static let wexloOutfitMore = ImageResource(name: "wexlo_outfit_more", bundle: resourceBundle)

    /// The "wexlo_profile_avatar" asset catalog image resource.
    static let wexloProfileAvatar = ImageResource(name: "wexlo_profile_avatar", bundle: resourceBundle)

    /// The "wexlo_profile_coins_banner" asset catalog image resource.
    static let wexloProfileCoinsBanner = ImageResource(name: "wexlo_profile_coins_banner", bundle: resourceBundle)

    /// The "wexlo_profile_coins_button" asset catalog image resource.
    static let wexloProfileCoinsButton = ImageResource(name: "wexlo_profile_coins_button", bundle: resourceBundle)

    /// The "wexlo_profile_edit_button" asset catalog image resource.
    static let wexloProfileEditButton = ImageResource(name: "wexlo_profile_edit_button", bundle: resourceBundle)

    /// The "wexlo_recharge_balance_banner" asset catalog image resource.
    static let wexloRechargeBalanceBanner = ImageResource(name: "wexlo_recharge_balance_banner", bundle: resourceBundle)

    /// The "wexlo_recharge_coin" asset catalog image resource.
    static let wexloRechargeCoin = ImageResource(name: "wexlo_recharge_coin", bundle: resourceBundle)

    /// The "wexlo_scene_camping" asset catalog image resource.
    static let wexloSceneCamping = ImageResource(name: "wexlo_scene_camping", bundle: resourceBundle)

    /// The "wexlo_scene_commute" asset catalog image resource.
    static let wexloSceneCommute = ImageResource(name: "wexlo_scene_commute", bundle: resourceBundle)

    /// The "wexlo_scene_rainy_day" asset catalog image resource.
    static let wexloSceneRainyDay = ImageResource(name: "wexlo_scene_rainy_day", bundle: resourceBundle)

    /// The "wexlo_scene_travel" asset catalog image resource.
    static let wexloSceneTravel = ImageResource(name: "wexlo_scene_travel", bundle: resourceBundle)

    /// The "wexlo_settings_block" asset catalog image resource.
    static let wexloSettingsBlock = ImageResource(name: "wexlo_settings_block", bundle: resourceBundle)

    /// The "wexlo_settings_chevron" asset catalog image resource.
    static let wexloSettingsChevron = ImageResource(name: "wexlo_settings_chevron", bundle: resourceBundle)

    /// The "wexlo_settings_delete" asset catalog image resource.
    static let wexloSettingsDelete = ImageResource(name: "wexlo_settings_delete", bundle: resourceBundle)

    /// The "wexlo_settings_logout" asset catalog image resource.
    static let wexloSettingsLogout = ImageResource(name: "wexlo_settings_logout", bundle: resourceBundle)

    /// The "wexlo_settings_privacy" asset catalog image resource.
    static let wexloSettingsPrivacy = ImageResource(name: "wexlo_settings_privacy", bundle: resourceBundle)

    /// The "wexlo_settings_terms" asset catalog image resource.
    static let wexloSettingsTerms = ImageResource(name: "wexlo_settings_terms", bundle: resourceBundle)

    /// The "wexlo_tab_explore" asset catalog image resource.
    static let wexloTabExplore = ImageResource(name: "wexlo_tab_explore", bundle: resourceBundle)

    /// The "wexlo_tab_explore_selected" asset catalog image resource.
    static let wexloTabExploreSelected = ImageResource(name: "wexlo_tab_explore_selected", bundle: resourceBundle)

    /// The "wexlo_tab_home" asset catalog image resource.
    static let wexloTabHome = ImageResource(name: "wexlo_tab_home", bundle: resourceBundle)

    /// The "wexlo_tab_home_selected" asset catalog image resource.
    static let wexloTabHomeSelected = ImageResource(name: "wexlo_tab_home_selected", bundle: resourceBundle)

    /// The "wexlo_tab_messages" asset catalog image resource.
    static let wexloTabMessages = ImageResource(name: "wexlo_tab_messages", bundle: resourceBundle)

    /// The "wexlo_tab_messages_selected" asset catalog image resource.
    static let wexloTabMessagesSelected = ImageResource(name: "wexlo_tab_messages_selected", bundle: resourceBundle)

    /// The "wexlo_tab_post" asset catalog image resource.
    static let wexloTabPost = ImageResource(name: "wexlo_tab_post", bundle: resourceBundle)

    /// The "wexlo_tab_post_selected" asset catalog image resource.
    static let wexloTabPostSelected = ImageResource(name: "wexlo_tab_post_selected", bundle: resourceBundle)

    /// The "wexlo_tab_profile" asset catalog image resource.
    static let wexloTabProfile = ImageResource(name: "wexlo_tab_profile", bundle: resourceBundle)

    /// The "wexlo_tab_profile_selected" asset catalog image resource.
    static let wexloTabProfileSelected = ImageResource(name: "wexlo_tab_profile_selected", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "0b3b21ff27f67b9e5821e5ffee7366c5" asset catalog image.
    static var _0B3B21Ff27F67B9E5821E5Ffee7366C5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: ._0B3B21Ff27F67B9E5821E5Ffee7366C5)
#else
        .init()
#endif
    }

    /// The "15d058e5b1d372de38f21d8055f89223" asset catalog image.
    static var _15D058E5B1D372De38F21D8055F89223: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: ._15D058E5B1D372De38F21D8055F89223)
#else
        .init()
#endif
    }

    /// The "3ecb9ea93cd043fde069c650fc98e9d1" asset catalog image.
    static var _3Ecb9Ea93Cd043Fde069C650Fc98E9D1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: ._3Ecb9Ea93Cd043Fde069C650Fc98E9D1)
#else
        .init()
#endif
    }

    /// The "445ae4344fa0422383d2b1042ce9fbee" asset catalog image.
    static var _445Ae4344Fa0422383D2B1042Ce9Fbee: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: ._445Ae4344Fa0422383D2B1042Ce9Fbee)
#else
        .init()
#endif
    }

    /// The "6f8c34cdcbf72a5d34b2e5535223b72b" asset catalog image.
    static var _6F8C34Cdcbf72A5D34B2E5535223B72B: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: ._6F8C34Cdcbf72A5D34B2E5535223B72B)
#else
        .init()
#endif
    }

    /// The "a1cef908ea057f0877b33f490f9520aa" asset catalog image.
    static var a1Cef908Ea057F0877B33F490F9520Aa: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .a1Cef908Ea057F0877B33F490F9520Aa)
#else
        .init()
#endif
    }

    /// The "a9d6f577358d6cc2328548b9b5dd8f2f" asset catalog image.
    static var a9D6F577358D6Cc2328548B9B5Dd8F2F: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .a9D6F577358D6Cc2328548B9B5Dd8F2F)
#else
        .init()
#endif
    }

    /// The "c6b1bcf0a7de2602d641ffd7ed2f279d" asset catalog image.
    static var c6B1Bcf0A7De2602D641Ffd7Ed2F279D: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .c6B1Bcf0A7De2602D641Ffd7Ed2F279D)
#else
        .init()
#endif
    }

    /// The "cs" asset catalog image.
    static var cs: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cs)
#else
        .init()
#endif
    }

    /// The "download (10)" asset catalog image.
    static var download10: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .download10)
#else
        .init()
#endif
    }

    /// The "download (11)" asset catalog image.
    static var download11: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .download11)
#else
        .init()
#endif
    }

    /// The "download (2)" asset catalog image.
    static var download2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .download2)
#else
        .init()
#endif
    }

    /// The "download (3)" asset catalog image.
    static var download3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .download3)
#else
        .init()
#endif
    }

    /// The "download (5)" asset catalog image.
    static var download5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .download5)
#else
        .init()
#endif
    }

    /// The "download (7)" asset catalog image.
    static var download7: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .download7)
#else
        .init()
#endif
    }

    /// The "download (9)" asset catalog image.
    static var download9: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .download9)
#else
        .init()
#endif
    }

    /// The "sb" asset catalog image.
    static var sb: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .sb)
#else
        .init()
#endif
    }

    /// The "textIcon" asset catalog image.
    static var textIcon: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .textIcon)
#else
        .init()
#endif
    }

    /// The "wexlo_ai_stylist_avatar" asset catalog image.
    static var wexloAiStylistAvatar: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloAiStylistAvatar)
#else
        .init()
#endif
    }

    /// The "wexlo_auth_logo" asset catalog image.
    static var wexloAuthLogo: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloAuthLogo)
#else
        .init()
#endif
    }

    /// The "wexlo_authorization_consent_selected" asset catalog image.
    static var wexloAuthorizationConsentSelected: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloAuthorizationConsentSelected)
#else
        .init()
#endif
    }

    /// The "wexlo_authorization_consent_unselected" asset catalog image.
    static var wexloAuthorizationConsentUnselected: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloAuthorizationConsentUnselected)
#else
        .init()
#endif
    }

    /// The "wexlo_authorization_logo" asset catalog image.
    static var wexloAuthorizationLogo: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloAuthorizationLogo)
#else
        .init()
#endif
    }

    /// The "wexlo_button_back" asset catalog image.
    static var wexloButtonBack: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloButtonBack)
#else
        .init()
#endif
    }

    /// The "wexlo_chat_more" asset catalog image.
    static var wexloChatMore: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloChatMore)
#else
        .init()
#endif
    }

    /// The "wexlo_chat_send_image" asset catalog image.
    static var wexloChatSend: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloChatSend)
#else
        .init()
#endif
    }

    /// The "wexlo_chat_send_message" asset catalog image.
    static var wexloChatSendMessage: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloChatSendMessage)
#else
        .init()
#endif
    }

    /// The "wexlo_chat_send_voice" asset catalog image.
    static var wexloChatSendVoice: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloChatSendVoice)
#else
        .init()
#endif
    }

    /// The "wexlo_chat_voice_play" asset catalog image.
    static var wexloChatVoicePlay: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloChatVoicePlay)
#else
        .init()
#endif
    }

    /// The "wexlo_coin" asset catalog image.
    static var wexloCoin: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloCoin)
#else
        .init()
#endif
    }

    /// The "wexlo_explore_accessories" asset catalog image.
    static var wexloExploreAccessories: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloExploreAccessories)
#else
        .init()
#endif
    }

    /// The "wexlo_explore_bags" asset catalog image.
    static var wexloExploreBags: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloExploreBags)
#else
        .init()
#endif
    }

    /// The "wexlo_explore_fleece" asset catalog image.
    static var wexloExploreFleece: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloExploreFleece)
#else
        .init()
#endif
    }

    /// The "wexlo_explore_jackets" asset catalog image.
    static var wexloExploreJackets: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloExploreJackets)
#else
        .init()
#endif
    }

    /// The "wexlo_explore_pants" asset catalog image.
    static var wexloExplorePants: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloExplorePants)
#else
        .init()
#endif
    }

    /// The "wexlo_explore_rainy_day" asset catalog image.
    static var wexloExploreRainyDay: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloExploreRainyDay)
#else
        .init()
#endif
    }

    /// The "wexlo_explore_search" asset catalog image.
    static var wexloExploreSearch: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloExploreSearch)
#else
        .init()
#endif
    }

    /// The "wexlo_explore_shoes" asset catalog image.
    static var wexloExploreShoes: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloExploreShoes)
#else
        .init()
#endif
    }

    /// The "wexlo_explore_weekend_camp" asset catalog image.
    static var wexloExploreWeekendCamp: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloExploreWeekendCamp)
#else
        .init()
#endif
    }

    /// The "wexlo_home_ai_stylist" asset catalog image.
    static var wexloHomeAiStylist: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloHomeAiStylist)
#else
        .init()
#endif
    }

    /// The "wexlo_home_avatar_alex" asset catalog image.
    static var wexloHomeAvatarAlex: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloHomeAvatarAlex)
#else
        .init()
#endif
    }

    /// The "wexlo_home_feed_commute" asset catalog image.
    static var wexloHomeFeedCommute: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloHomeFeedCommute)
#else
        .init()
#endif
    }

    /// The "wexlo_home_scene_camping" asset catalog image.
    static var wexloHomeSceneCamping: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloHomeSceneCamping)
#else
        .init()
#endif
    }

    /// The "wexlo_home_scene_commute" asset catalog image.
    static var wexloHomeSceneCommute: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloHomeSceneCommute)
#else
        .init()
#endif
    }

    /// The "wexlo_home_scene_rain" asset catalog image.
    static var wexloHomeSceneRain: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloHomeSceneRain)
#else
        .init()
#endif
    }

    /// The "wexlo_outfit_like_selected" asset catalog image.
    static var wexloOutfitLikeSelected: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloOutfitLikeSelected)
#else
        .init()
#endif
    }

    /// The "wexlo_outfit_more" asset catalog image.
    static var wexloOutfitMore: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloOutfitMore)
#else
        .init()
#endif
    }

    /// The "wexlo_profile_avatar" asset catalog image.
    static var wexloProfileAvatar: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloProfileAvatar)
#else
        .init()
#endif
    }

    /// The "wexlo_profile_coins_banner" asset catalog image.
    static var wexloProfileCoinsBanner: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloProfileCoinsBanner)
#else
        .init()
#endif
    }

    /// The "wexlo_profile_coins_button" asset catalog image.
    static var wexloProfileCoinsButton: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloProfileCoinsButton)
#else
        .init()
#endif
    }

    /// The "wexlo_profile_edit_button" asset catalog image.
    static var wexloProfileEditButton: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloProfileEditButton)
#else
        .init()
#endif
    }

    /// The "wexlo_recharge_balance_banner" asset catalog image.
    static var wexloRechargeBalanceBanner: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloRechargeBalanceBanner)
#else
        .init()
#endif
    }

    /// The "wexlo_recharge_coin" asset catalog image.
    static var wexloRechargeCoin: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloRechargeCoin)
#else
        .init()
#endif
    }

    /// The "wexlo_scene_camping" asset catalog image.
    static var wexloSceneCamping: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloSceneCamping)
#else
        .init()
#endif
    }

    /// The "wexlo_scene_commute" asset catalog image.
    static var wexloSceneCommute: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloSceneCommute)
#else
        .init()
#endif
    }

    /// The "wexlo_scene_rainy_day" asset catalog image.
    static var wexloSceneRainyDay: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloSceneRainyDay)
#else
        .init()
#endif
    }

    /// The "wexlo_scene_travel" asset catalog image.
    static var wexloSceneTravel: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloSceneTravel)
#else
        .init()
#endif
    }

    /// The "wexlo_settings_block" asset catalog image.
    static var wexloSettingsBlock: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloSettingsBlock)
#else
        .init()
#endif
    }

    /// The "wexlo_settings_chevron" asset catalog image.
    static var wexloSettingsChevron: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloSettingsChevron)
#else
        .init()
#endif
    }

    /// The "wexlo_settings_delete" asset catalog image.
    static var wexloSettingsDelete: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloSettingsDelete)
#else
        .init()
#endif
    }

    /// The "wexlo_settings_logout" asset catalog image.
    static var wexloSettingsLogout: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloSettingsLogout)
#else
        .init()
#endif
    }

    /// The "wexlo_settings_privacy" asset catalog image.
    static var wexloSettingsPrivacy: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloSettingsPrivacy)
#else
        .init()
#endif
    }

    /// The "wexlo_settings_terms" asset catalog image.
    static var wexloSettingsTerms: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloSettingsTerms)
#else
        .init()
#endif
    }

    /// The "wexlo_tab_explore" asset catalog image.
    static var wexloTabExplore: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloTabExplore)
#else
        .init()
#endif
    }

    /// The "wexlo_tab_explore_selected" asset catalog image.
    static var wexloTabExploreSelected: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloTabExploreSelected)
#else
        .init()
#endif
    }

    /// The "wexlo_tab_home" asset catalog image.
    static var wexloTabHome: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloTabHome)
#else
        .init()
#endif
    }

    /// The "wexlo_tab_home_selected" asset catalog image.
    static var wexloTabHomeSelected: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloTabHomeSelected)
#else
        .init()
#endif
    }

    /// The "wexlo_tab_messages" asset catalog image.
    static var wexloTabMessages: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloTabMessages)
#else
        .init()
#endif
    }

    /// The "wexlo_tab_messages_selected" asset catalog image.
    static var wexloTabMessagesSelected: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloTabMessagesSelected)
#else
        .init()
#endif
    }

    /// The "wexlo_tab_post" asset catalog image.
    static var wexloTabPost: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloTabPost)
#else
        .init()
#endif
    }

    /// The "wexlo_tab_post_selected" asset catalog image.
    static var wexloTabPostSelected: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloTabPostSelected)
#else
        .init()
#endif
    }

    /// The "wexlo_tab_profile" asset catalog image.
    static var wexloTabProfile: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloTabProfile)
#else
        .init()
#endif
    }

    /// The "wexlo_tab_profile_selected" asset catalog image.
    static var wexloTabProfileSelected: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wexloTabProfileSelected)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "0b3b21ff27f67b9e5821e5ffee7366c5" asset catalog image.
    static var _0B3B21Ff27F67B9E5821E5Ffee7366C5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: ._0B3B21Ff27F67B9E5821E5Ffee7366C5)
#else
        .init()
#endif
    }

    /// The "15d058e5b1d372de38f21d8055f89223" asset catalog image.
    static var _15D058E5B1D372De38F21D8055F89223: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: ._15D058E5B1D372De38F21D8055F89223)
#else
        .init()
#endif
    }

    /// The "3ecb9ea93cd043fde069c650fc98e9d1" asset catalog image.
    static var _3Ecb9Ea93Cd043Fde069C650Fc98E9D1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: ._3Ecb9Ea93Cd043Fde069C650Fc98E9D1)
#else
        .init()
#endif
    }

    /// The "445ae4344fa0422383d2b1042ce9fbee" asset catalog image.
    static var _445Ae4344Fa0422383D2B1042Ce9Fbee: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: ._445Ae4344Fa0422383D2B1042Ce9Fbee)
#else
        .init()
#endif
    }

    /// The "6f8c34cdcbf72a5d34b2e5535223b72b" asset catalog image.
    static var _6F8C34Cdcbf72A5D34B2E5535223B72B: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: ._6F8C34Cdcbf72A5D34B2E5535223B72B)
#else
        .init()
#endif
    }

    /// The "a1cef908ea057f0877b33f490f9520aa" asset catalog image.
    static var a1Cef908Ea057F0877B33F490F9520Aa: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .a1Cef908Ea057F0877B33F490F9520Aa)
#else
        .init()
#endif
    }

    /// The "a9d6f577358d6cc2328548b9b5dd8f2f" asset catalog image.
    static var a9D6F577358D6Cc2328548B9B5Dd8F2F: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .a9D6F577358D6Cc2328548B9B5Dd8F2F)
#else
        .init()
#endif
    }

    /// The "c6b1bcf0a7de2602d641ffd7ed2f279d" asset catalog image.
    static var c6B1Bcf0A7De2602D641Ffd7Ed2F279D: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .c6B1Bcf0A7De2602D641Ffd7Ed2F279D)
#else
        .init()
#endif
    }

    /// The "cs" asset catalog image.
    static var cs: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cs)
#else
        .init()
#endif
    }

    /// The "download (10)" asset catalog image.
    static var download10: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .download10)
#else
        .init()
#endif
    }

    /// The "download (11)" asset catalog image.
    static var download11: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .download11)
#else
        .init()
#endif
    }

    /// The "download (2)" asset catalog image.
    static var download2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .download2)
#else
        .init()
#endif
    }

    /// The "download (3)" asset catalog image.
    static var download3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .download3)
#else
        .init()
#endif
    }

    /// The "download (5)" asset catalog image.
    static var download5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .download5)
#else
        .init()
#endif
    }

    /// The "download (7)" asset catalog image.
    static var download7: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .download7)
#else
        .init()
#endif
    }

    /// The "download (9)" asset catalog image.
    static var download9: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .download9)
#else
        .init()
#endif
    }

    /// The "sb" asset catalog image.
    static var sb: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .sb)
#else
        .init()
#endif
    }

    /// The "textIcon" asset catalog image.
    static var textIcon: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .textIcon)
#else
        .init()
#endif
    }

    /// The "wexlo_ai_stylist_avatar" asset catalog image.
    static var wexloAiStylistAvatar: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloAiStylistAvatar)
#else
        .init()
#endif
    }

    /// The "wexlo_auth_logo" asset catalog image.
    static var wexloAuthLogo: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloAuthLogo)
#else
        .init()
#endif
    }

    /// The "wexlo_authorization_consent_selected" asset catalog image.
    static var wexloAuthorizationConsentSelected: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloAuthorizationConsentSelected)
#else
        .init()
#endif
    }

    /// The "wexlo_authorization_consent_unselected" asset catalog image.
    static var wexloAuthorizationConsentUnselected: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloAuthorizationConsentUnselected)
#else
        .init()
#endif
    }

    /// The "wexlo_authorization_logo" asset catalog image.
    static var wexloAuthorizationLogo: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloAuthorizationLogo)
#else
        .init()
#endif
    }

    /// The "wexlo_button_back" asset catalog image.
    static var wexloButtonBack: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloButtonBack)
#else
        .init()
#endif
    }

    /// The "wexlo_chat_more" asset catalog image.
    static var wexloChatMore: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloChatMore)
#else
        .init()
#endif
    }

    /// The "wexlo_chat_send_image" asset catalog image.
    static var wexloChatSend: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloChatSend)
#else
        .init()
#endif
    }

    /// The "wexlo_chat_send_message" asset catalog image.
    static var wexloChatSendMessage: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloChatSendMessage)
#else
        .init()
#endif
    }

    /// The "wexlo_chat_send_voice" asset catalog image.
    static var wexloChatSendVoice: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloChatSendVoice)
#else
        .init()
#endif
    }

    /// The "wexlo_chat_voice_play" asset catalog image.
    static var wexloChatVoicePlay: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloChatVoicePlay)
#else
        .init()
#endif
    }

    /// The "wexlo_coin" asset catalog image.
    static var wexloCoin: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloCoin)
#else
        .init()
#endif
    }

    /// The "wexlo_explore_accessories" asset catalog image.
    static var wexloExploreAccessories: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloExploreAccessories)
#else
        .init()
#endif
    }

    /// The "wexlo_explore_bags" asset catalog image.
    static var wexloExploreBags: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloExploreBags)
#else
        .init()
#endif
    }

    /// The "wexlo_explore_fleece" asset catalog image.
    static var wexloExploreFleece: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloExploreFleece)
#else
        .init()
#endif
    }

    /// The "wexlo_explore_jackets" asset catalog image.
    static var wexloExploreJackets: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloExploreJackets)
#else
        .init()
#endif
    }

    /// The "wexlo_explore_pants" asset catalog image.
    static var wexloExplorePants: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloExplorePants)
#else
        .init()
#endif
    }

    /// The "wexlo_explore_rainy_day" asset catalog image.
    static var wexloExploreRainyDay: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloExploreRainyDay)
#else
        .init()
#endif
    }

    /// The "wexlo_explore_search" asset catalog image.
    static var wexloExploreSearch: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloExploreSearch)
#else
        .init()
#endif
    }

    /// The "wexlo_explore_shoes" asset catalog image.
    static var wexloExploreShoes: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloExploreShoes)
#else
        .init()
#endif
    }

    /// The "wexlo_explore_weekend_camp" asset catalog image.
    static var wexloExploreWeekendCamp: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloExploreWeekendCamp)
#else
        .init()
#endif
    }

    /// The "wexlo_home_ai_stylist" asset catalog image.
    static var wexloHomeAiStylist: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloHomeAiStylist)
#else
        .init()
#endif
    }

    /// The "wexlo_home_avatar_alex" asset catalog image.
    static var wexloHomeAvatarAlex: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloHomeAvatarAlex)
#else
        .init()
#endif
    }

    /// The "wexlo_home_feed_commute" asset catalog image.
    static var wexloHomeFeedCommute: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloHomeFeedCommute)
#else
        .init()
#endif
    }

    /// The "wexlo_home_scene_camping" asset catalog image.
    static var wexloHomeSceneCamping: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloHomeSceneCamping)
#else
        .init()
#endif
    }

    /// The "wexlo_home_scene_commute" asset catalog image.
    static var wexloHomeSceneCommute: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloHomeSceneCommute)
#else
        .init()
#endif
    }

    /// The "wexlo_home_scene_rain" asset catalog image.
    static var wexloHomeSceneRain: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloHomeSceneRain)
#else
        .init()
#endif
    }

    /// The "wexlo_outfit_like_selected" asset catalog image.
    static var wexloOutfitLikeSelected: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloOutfitLikeSelected)
#else
        .init()
#endif
    }

    /// The "wexlo_outfit_more" asset catalog image.
    static var wexloOutfitMore: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloOutfitMore)
#else
        .init()
#endif
    }

    /// The "wexlo_profile_avatar" asset catalog image.
    static var wexloProfileAvatar: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloProfileAvatar)
#else
        .init()
#endif
    }

    /// The "wexlo_profile_coins_banner" asset catalog image.
    static var wexloProfileCoinsBanner: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloProfileCoinsBanner)
#else
        .init()
#endif
    }

    /// The "wexlo_profile_coins_button" asset catalog image.
    static var wexloProfileCoinsButton: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloProfileCoinsButton)
#else
        .init()
#endif
    }

    /// The "wexlo_profile_edit_button" asset catalog image.
    static var wexloProfileEditButton: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloProfileEditButton)
#else
        .init()
#endif
    }

    /// The "wexlo_recharge_balance_banner" asset catalog image.
    static var wexloRechargeBalanceBanner: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloRechargeBalanceBanner)
#else
        .init()
#endif
    }

    /// The "wexlo_recharge_coin" asset catalog image.
    static var wexloRechargeCoin: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloRechargeCoin)
#else
        .init()
#endif
    }

    /// The "wexlo_scene_camping" asset catalog image.
    static var wexloSceneCamping: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloSceneCamping)
#else
        .init()
#endif
    }

    /// The "wexlo_scene_commute" asset catalog image.
    static var wexloSceneCommute: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloSceneCommute)
#else
        .init()
#endif
    }

    /// The "wexlo_scene_rainy_day" asset catalog image.
    static var wexloSceneRainyDay: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloSceneRainyDay)
#else
        .init()
#endif
    }

    /// The "wexlo_scene_travel" asset catalog image.
    static var wexloSceneTravel: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloSceneTravel)
#else
        .init()
#endif
    }

    /// The "wexlo_settings_block" asset catalog image.
    static var wexloSettingsBlock: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloSettingsBlock)
#else
        .init()
#endif
    }

    /// The "wexlo_settings_chevron" asset catalog image.
    static var wexloSettingsChevron: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloSettingsChevron)
#else
        .init()
#endif
    }

    /// The "wexlo_settings_delete" asset catalog image.
    static var wexloSettingsDelete: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloSettingsDelete)
#else
        .init()
#endif
    }

    /// The "wexlo_settings_logout" asset catalog image.
    static var wexloSettingsLogout: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloSettingsLogout)
#else
        .init()
#endif
    }

    /// The "wexlo_settings_privacy" asset catalog image.
    static var wexloSettingsPrivacy: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloSettingsPrivacy)
#else
        .init()
#endif
    }

    /// The "wexlo_settings_terms" asset catalog image.
    static var wexloSettingsTerms: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloSettingsTerms)
#else
        .init()
#endif
    }

    /// The "wexlo_tab_explore" asset catalog image.
    static var wexloTabExplore: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloTabExplore)
#else
        .init()
#endif
    }

    /// The "wexlo_tab_explore_selected" asset catalog image.
    static var wexloTabExploreSelected: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloTabExploreSelected)
#else
        .init()
#endif
    }

    /// The "wexlo_tab_home" asset catalog image.
    static var wexloTabHome: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloTabHome)
#else
        .init()
#endif
    }

    /// The "wexlo_tab_home_selected" asset catalog image.
    static var wexloTabHomeSelected: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloTabHomeSelected)
#else
        .init()
#endif
    }

    /// The "wexlo_tab_messages" asset catalog image.
    static var wexloTabMessages: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloTabMessages)
#else
        .init()
#endif
    }

    /// The "wexlo_tab_messages_selected" asset catalog image.
    static var wexloTabMessagesSelected: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloTabMessagesSelected)
#else
        .init()
#endif
    }

    /// The "wexlo_tab_post" asset catalog image.
    static var wexloTabPost: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloTabPost)
#else
        .init()
#endif
    }

    /// The "wexlo_tab_post_selected" asset catalog image.
    static var wexloTabPostSelected: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloTabPostSelected)
#else
        .init()
#endif
    }

    /// The "wexlo_tab_profile" asset catalog image.
    static var wexloTabProfile: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloTabProfile)
#else
        .init()
#endif
    }

    /// The "wexlo_tab_profile_selected" asset catalog image.
    static var wexloTabProfileSelected: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wexloTabProfileSelected)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
@available(watchOS, unavailable)
extension ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 11.0, macOS 10.7, tvOS 11.0, *)
@available(watchOS, unavailable)
extension ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

// MARK: - Backwards Deployment Support -

/// A color resource.
struct ColorResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog color resource name.
    fileprivate let name: Swift.String

    /// An asset catalog color resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize a `ColorResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

/// An image resource.
struct ImageResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog image resource name.
    fileprivate let name: Swift.String

    /// An asset catalog image resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize an `ImageResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// Initialize a `NSColor` with a color resource.
    convenience init(resource: ColorResource) {
        self.init(named: NSColor.Name(resource.name), bundle: resource.bundle)!
    }

}

protocol _ACResourceInitProtocol {}
extension AppKit.NSImage: _ACResourceInitProtocol {}

@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension _ACResourceInitProtocol {

    /// Initialize a `NSImage` with an image resource.
    init(resource: ImageResource) {
        self = resource.bundle.image(forResource: NSImage.Name(resource.name))! as! Self
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// Initialize a `UIColor` with a color resource.
    convenience init(resource: ColorResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}

@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// Initialize a `UIImage` with an image resource.
    convenience init(resource: ImageResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    /// Initialize a `Color` with a color resource.
    init(_ resource: ColorResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Image {

    /// Initialize an `Image` with an image resource.
    init(_ resource: ImageResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}
#endif