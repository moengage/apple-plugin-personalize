//
//  MoEngagePluginPersonalizeParser.swift
//  MoEngagePluginPersonalize
//
//  Created by MoEngage on 31/03/26.
//

import Foundation
import MoEngagePersonalize
import MoEngagePluginBase

class MoEngagePluginPersonalizeParser {

    static func parseStatuses(from payload: [String: Any]) -> [MoEngageExperienceStatus] {
        guard let data = payload[MoEngagePluginConstants.General.data] as? [String: Any],
              let statusStrings = data[MoEngagePluginPersonalizeConstants.Personalize.status] as? [String]
        else {
            return []
        }
        return MoEngageExperienceStatusUtils.getStatus(from: statusStrings)
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

            return MoEngageExperienceCampaign(
                experienceKey: key,
                payload: payload,
                experienceContext: context,
                source: .network
            )
        }
    }
}
