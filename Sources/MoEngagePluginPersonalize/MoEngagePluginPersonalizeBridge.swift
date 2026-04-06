//
//  MoEngagePluginPersonalizeBridge.swift
//  MoEngagePluginPersonalize
//
//  Created by MoEngage on 31/03/26.
//

import Foundation
import MoEngagePersonalization
import MoEngagePluginBase

@objc final public class MoEngagePluginPersonalizeBridge: NSObject {
    @objc public static let sharedInstance = MoEngagePluginPersonalizeBridge()

    private override init() {
    }

    // MARK: - Fetch APIs (Completion-based)

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

    @objc public func trackExperienceShown(_ payload: [String: Any]) {
        guard let identifier = MoEngagePluginUtils.fetchIdentifierFromPayload(attribute: payload),
              let campaigns = MoEngagePluginPersonalizeParser.parseCampaigns(from: payload)
        else { return }

        MoEngageSDKPersonalize.sharedInstance.trackExperiencesShown(
            campaigns: campaigns, workspaceId: identifier
        )
    }

    @objc public func trackExperienceClicked(_ payload: [String: Any]) {
        guard let identifier = MoEngagePluginUtils.fetchIdentifierFromPayload(attribute: payload),
              let campaigns = MoEngagePluginPersonalizeParser.parseCampaigns(from: payload)
        else { return }

        for campaign in campaigns {
            MoEngageSDKPersonalize.sharedInstance.trackExperienceClicked(
                campaign: campaign, workspaceId: identifier
            )
        }
    }

    // MARK: - Offering Tracking

    @objc public func trackOfferingShown(_ payload: [String: Any]) {
        guard let identifier = MoEngagePluginUtils.fetchIdentifierFromPayload(attribute: payload),
              let data = payload[MoEngagePluginConstants.General.data] as? [String: Any],
              let offeringAttrs = data[MoEngagePluginPersonalizeConstants.Personalize.offeringAttributes] as? [[String: Any]]
        else { return }

        MoEngageSDKPersonalize.sharedInstance.trackOfferingsShown(
            offeringsAttributes: offeringAttrs, workspaceId: identifier
        )
    }

    @objc public func trackOfferingClicked(_ payload: [String: Any]) {
        guard let identifier = MoEngagePluginUtils.fetchIdentifierFromPayload(attribute: payload),
              let campaigns = MoEngagePluginPersonalizeParser.parseCampaigns(from: payload),
              let data = payload[MoEngagePluginConstants.General.data] as? [String: Any],
              let offeringAttrs = data[MoEngagePluginPersonalizeConstants.Personalize.offeringAttributes] as? [String: Any],
              let campaign = campaigns.first
        else { return }

        MoEngageSDKPersonalize.sharedInstance.trackOfferingClicked(
            campaign: campaign,
            offeringAttributes: offeringAttrs,
            workspaceId: identifier
        )
    }
}
