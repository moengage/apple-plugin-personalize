//
//  MoEngagePluginPersonalizeUtils.swift
//  MoEngagePluginPersonalize
//
//  Created by MoEngage on 31/03/26.
//

import Foundation
import MoEngagePersonalization
import MoEngagePluginBase

enum MoEngagePluginPersonalizeUtils {

    // MARK: - Native to Hybrid Serialization

    static func metadataToJSON(metadata: MoEngageExperienceCampaignMetaData, identifier: String) -> [String: Any] {
        let accountMeta = MoEngagePluginUtils.createAccountPayload(identifier: identifier)

        let experiences = metadata.experienceCampaignMeta.map { meta -> [String: Any] in
            return [
                MoEngagePluginPersonalizeConstants.Personalize.experienceKey: meta.experienceKey,
                MoEngagePluginPersonalizeConstants.Personalize.experienceName: meta.experienceName,
                MoEngagePluginPersonalizeConstants.Personalize.status: experienceStatusString(meta.status)
            ]
        }

        let data: [String: Any] = [
            MoEngagePluginPersonalizeConstants.Personalize.source: dataSourceString(metadata.source),
            MoEngagePluginPersonalizeConstants.Personalize.experiences: experiences
        ]

        return [
            MoEngagePluginConstants.General.accountMeta: accountMeta,
            MoEngagePluginConstants.General.data: data
        ]
    }

    static func experienceResultToJSON(result: MoEngageExperienceCampaignsResult, identifier: String) -> [String: Any] {
        let accountMeta = MoEngagePluginUtils.createAccountPayload(identifier: identifier)

        let experiences = result.experiences.map { campaign -> [String: Any] in
            return [
                MoEngagePluginPersonalizeConstants.Personalize.experienceKey: campaign.experienceKey,
                MoEngagePluginConstants.General.payload: unwrapPayload(campaign.payload),
                MoEngagePluginPersonalizeConstants.Personalize.experienceContext: campaign.experienceContext,
                MoEngagePluginPersonalizeConstants.Personalize.source: dataSourceString(campaign.source)
            ]
        }

        let failures = result.failures.map { failure -> [String: Any] in
            return [
                MoEngagePluginPersonalizeConstants.Personalize.reason: mapFailureReason(failure.code),
                MoEngagePluginPersonalizeConstants.Personalize.experienceKeys: failure.experienceKeys ?? []
            ]
        }

        let data: [String: Any] = [
            MoEngagePluginPersonalizeConstants.Personalize.experiences: experiences,
            MoEngagePluginPersonalizeConstants.Personalize.failures: failures
        ]

        return [
            MoEngagePluginConstants.General.accountMeta: accountMeta,
            MoEngagePluginConstants.General.data: data
        ]
    }

    static func errorToJSON(error: MoEngageExperienceFailureReason, identifier: String) -> [String: Any] {
        let accountMeta = MoEngagePluginUtils.createAccountPayload(identifier: identifier)

        let errorData: [String: Any] = [
            MoEngagePluginPersonalizeConstants.Personalize.code: mapFailureReason(error.code),
            MoEngagePluginPersonalizeConstants.Personalize.message: error.message
        ]

        return [
            MoEngagePluginConstants.General.accountMeta: accountMeta,
            MoEngagePluginPersonalizeConstants.Personalize.error: errorData
        ]
    }

    // MARK: - Private Helpers

    private static func experienceStatusString(_ status: MoEngageExperienceStatus) -> String {
        switch status {
        case .active:
            return MoEngagePluginPersonalizeConstants.ExperienceStatusValues.active
        case .paused:
            return MoEngagePluginPersonalizeConstants.ExperienceStatusValues.paused
        case .scheduled:
            return MoEngagePluginPersonalizeConstants.ExperienceStatusValues.scheduled
        @unknown default:
            return MoEngagePluginPersonalizeConstants.ExperienceStatusValues.active
        }
    }

    private static func dataSourceString(_ source: MoEngagePersonalizeDataSource) -> String {
        switch source {
        case .cache:
            return MoEngagePluginPersonalizeConstants.DataSourceValues.cache
        case .network:
            return MoEngagePluginPersonalizeConstants.DataSourceValues.network
        @unknown default:
            return MoEngagePluginPersonalizeConstants.DataSourceValues.network
        }
    }

    private static func mapFailureReason(_ code: MoEngageExperienceFailureReasonCode) -> String {
        switch code {
        case .userInCampaignControlGroup:
            return MoEngagePluginPersonalizeConstants.FailureReasons.userInCampaignControlGroup
        case .userInGlobalControlGroup:
            return MoEngagePluginPersonalizeConstants.FailureReasons.userInGlobalControlGroup
        case .userNotInSegment:
            return MoEngagePluginPersonalizeConstants.FailureReasons.userNotInSegment
        case .invalidExperienceKey:
            return MoEngagePluginPersonalizeConstants.FailureReasons.invalidExperienceKey
        case .maxLimitBreached:
            return MoEngagePluginPersonalizeConstants.FailureReasons.maxLimitBreached
        case .campaignNotActive:
            return MoEngagePluginPersonalizeConstants.FailureReasons.experienceNotActive
        case .campaignExpired:
            return MoEngagePluginPersonalizeConstants.FailureReasons.experienceExpired
        case .personalizationFailed:
            return MoEngagePluginPersonalizeConstants.FailureReasons.personalizationFailed
        case .sdkNotInitialized:
            return MoEngagePluginPersonalizeConstants.FailureReasons.sdkNotInitialized
        case .sdkDisabled:
            return MoEngagePluginPersonalizeConstants.FailureReasons.sdkDisabled
        case .featureDisabled:
            return MoEngagePluginPersonalizeConstants.FailureReasons.featureDisabled
        case .networkError:
            return MoEngagePluginPersonalizeConstants.FailureReasons.networkError
        case .httpError:
            return MoEngagePluginPersonalizeConstants.FailureReasons.httpError
        case .parseError:
            return MoEngagePluginPersonalizeConstants.FailureReasons.parseError
        case .unknownServerError:
            return MoEngagePluginPersonalizeConstants.FailureReasons.unknownServerError
        case .unknownError:
            return MoEngagePluginPersonalizeConstants.FailureReasons.unknown
        @unknown default:
            return MoEngagePluginPersonalizeConstants.FailureReasons.unknown
        }
    }

    /// Lifts the inner `value` out of each `{ "value": X, "data_type": "..." }` envelope on
    /// the top-level `payload` map. Trusts JSONSerialization to have already typed each
    /// primitive natively, so no per-data_type coercion is needed.
    ///
    /// Pass-through for entries that aren't envelope-shaped — keeps the helper forward-
    /// compatible if the backend ever sends payload entries without the wrapper.
    ///
    /// Lives at the plugin layer (instead of the iOS native SDK) so `MoEngagePersonalization`
    /// stays free of `data_type` parsing. After this, hybrid (RN/Flutter) consumers see the
    /// same plain-value shape Android already exposes via `ExperiencePayloadKeyValue.mapToAny()`.
    static func unwrapPayload(_ raw: [String: Any]) -> [String: Any] {
        var out: [String: Any] = [:]
        out.reserveCapacity(raw.count)
        for (key, rawValue) in raw {
            if let envelope = rawValue as? [String: Any],
               let value = envelope["value"] {
                out[key] = value
            } else {
                out[key] = rawValue
            }
        }
        return out
    }
}
