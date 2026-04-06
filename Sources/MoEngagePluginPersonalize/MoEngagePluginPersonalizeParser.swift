//
//  MoEngagePluginPersonalizeParser.swift
//  MoEngagePluginPersonalize
//
//  Created by MoEngage on 31/03/26.
//

import Foundation
import MoEngagePersonalization
import MoEngagePluginBase

class MoEngagePluginPersonalizeParser {

    static func parseStatuses(from payload: [String: Any]) -> [MoEngageExperienceStatus] {
        guard let data = payload[MoEngagePluginConstants.General.data] as? [String: Any],
              let statusStrings = data[MoEngagePluginPersonalizeConstants.Personalize.status] as? [String]
        else {
            return []
        }
        return statusStrings.compactMap { experienceStatusFromString($0) }
    }

    private static func experienceStatusFromString(_ value: String) -> MoEngageExperienceStatus? {
        switch value.lowercased() {
        case MoEngagePluginPersonalizeConstants.ExperienceStatusValues.active:
            return .active
        case MoEngagePluginPersonalizeConstants.ExperienceStatusValues.paused:
            return .paused
        case MoEngagePluginPersonalizeConstants.ExperienceStatusValues.scheduled:
            return .scheduled
        default:
            return nil
        }
    }

    private static func parseDataSource(from dict: [String: Any]) -> MoEngagePersonalizeDataSource {
        guard let sourceString = dict[MoEngagePluginPersonalizeConstants.Personalize.source] as? String else {
            return .network
        }
        return sourceString == MoEngagePluginPersonalizeConstants.DataSourceValues.cache ? .cache : .network
    }

    static func parseCampaigns(from payload: [String: Any]) -> [MoEngageExperienceCampaign]? {
        guard let data = payload[MoEngagePluginConstants.General.data] as? [String: Any],
              let experiences = data[MoEngagePluginPersonalizeConstants.Personalize.experiences] as? [[String: Any]]
        else {
            return nil
        }

        return experiences.compactMap { exp in
            guard let key = exp[MoEngagePluginPersonalizeConstants.Personalize.experienceKey] as? String,
                  let payload = exp[MoEngagePluginConstants.General.payload] as? [String: Any],
                  let context = exp[MoEngagePluginPersonalizeConstants.Personalize.experienceContext] as? [String: Any]
            else { return nil }

            let source = parseDataSource(from: exp)

            return MoEngageExperienceCampaign(
                experienceKey: key,
                payload: payload,
                experienceContext: context,
                source: source
            )
        }
    }
}
