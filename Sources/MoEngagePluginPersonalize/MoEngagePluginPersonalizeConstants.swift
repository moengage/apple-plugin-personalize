//
//  MoEngagePluginPersonalizeConstants.swift
//  MoEngagePluginPersonalize
//
//  Created by MoEngage on 31/03/26.
//

import Foundation

struct MoEngagePluginPersonalizeConstants {

    struct Personalize {
        // Request keys
        static let status = "status"
        static let experienceKeys = "experienceKeys"
        static let attributes = "attributes"
        static let experiences = "experiences"
        static let experienceKey = "experienceKey"
        static let experienceContext = "experienceContext"
        static let offeringAttributes = "offeringAttributes"

        // Response keys
        static let experienceName = "experienceName"
        static let source = "source"
        static let failures = "failures"
        static let reason = "reason"
        static let message = "message"
        static let code = "code"
        static let error = "error"
    }

    struct ExperienceStatusValues {
        static let active = "active"
        static let paused = "paused"
        static let scheduled = "scheduled"
    }

    struct DataSourceValues {
        static let cache = "CACHE"
        static let network = "NETWORK"
    }

    struct FailureReasons {
        static let userInCampaignControlGroup = "USER_IN_CAMPAIGN_CONTROL_GROUP"
        static let userInGlobalControlGroup = "USER_IN_GLOBAL_CONTROL_GROUP"
        static let userNotInSegment = "USER_NOT_IN_SEGMENT"
        static let invalidExperienceKey = "IN_VALID_EXPERIENCE_KEY"
        static let maxLimitBreached = "MAX_LIMIT_BREACHED"
        static let experienceNotActive = "EXPERIENCE_NOT_ACTIVE"
        static let experienceExpired = "EXPERIENCE_EXPIRED"
        static let personalizationFailed = "PERSONALIZATION_FAILED"
        static let sdkNotInitialized = "SDK_NOT_INITIALIZED"
        static let sdkDisabled = "SDK_DISABLED"
        static let featureDisabled = "FEATURE_DISABLED"
        static let networkError = "NETWORK_ERROR"
        static let httpError = "HTTP_ERROR"
        static let parseError = "PARSE_ERROR"
        static let unknownServerError = "UNKNOWN_SERVER_ERROR"
        static let unknown = "UNKNOWN"
    }
}
