//
//  MoEngagePluginPersonalizeBridge.swift
//  MoEngagePluginPersonalize
//
//  Created by MoEngage on 31/03/26.
//

import Foundation
import MoEngagePersonalization
import MoEngagePluginBase

/// Bridge layer between hybrid SDKs (React Native, Flutter) and the native
/// `MoEngageSDKPersonalize` APIs for experience and offering operations.
///
/// All public methods accept a JSON payload dictionary from the hybrid layer,
/// parse it into native types, and forward to the corresponding native SDK API.
@objc final public class MoEngagePluginPersonalizeBridge: NSObject {
    @objc public static let sharedInstance = MoEngagePluginPersonalizeBridge()

    private override init() {
    }

    // MARK: - Fetch APIs (Completion-based)

    /// Fetches experience campaign metadata filtered by status.
    ///
    /// - Parameters:
    ///   - payload: JSON dictionary containing `accountMeta` and `data.status` (array of status strings).
    ///   - completionHandler: Returns a JSON dictionary with metadata on success or error details on failure.
    @objc public func fetchExperiencesMeta(
        _ payload: [String: Any],
        completionHandler: @escaping (([String: Any]) -> Void)
    ) {
        guard let identifier = MoEngagePluginUtils.fetchIdentifierFromPayload(attribute: payload) else { return }

        let statuses = MoEngagePluginPersonalizeParser.parseStatuses(from: payload)

        MoEngageSDKPersonalize.sharedInstance.fetchExperiencesMeta(
            status: statuses,
            onSuccess: { metadata in
                let response = MoEngagePluginPersonalizeUtils.metadataToJSON(
                    metadata: metadata, identifier: identifier
                )
                completionHandler(response)
            },
            onFailure: { error in
                let response = MoEngagePluginPersonalizeUtils.errorToJSON(
                    error: error, identifier: identifier
                )
                completionHandler(response)
            },
            workspaceId: identifier
        )
    }

    /// Fetches experience campaigns for the given keys and optional attributes.
    ///
    /// - Parameters:
    ///   - payload: JSON dictionary containing `accountMeta`, `data.experienceKeys`, and optional `data.attributes`.
    ///   - completionHandler: Returns a JSON dictionary with experiences/failures on success or error details on failure.
    @objc public func fetchExperiences(
        _ payload: [String: Any],
        completionHandler: @escaping (([String: Any]) -> Void)
    ) {
        guard let identifier = MoEngagePluginUtils.fetchIdentifierFromPayload(attribute: payload),
              let data = payload[MoEngagePluginConstants.General.data] as? [String: Any],
              let keys = data[MoEngagePluginPersonalizeConstants.Personalize.experienceKeys] as? [String]
        else { return }

        let attributes = data[MoEngagePluginPersonalizeConstants.Personalize.attributes] as? [String: String] ?? [:]

        MoEngageSDKPersonalize.sharedInstance.fetchExperiences(
            experienceKeys: Set(keys),
            attributes: attributes,
            onSuccess: { result in
                let response = MoEngagePluginPersonalizeUtils.experienceResultToJSON(
                    result: result, identifier: identifier
                )
                completionHandler(response)
            },
            onFailure: { error in
                let response = MoEngagePluginPersonalizeUtils.errorToJSON(
                    error: error, identifier: identifier
                )
                completionHandler(response)
            },
            workspaceId: identifier
        )
    }

    // MARK: - Experience Tracking

    /// Tracks impression events for one or more experience campaigns.
    ///
    /// - Parameter payload: JSON dictionary containing `accountMeta` and `data.experiences` array.
    @objc public func experiencesShown(_ payload: [String: Any]) {
        guard let identifier = MoEngagePluginUtils.fetchIdentifierFromPayload(attribute: payload),
              let campaigns = MoEngagePluginPersonalizeParser.parseCampaigns(from: payload)
        else { return }

        MoEngageSDKPersonalize.sharedInstance.experiencesShown(
            campaigns: campaigns, workspaceId: identifier
        )
    }

    /// Tracks a click event for a single experience campaign.
    ///
    /// - Parameter payload: JSON dictionary containing `accountMeta` and `data.experience` (single campaign object).
    @objc public func experienceClicked(_ payload: [String: Any]) {
        guard let identifier = MoEngagePluginUtils.fetchIdentifierFromPayload(attribute: payload),
              let data = payload[MoEngagePluginConstants.General.data] as? [String: Any],
              let experienceDict = data[MoEngagePluginPersonalizeConstants.Personalize.experience] as? [String: Any],
              let campaign = MoEngagePluginPersonalizeParser.parseSingleCampaign(from: experienceDict)
        else { return }

        MoEngageSDKPersonalize.sharedInstance.experienceClicked(
            campaign: campaign, workspaceId: identifier
        )
    }

    // MARK: - Offering Tracking

    /// Tracks impression events for one or more offerings.
    ///
    /// - Parameter payload: JSON dictionary containing `accountMeta` and `data.offeringPayloads` (array of full offering dicts).
    @objc public func offeringsShown(_ payload: [String: Any]) {
        guard let identifier = MoEngagePluginUtils.fetchIdentifierFromPayload(attribute: payload),
              let data = payload[MoEngagePluginConstants.General.data] as? [String: Any],
              let offeringPayloads = data[MoEngagePluginPersonalizeConstants.Personalize.offeringPayloads] as? [[String: Any]]
        else { return }

        MoEngageSDKPersonalize.sharedInstance.offeringsShown(
            offeringPayloads: offeringPayloads, workspaceId: identifier
        )
    }

    /// Tracks a click event for a single offering within an experience campaign.
    ///
    /// - Parameter payload: JSON dictionary containing `accountMeta`, `data.experience` (single campaign object),
    ///   and `data.offeringPayload` (full offering dict).
    @objc public func offeringClicked(_ payload: [String: Any]) {
        guard let identifier = MoEngagePluginUtils.fetchIdentifierFromPayload(attribute: payload),
              let data = payload[MoEngagePluginConstants.General.data] as? [String: Any],
              let experienceDict = data[MoEngagePluginPersonalizeConstants.Personalize.experience] as? [String: Any],
              let campaign = MoEngagePluginPersonalizeParser.parseSingleCampaign(from: experienceDict),
              let offeringPayload = data[MoEngagePluginPersonalizeConstants.Personalize.offeringPayload] as? [String: Any]
        else { return }

        MoEngageSDKPersonalize.sharedInstance.offeringClicked(
            campaign: campaign,
            offeringPayload: offeringPayload,
            workspaceId: identifier
        )
    }
}
